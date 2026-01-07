/**
 * ═══════════════════════════════════════════════════════════════
 * CHAT ORCHESTRATOR - FIXED + STABLE VERSION (FINAL)
 * ═══════════════════════════════════════════════════════════════
 * Handles all chat logic, trait extraction, persona building,
 * OpenAI calls and Firestore-safe conversation history saving.
 */

import { openai } from "../config/openaiClient.js";
import { detectIntentType, getChatConfig } from "../domain/intentEngine.js";
import { buildUltimatePersona, normalizeTone, isRelationshipQuery } from "../domain/personaEngine.js";
import { extractDeepTraits } from "../domain/traitEngine.js";
import { predictOutcome } from "../domain/outcomePredictionEngine.js";
import { detectUserPatterns } from "../domain/patternEngine.js";
import { detectGenderSmart } from "../domain/genderEngine.js";
import { MODEL_FALLBACK } from "../utils/constants.js";

import {
  getUserProfile,
  updateUserProfile,
  incrementGenderAttempts,
  updateUserGender,
} from "../firestore/userProfileRepository.js";

import {
  getConversationHistory,
  saveConversationHistory,
  getSessionState,
  setSessionState,
} from "../firestore/conversationRepository.js";

import { db as firestore } from "../config/firebaseAdmin.js";
import { getRelationshipContext } from "./relationshipRetrieval.js";

/**
 * MAIN CHAT PROCESSOR
 * @param {string} uid
 * @param {string} sessionId - Session ID for scoped history (MODULE 1)
 * @param {string} message
 * @param {string} replyTo
 * @param {boolean} isPremium
 * @param {string} imageUrl - Optional image URL for vision analysis
 * @param {string} mode - Conversation mode: 'standard', 'deep', 'mentor'
 * @param {string} tarotContext - Optional tarot reading context for follow-up questions
 */
export async function processChat(uid, sessionId, message, replyTo, isPremium, imageUrl = null, mode = 'standard', tarotContext = null) {
  const startTime = Date.now();

  // SAFETY: Make sure OpenAI client exists
  if (!openai) {
    console.error(`[${uid}] 🔥 CRITICAL: OpenAI client missing (API key invalid).`);
    throw new Error("OpenAI not configured - missing API key");
  }

  // Safe message
  const safeMessage = String(message).slice(0, 5000);
  
  // Log tarot context if present
  if (tarotContext) {
    console.log(`[${uid}] Processing tarot follow-up question`);
  }

  // Load user + history + session state
  const [userProfile, rawHistory, sessionState] = await Promise.all([
    getUserProfile(uid),
    getConversationHistory(uid, sessionId), // MODULE 1: Pass sessionId
    getSessionState(uid, sessionId), // Load session state for deep scan permissions
  ]);

  const history = rawHistory?.messages || [];
  const conversationSummary = rawHistory?.summary || null;
  
  // TASK B: Gender pronoun for guidance messages
  const gender = userProfile.gender || "belirsiz";
  const genderPronoun = gender === "erkek" ? "kardeşim" : gender === "kadın" ? "kanka" : "kanka";

  console.log(
    `[${uid}] Processing - Session: ${sessionId}, Premium: ${isPremium}, Mode: ${mode}, History: ${history.length}, Summary: ${!!conversationSummary}`
  );

  // Intent detection
  const intent = detectIntentType(safeMessage, history);
  let { model, temperature, maxTokens } = getChatConfig(
    intent,
    isPremium,
    userProfile
  );

  // ═══════════════════════════════════════════════════════════════
  // VISION MODEL OVERRIDE: Eğer resim varsa, vision destekli model kullan
  // TASK A: Use gpt-5.2 for vision (assuming gpt-5 supports vision)
  // ═══════════════════════════════════════════════════════════════
  if (imageUrl) {
    // gpt-5 models should support vision
    if (model === "gpt-5-mini") {
      model = isPremium ? "gpt-5.2" : "gpt-5-mini";
      console.log(`[${uid}] Model kept for vision → ${model}`);
    }
  }

  console.log(
    `[${uid}] Intent: ${intent}, Model: ${model}, Temp: ${temperature}, MaxTokens: ${maxTokens}, Image: ${!!imageUrl}`
  );

  // Gender detection
  let detectedGender = await detectGenderSmart(safeMessage, userProfile);

  if (detectedGender !== userProfile.gender && detectedGender !== "belirsiz") {
    await updateUserGender(uid, detectedGender);
    userProfile.gender = detectedGender;
    console.log(`[${uid}] Gender updated → ${detectedGender}`);
  } else if (detectedGender === "belirsiz" && userProfile.genderAttempts < 3) {
    await incrementGenderAttempts(uid);
  }

  // Trait extraction
  const extractedTraits = await extractDeepTraits(
    safeMessage,
    replyTo,
    history
  );

  console.log(
    `[${uid}] Traits → Tone: ${extractedTraits.tone}, Urgency: ${extractedTraits.urgency}, Flags: R${extractedTraits.flags.red.length}/G${extractedTraits.flags.green.length}`
  );

  // Pattern detection
  const patterns = await detectUserPatterns(history, userProfile, isPremium);

  if (patterns) {
    console.log(
      `[${uid}] Patterns → Mistakes: ${patterns.repeatingMistakes?.length || 0}, Type: ${patterns.relationshipType}`
    );
  }

  // Outcome prediction
  const outcomePrediction = await predictOutcome(
    safeMessage,
    history,
    isPremium
  );

  if (outcomePrediction) {
    console.log(
      `[${uid}] Outcome → Interest: ${outcomePrediction.interestLevel}% / Date: ${outcomePrediction.dateProbability}%`
    );
  }

  // Update user profile
  userProfile.lastTone = normalizeTone(extractedTraits.tone);

  if (
    extractedTraits.relationshipStage &&
    extractedTraits.relationshipStage !== "none"
  ) {
    userProfile.relationshipStage = extractedTraits.relationshipStage;
  }

  if (
    extractedTraits.attachmentStyle &&
    extractedTraits.attachmentStyle !== "unknown"
  ) {
    userProfile.attachmentStyle = extractedTraits.attachmentStyle;
  }

  userProfile.totalAdviceGiven = (userProfile.totalAdviceGiven || 0) + 1;

  updateUserProfile(uid, userProfile).catch((e) =>
    console.error(`[${uid}] UserProfile update error →`, e)
  );

  // ═══════════════════════════════════════════════════════════════
  // STEP 1 & 2: Detect if query is relationship-related
  // ═══════════════════════════════════════════════════════════════
  const isRelQuery = isRelationshipQuery(safeMessage);
  let hasActiveRelationship = false;

  // Reply context
  const replyContext = replyTo
    ? `
🎯 ÖZEL YANIT MODU:
Kullanıcı şu mesaja yanıt veriyor: "${String(replyTo).slice(0, 400)}"
Cevabını buna göre kurgula.
`
    : "Normal sohbet modu.";

  // Enriched long context (Premium only)
  const enrichedContext =
    isPremium && (history.length > 5 || conversationSummary)
      ? `
📊 CONTEXT:
• Summary: ${conversationSummary || "yok"}
• Mesaj sayısı: ${userProfile.messageCount}
• Stage: ${userProfile.relationshipStage}
• Attachment: ${userProfile.attachmentStyle}
`
      : "";

  // System messages - persona will be added after relationship context check
  const systemMessages = [
    { role: "system", content: replyContext },
  ];

  if (enrichedContext) {
    systemMessages.push({ role: "system", content: enrichedContext });
  }

  // Tone and emotional adjustments
  if (
    extractedTraits.urgency === "high" ||
    extractedTraits.urgency === "critical"
  ) {
    systemMessages.push({
      role: "system",
      content: "⚠️ ACİL: Daha net ve hızlı çözüm odaklı cevap ver.",
    });
  }

  if (extractedTraits.needsSupport) {
    systemMessages.push({
      role: "system",
      content:
        "💙 Kullanıcı duygusal destek istiyor. Yumuşak ve empatik ol.",
    });
  }

  // ═══════════════════════════════════════════════════════════════
  // UPLOAD GUIDANCE GUARD: Detect upload questions and give UI instructions only
  // ═══════════════════════════════════════════════════════════════
  const uploadKeywords = [
    "nereden yükle", "nasıl yükle", "ilişki yükleme", "ilişkiyi yükle",
    "upload", "zip", "whatsapp sohbet", "sohbeti yükle", "dosya yükle",
    "nereye yükle", "nasıl ekle"
  ];
  
  const abKeywords = [
    "a ve b ne", "a b ne demek", "a veya b", "a/b ne", "kim a kim b",
    "a kimdir", "b kimdir", "a ile b"
  ];
  
  const messageLower = message.toLowerCase();
  const isUploadQuestion = uploadKeywords.some(keyword => messageLower.includes(keyword));
  const isAbQuestion = abKeywords.some(keyword => messageLower.includes(keyword));
  
  if (isUploadQuestion) {
    systemMessages.push({
      role: "system",
      content: `
🔒 UPLOAD GUIDANCE OVERRIDE:
User is asking how to upload relationship. Give ONLY these UI instructions (short, confident, 1-3 sentences):

1) "İlişkiyi yüklemek için chat bar'daki SYRA logosuna dokun."
2) "WhatsApp sohbet ZIP veya .txt dosyanı seç ve yükle."
3) "Yükledikten sonra panelden 'Chat'te kullan'ı aç."

Do NOT ask for names, details, or relationship info. Just give UI steps.
      `.trim(),
    });
  }
  
  if (isAbQuestion) {
    systemMessages.push({
      role: "system",
      content: `
🔒 A/B EXPLANATION OVERRIDE:
User is asking what A/B means. Give a brief, friendly explanation (1-2 sentences):

"A ve B, WhatsApp sohbetinde ilk yazan ve ikinci yazan kişiyi temsil eder. 'Ben A'yım' veya 'Ben B'yim' diyerek seçim yapabilirsin, ya da panelden kendin belirleyebilirsin."

Keep it simple and actionable.
      `.trim(),
    });
  }

  // ═══════════════════════════════════════════════════════════════
  // RESPONSE STYLE ENFORCEMENT: ChatGPT-quality concise responses
  // ═══════════════════════════════════════════════════════════════
  systemMessages.push({
    role: "system",
    content: `
⚡ STYLE REMINDER (CRITICAL):
• Keep responses SHORT: 1-2 sentences default
• NO filler phrases: "Buradayım", "Seni dinliyorum", "Yardımcı olabilirim", etc.
• MAX 1 question per response
• NO repeated greetings (only greet once per new chat)
• Direct action framing: "Tamam. Şunu yap: …"
• Only expand if user asks or situation requires detail
    `.trim(),
  });

  const recentHistory = history.slice(-10);

  // ═══════════════════════════════════════════════════════════════
  // TAROT CONTEXT: If this is a follow-up about a tarot reading
  // ═══════════════════════════════════════════════════════════════
  if (tarotContext) {
    systemMessages.push({
      role: "system",
      content: `🔮 TAROT CONTEXT:\n${tarotContext}\n\nŞimdi kullanıcı bu tarot açılımı hakkında soru soruyor. Açılımdaki kartları ve yorumu referans alarak cevap ver. Tarot yorumcusu gibi konuş - spesifik, tekrar odaklı, dürüst.`,
    });
  }

  // ═══════════════════════════════════════════════════════════════
  // RELATIONSHIP MEMORY V2: Smart retrieval with chunked storage
  // + DEEP SCAN PERMISSION FLOW
  // ═══════════════════════════════════════════════════════════════
  let relationshipData = null;
  let needsDeepScanPermission = false;
  
  try {
    // ═══════════════════════════════════════════════════════════════
    // HANDLE PENDING DEEP SCAN CONFIRMATION
    // ═══════════════════════════════════════════════════════════════
    if (sessionState?.pendingDeepScan) {
      console.log(`[${uid}] Pending deep scan detected, checking user response`);
      
      const userResponse = safeMessage.toLowerCase().trim();
      const affirmativeResponses = ['evet', 'tamam', 'olur', 'yap', 'hadi', 'başlat', 'yapabilirsin', 'istiyorum'];
      const negativeResponses = ['hayır', 'boşver', 'gerek yok', 'istemiyorum', 'vazgeçtim'];
      
      if (affirmativeResponses.some(r => userResponse.includes(r))) {
        // User confirmed - run retrieval with stored queryHint
        console.log(`[${uid}] User confirmed deep scan - proceeding with retrieval`);
        
        // Combine stored queryHint with current message for better context
        const combinedQuery = `${sessionState.pendingDeepScan.queryHint} ${safeMessage}`;
        relationshipData = await getRelationshipContext(uid, combinedQuery, history, sessionState);
        
        // Clear pendingDeepScan after use
        await setSessionState(uid, sessionId, { pendingDeepScan: null });
      } else if (negativeResponses.some(r => userResponse.includes(r))) {
        // User declined - clear pending state and continue without memory
        console.log(`[${uid}] User declined deep scan - continuing without relationship memory`);
        await setSessionState(uid, sessionId, { pendingDeepScan: null });
        relationshipData = null;
      } else {
        // Ambiguous response - ask for clarification
        systemMessages.push({
          role: "system",
          content: `
🔄 CLARIFICATION NEEDED:
User has a pending deep scan permission request.
Their response was unclear. Ask them directly in Turkish:
"Kayıtlarda arama yapmamı istiyor musun? (Evet/Hayır)"
Keep it short and conversational.
          `.trim(),
        });
      }
    } else {
      // Normal flow - check if relationship context is needed
      relationshipData = await getRelationshipContext(uid, safeMessage, history, sessionState);
    }
    
    // ═══════════════════════════════════════════════════════════════
    // HANDLE PERMISSION REQUEST
    // ═══════════════════════════════════════════════════════════════
    if (relationshipData?.needsPermission) {
      console.log(`[${uid}] Deep scan permission needed - setting pendingDeepScan`);
      needsDeepScanPermission = true;
      
      // Store pending deep scan in session state
      await setSessionState(uid, sessionId, {
        pendingDeepScan: {
          type: 'search_request',
          queryHint: relationshipData.queryHint,
          createdAt: new Date().toISOString(),
        }
      });
      
      // Inject permission prompt
      systemMessages.push({
        role: "system",
        content: `
🔍 DEEP SCAN PERMISSION REQUEST:
User asked for evidence/search but query is underspecified.
Respond ONLY with this permission question in Turkish (natural, conversational):

"Bunu daha net görmek için ilişki kayıtlarında arama yapıp 1–2 kısa alıntı çıkarabilirim. Yapmamı ister misin?"

Do NOT answer their question yet. Do NOT provide analysis. Just ask permission.
        `.trim(),
      });
      
      // Don't inject full relationship context yet
      hasActiveRelationship = true; // Mark as having relationship for persona
    }
    
    // ═══════════════════════════════════════════════════════════════
    // INJECT RELATIONSHIP CONTEXT (if not waiting for permission)
    // ═══════════════════════════════════════════════════════════════
    if (relationshipData && relationshipData.context && !needsDeepScanPermission) {
      hasActiveRelationship = true;
      
      // ═══════════════════════════════════════════════════════════════
      // AUTO-PERSIST SELFPARTICIPANT
      // If selfParticipant is missing, detect if user is answering the clarification question
      // ═══════════════════════════════════════════════════════════════
      if (!relationshipData.selfParticipant && relationshipData.speakers && relationshipData.speakers.length >= 2) {
        const { detectSelfParticipantFromMessage, persistSelfParticipant, getActiveRelationshipContext, buildParticipantContextPrompt } = await import("./relationshipContext.js");
        
        const detectedSpeaker = detectSelfParticipantFromMessage(safeMessage, relationshipData.speakers);
        
        if (detectedSpeaker) {
          console.log(`[${uid}] 🎯 Detected self-participant from message: ${detectedSpeaker}`);
          
          // Persist to Firestore
          const persistSuccess = await persistSelfParticipant(
            uid,
            relationshipData.relationshipId,
            detectedSpeaker,
            relationshipData.speakers
          );
          
          if (persistSuccess) {
            console.log(`[${uid}] ✅ Auto-set selfParticipant to: ${detectedSpeaker}`);
            
            // Rebuild relationship context with updated participant mapping
            const updatedContext = await getActiveRelationshipContext(uid);
            if (updatedContext) {
              relationshipData.selfParticipant = updatedContext.selfParticipant;
              relationshipData.partnerParticipant = updatedContext.partnerParticipant;
              
              // Rebuild participant context prompt
              relationshipData.participantContext = buildParticipantContextPrompt(updatedContext);
              
              console.log(`[${uid}] 🔄 Rebuilt participant context with USER=${updatedContext.selfParticipant}, PARTNER=${updatedContext.partnerParticipant}`);
            }
          }
        }
      }
      
      // Inject relationship context
      systemMessages.push({
        role: "system",
        content: relationshipData.context,
      });
      
      // ═══════════════════════════════════════════════════════════════
      // PATCH C: Detect relationship context change and inject override
      // ═══════════════════════════════════════════════════════════════
      const shouldInjectOverride = await checkRelationshipContextChange(
        uid,
        relationshipData.relationshipId,
        relationshipData.updatedAt
      );
      
      if (shouldInjectOverride) {
        systemMessages.push({
          role: "system",
          content: `
🔄 RELATIONSHIP CONTEXT UPDATED (CRITICAL):
The active relationship has just been changed or toggled ON.
IGNORE any previous assumptions about who is who from earlier in this chat.
Use ONLY the current relationship participants provided above:
- USER = ${relationshipData.selfParticipant || 'to be determined'}
- PARTNER = ${relationshipData.partnerParticipant || 'to be determined'}

Previous partner names or relationship details from earlier turns are now INVALID.
Base all responses on the CURRENT active relationship context only.
          `.trim(),
        });
        console.log(`[${uid}] 🔄 Relationship context change detected - override injected`);
      }
      
      // CRITICAL: Inject participant mapping context
      if (relationshipData.participantContext) {
        systemMessages.push({
          role: "system",
          content: relationshipData.participantContext,
        });
      }
      
      console.log(`[${uid}] 📱 Relationship context loaded (retrieval: ${relationshipData.hasRetrieval}, participant mapping: ${!!relationshipData.participantContext})`);
    } else {
      // ═══════════════════════════════════════════════════════════════
      // STEP 2: No active relationship - check if user is asking about messages
      // ═══════════════════════════════════════════════════════════════
      const readMessagesKeywords = [
        "son mesaj", "last message", "mesajları oku", "read messages",
        "mesajları gör", "mesajları incele", "mesajlara bak", "konuşmaları oku",
        "yazışmaları oku", "sohbetleri oku"
      ];
      const messageLower = safeMessage.toLowerCase();
      const isAskingForMessages = readMessagesKeywords.some(k => messageLower.includes(k));
      
      // TASK B: Don't inject system prompt, handle in response below
      if (isAskingForMessages && isRelQuery) {
        console.log(`[${uid}] ⚠️ User asking for messages but no active relationship`);
      } else if (history.length > 0 && isRelQuery) {
        console.log(`[${uid}] 🚫 No active relationship but relationship query detected`);
      }
    }
  } catch (memErr) {
    console.error(`[${uid}] Failed to load relationship context (non-critical):`, memErr);
  }

  // ═══════════════════════════════════════════════════════════════
  // STEP 1 & 2: Build persona AFTER relationship context check
  // Persona needs to know hasActiveRelationship status
  // ═══════════════════════════════════════════════════════════════
  const persona = buildUltimatePersona(
    isPremium,
    userProfile,
    extractedTraits,
    patterns,
    conversationSummary,
    mode,
    hasActiveRelationship,
    isRelQuery
  );
  
  // Inject persona at the beginning of system messages
  systemMessages.unshift({ role: "system", content: persona });
  
  console.log(`[${uid}] Persona built: hasActiveRelationship=${hasActiveRelationship}, isRelQuery=${isRelQuery}`);
  
  // ═══════════════════════════════════════════════════════════════
  // TASK B: If relationship query but NO active relationship, return guidance immediately
  // ═══════════════════════════════════════════════════════════════
  if (isRelQuery && !hasActiveRelationship) {
    const guidanceReply = `Şu an bu ilişki aktif değil ${genderPronoun}. "Relationship Upload" panelinden ilişkiyi aktif edersen son mesajlara bakabilirim. Hangi ilişkiyle ilgili konuşmak istiyorsun?`;
    
    console.log(`[${uid}] 🚫 Returning guidance for inactive relationship query`);
    
    // Save to history
    await saveConversationHistory(uid, sessionId, safeMessage, guidanceReply, {
      messages: Array.isArray(rawHistory?.messages) ? rawHistory.messages : [],
      summary: rawHistory?.summary ?? null,
      lastSummaryAt: rawHistory?.lastSummaryAt ?? null,
    }).catch((e) => console.error(`[${uid}] History save error →`, e));
    
    return {
      reply: guidanceReply,
      extractedTraits,
      outcomePrediction: undefined,
      patterns: undefined,
      meta: {
        intent,
        model: "none",
        premium: isPremium,
        messageCount: userProfile.messageCount,
        processingTime: Date.now() - startTime,
        hadError: false,
        errorType: null,
        inactiveRelationshipGuidance: true,
      },
    };
  }

  // ═══════════════════════════════════════════════════════════════
  // VISION SUPPORT: Eğer imageUrl varsa, user message'ı vision formatında gönder
  // ═══════════════════════════════════════════════════════════════
  let userMessageContent;
  
  if (imageUrl) {
    // Vision API formatı: content array ile
    userMessageContent = [
      {
        type: "text",
        text: safeMessage || "Bu resimle ilgili ne düşünüyorsun?",
      },
      {
        type: "image_url",
        image_url: {
          url: imageUrl,
          detail: "auto", // "low", "high", "auto"
        },
      },
    ];
    console.log(`[${uid}] 📸 Image attached to message → Vision mode enabled`);
  } else {
    // Normal text message
    userMessageContent = safeMessage;
  }

  const contextMessages = [
    ...systemMessages,
    ...recentHistory,
    { role: "user", content: userMessageContent },
  ];

  let replyText = null;
  let openaiError = null;

  // ═══════════════════════════════════════════════════════════════
  // STEP 3: OUTPUT GUARD - retry if response is generic/empty
  // STEP 4: MODEL FALLBACK - if primary fails, try fallback model
  // ═══════════════════════════════════════════════════════════════
  let retryAttempted = false;
  let fallbackAttempted = false;
  let originalModel = model;

  // OPENAI CALL with fallback
  try {
    console.log(`[${uid}] Calling OpenAI → ${model}`);

    let completion;
    
    try {
      completion = await openai.chat.completions.create({
        model,
        messages: contextMessages,
        max_completion_tokens: maxTokens, // GPT-5 models use max_completion_tokens
      });
    } catch (primaryError) {
      // TASK A: Check if error is rate limit or model-specific
      const errorMessage = primaryError?.message?.toLowerCase() || '';
      const isRateLimit = errorMessage.includes('rate') || errorMessage.includes('429');
      const isModelError = errorMessage.includes('model') || errorMessage.includes('not found');
      
      if ((isRateLimit || isModelError) && model !== MODEL_FALLBACK) {
        console.log(`[${uid}] ⚠️ Primary model failed (${primaryError.message}), falling back to ${MODEL_FALLBACK}`);
        fallbackAttempted = true;
        model = MODEL_FALLBACK; // Fallback to gpt-5-mini
        
        completion = await openai.chat.completions.create({
          model,
          messages: contextMessages,
          max_completion_tokens: maxTokens, // GPT-5 models use max_completion_tokens
        });
      } else {
        throw primaryError; // Re-throw if not a fallback scenario
      }
    }

    if (
      completion &&
      completion.choices &&
      completion.choices[0]?.message?.content
    ) {
      replyText = completion.choices[0].message.content.trim();
      console.log(
        `[${uid}] OpenAI success → Model: ${model}, Reply length: ${replyText.length}`
      );
      
      // STEP 3: Check if response is too generic/empty
      const isGeneric = checkIfGenericResponse(replyText);
      
      if (isGeneric && !retryAttempted) {
        console.log(`[${uid}] ⚠️ Generic response detected, retrying with stronger prompt`);
        retryAttempted = true;
        
        // Add stronger instruction and retry ONCE
        const retryMessages = [
          ...contextMessages.slice(0, -1), // All except last user message
          {
            role: "system",
            content: `
⚠️ CRITICAL QUALITY INSTRUCTION:
Previous response was too generic/vague. This time:
• Be CONCRETE and SPECIFIC
• Give 1-3 ACTIONABLE steps
• Ask MAX 1 clarifying question if truly needed
• NO filler phrases ("Buradayım", "Yardımcı olabilirim", etc.)
• Get straight to the point
            `.trim()
          },
          contextMessages[contextMessages.length - 1] // Last user message
        ];
        
        const retryCompletion = await openai.chat.completions.create({
          model,
          messages: retryMessages,
          max_completion_tokens: maxTokens, // GPT-5 models use max_completion_tokens
        });
        
        if (retryCompletion?.choices?.[0]?.message?.content) {
          replyText = retryCompletion.choices[0].message.content.trim();
          console.log(`[${uid}] ✅ Retry successful → Reply length: ${replyText.length}`);
        }
      }
    } else {
      openaiError = "EMPTY_COMPLETION";
    }
  } catch (e) {
    console.error(`[${uid}] 🔥 OpenAI API ERROR:`, e);
    openaiError = e?.message || "UNKNOWN_OPENAI_ERROR";
  }

  // FALLBACK REPLY
  if (!replyText) {
    replyText =
      "Sistem şu an cevap üretemedi kanka. Bir daha dene, bu sefer olacak. 💪";
    console.warn(`[${uid}] Fallback reply used → ${openaiError}`);
  }

  /**
   * ════════════════════════════════════════════════
   * FIRESTORE-SAFE HISTORY SAVE FIX
   * ════════════════════════════════════════════════
   * lastSummaryAt, summary, messages… hiçbir alan artık undefined kalamaz.
   */

  const safeHistoryObject = {
    messages: Array.isArray(rawHistory?.messages)
      ? rawHistory.messages
      : [],
    summary: rawHistory?.summary ?? null,
    lastSummaryAt: rawHistory?.lastSummaryAt ?? null,
  };

  await saveConversationHistory(uid, sessionId, safeMessage, replyText, safeHistoryObject).catch(
    (e) => console.error(`[${uid}] History save error →`, e)
  );

  const processingTime = Date.now() - startTime;

  console.log(
    `[${uid}] ✅ DONE (${processingTime}ms) → Success: ${!openaiError}`
  );

  return {
    reply: replyText,
    extractedTraits,
    outcomePrediction: isPremium ? outcomePrediction : undefined,
    patterns: isPremium ? patterns : undefined,
    meta: {
      intent,
      model,
      originalModel: fallbackAttempted ? originalModel : model, // STEP 4: Track if fallback was used
      usedFallback: fallbackAttempted, // STEP 4
      premium: isPremium,
      messageCount: userProfile.messageCount,
      processingTime,
      hadError: !!openaiError,
      errorType: openaiError,
    },
  };
}

/**
 * ═══════════════════════════════════════════════════════════════
 * PATCH C: Check if relationship context was recently changed
 * ═══════════════════════════════════════════════════════════════
 * Returns true if relationship was updated in the last 2 minutes
 * This indicates a toggle ON or relationship switch in same chat
 */
async function checkRelationshipContextChange(uid, relationshipId, relationshipUpdatedAt) {
  try {
    // Get user doc to check last known relationship state
    const userDoc = await firestore.collection("users").doc(uid).get();
    const userData = userDoc.data();
    
    if (!userData) return false;
    
    // Parse relationship updatedAt timestamp
    let relationshipTimestamp = null;
    if (relationshipUpdatedAt) {
      if (relationshipUpdatedAt.toDate) {
        relationshipTimestamp = relationshipUpdatedAt.toDate();
      } else if (relationshipUpdatedAt._seconds) {
        relationshipTimestamp = new Date(relationshipUpdatedAt._seconds * 1000);
      } else if (typeof relationshipUpdatedAt === "string") {
        relationshipTimestamp = new Date(relationshipUpdatedAt);
      }
    }
    
    if (!relationshipTimestamp) return false;
    
    // Check if relationship was updated in last 2 minutes
    const twoMinutesAgo = new Date(Date.now() - 2 * 60 * 1000);
    const isRecentlyUpdated = relationshipTimestamp > twoMinutesAgo;
    
    if (isRecentlyUpdated) {
      console.log(`[${uid}] Relationship recently updated: ${relationshipTimestamp.toISOString()}`);
      return true;
    }
    
    // Also check if activeRelationshipId changed recently
    const lastKnownRelId = userData.lastKnownRelationshipId;
    if (lastKnownRelId && lastKnownRelId !== relationshipId) {
      console.log(`[${uid}] Relationship ID changed: ${lastKnownRelId} → ${relationshipId}`);
      
      // Update last known relationship ID
      await firestore.collection("users").doc(uid).set({
        lastKnownRelationshipId: relationshipId,
      }, { merge: true });
      
      return true;
    }
    
    // If this is first time seeing this relationship ID, store it
    if (!lastKnownRelId) {
      await firestore.collection("users").doc(uid).set({
        lastKnownRelationshipId: relationshipId,
      }, { merge: true });
    }
    
    return false;
  } catch (error) {
    console.error(`[${uid}] Error checking relationship context change:`, error);
    return false; // Safe default
  }
}

/**
 * ═══════════════════════════════════════════════════════════════
 * STEP 3: Check if response is too generic/empty (OUTPUT GUARD)
 * ═══════════════════════════════════════════════════════════════
 * Returns true if response lacks actionable content
 */
function checkIfGenericResponse(text) {
  if (!text || text.length < 10) {
    return true; // Too short
  }
  
  // Forbidden filler phrases that indicate generic response
  const fillerPhrases = [
    "buradayım",
    "seni dinliyorum",
    "yardımcı olabilirim",
    "başka bir şey var mı",
    "ne düşünüyorsun",
    "umarım beğenirsin",
    "ihtiyacın olan her şey",
  ];
  
  const lowerText = text.toLowerCase();
  
  // Count how many filler phrases are present
  const fillerCount = fillerPhrases.filter(phrase => lowerText.includes(phrase)).length;
  
  // If response is short AND has filler phrases, it's generic
  if (text.length < 100 && fillerCount >= 2) {
    return true;
  }
  
  // If response has 3+ filler phrases regardless of length, it's generic
  if (fillerCount >= 3) {
    return true;
  }
  
  return false;
}