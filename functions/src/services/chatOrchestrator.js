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
import { 
  analyzeTurkishCulturalContext,
  extractContextFromMessage,
  generateRedFlagSummary
} from "../domain/turkishCultureEngine.js"; // MODULE 3
import { 
  MODEL_FALLBACK,
  MAX_RETRY_ATTEMPTS,
  RETRY_BASE_DELAY_MS,
  RETRY_MAX_JITTER_MS
} from "../utils/constants.js";

import {
  getUserProfile,
  updateUserProfile,
  incrementGenderAttempts,
  updateUserGender,
} from "../firestore/userProfileRepository.js";

import {
  getConversationHistory,
  saveConversationHistory,
} from "../firestore/conversationRepository.js";

import { db as firestore } from "../config/firebaseAdmin.js";
import { getRelationshipContext } from "./relationshipRetrieval.js";

/**
 * ═══════════════════════════════════════════════════════════════
 * MODULE 2.5: RETRY HELPER WITH EXPONENTIAL BACKOFF + JITTER
 * ═══════════════════════════════════════════════════════════════
 */
async function sleep(ms) {
  return new Promise(resolve => setTimeout(resolve, ms));
}

function getRetryDelay(attemptNumber) {
  // Exponential backoff: 2^attempt * base delay
  const exponentialDelay = Math.pow(2, attemptNumber) * RETRY_BASE_DELAY_MS;
  // Add random jitter to prevent thundering herd
  const jitter = Math.random() * RETRY_MAX_JITTER_MS;
  return exponentialDelay + jitter;
}

function isRetryableError(error) {
  if (!error) return false;
  
  const errorMessage = error?.message?.toLowerCase() || '';
  const errorCode = error?.status || error?.code;
  
  // Retry on rate limits
  if (errorCode === 429 || errorMessage.includes('rate limit')) {
    return true;
  }
  
  // Retry on 5xx server errors
  if (errorCode >= 500 && errorCode < 600) {
    return true;
  }
  
  // Retry on network timeouts
  if (errorMessage.includes('timeout') || 
      errorMessage.includes('econnreset') ||
      errorMessage.includes('network')) {
    return true;
  }
  
  return false;
}

/**
 * ═══════════════════════════════════════════════════════════════
 * MODULE 2.5: ROBUST OPENAI CALL WITH RETRY + FALLBACK
 * ═══════════════════════════════════════════════════════════════
 */
async function callOpenAIWithRetry(uid, model, messages, maxTokens) {
  let lastError = null;
  let currentModel = model;
  let usedFallback = false;
  
  // Try primary model with retries
  for (let attempt = 0; attempt < MAX_RETRY_ATTEMPTS; attempt++) {
    try {
      console.log(`[${uid}] [OPENAI_ATTEMPT] Attempt ${attempt + 1}/${MAX_RETRY_ATTEMPTS} with model ${currentModel}`);
      
      const completion = await openai.chat.completions.create({
        model: currentModel,
        messages: messages,
        max_completion_tokens: maxTokens,
        temperature: 0.4,
      });
      
      // Check for empty completion
      if (!completion?.choices?.[0]?.message?.content) {
        throw new Error('EMPTY_COMPLETION');
      }
      
      const replyText = completion.choices[0].message.content.trim();
      
      if (!replyText || replyText.length < 5) {
        throw new Error('EMPTY_COMPLETION');
      }
      
      console.log(`[${uid}] ✅ OpenAI success → Model: ${currentModel}, Reply length: ${replyText.length}`);
      
      return {
        replyText,
        model: currentModel,
        originalModel: model,
        usedFallback,
        hadError: false,
      };
      
    } catch (error) {
      lastError = error;
      const errorMessage = error?.message || 'Unknown error';
      const errorStatus = error?.status || error?.code || 'N/A';
      
      console.error(`[${uid}] [OPENAI_RETRY] Attempt ${attempt + 1} failed → Status: ${errorStatus}, Error: ${errorMessage}`);
      
      // Check if this is retryable
      const shouldRetry = isRetryableError(error) || errorMessage.includes('EMPTY_COMPLETION');
      
      if (shouldRetry && attempt < MAX_RETRY_ATTEMPTS - 1) {
        const delay = getRetryDelay(attempt);
        console.log(`[${uid}] [OPENAI_RETRY] Waiting ${Math.round(delay)}ms before retry ${attempt + 2}`);
        await sleep(delay);
        continue; // Try again with same model
      }
      
      // If we've exhausted retries, break and try fallback
      break;
    }
  }
  
  // If primary model failed after all retries, try fallback model
  if (currentModel !== MODEL_FALLBACK) {
    console.log(`[${uid}] [OPENAI_FALLBACK_MODEL] Primary model ${currentModel} failed after ${MAX_RETRY_ATTEMPTS} attempts. Trying fallback: ${MODEL_FALLBACK}`);
    
    try {
      // Trim messages to reduce payload size for fallback
      const trimmedMessages = messages.length > 10 
        ? [...messages.slice(0, 5), ...messages.slice(-5)] // Keep first 5 and last 5
        : messages;
      
      const completion = await openai.chat.completions.create({
        model: MODEL_FALLBACK,
        messages: trimmedMessages,
        max_completion_tokens: Math.min(maxTokens, 800), // Reduce token limit for fallback
        temperature: 0.4,
      });
      
      if (!completion?.choices?.[0]?.message?.content) {
        throw new Error('EMPTY_COMPLETION');
      }
      
      const replyText = completion.choices[0].message.content.trim();
      
      if (!replyText || replyText.length < 5) {
        throw new Error('EMPTY_COMPLETION');
      }
      
      console.log(`[${uid}] ✅ [OPENAI_FALLBACK_MODEL] Fallback successful → Model: ${MODEL_FALLBACK}, Reply length: ${replyText.length}`);
      
      return {
        replyText,
        model: MODEL_FALLBACK,
        originalModel: model,
        usedFallback: true,
        hadError: false,
      };
      
    } catch (fallbackError) {
      console.error(`[${uid}] [OPENAI_FINAL_FAIL] Fallback model also failed → ${fallbackError?.message}`);
      lastError = fallbackError;
    }
  }
  
  // All attempts failed
  console.error(`[${uid}] [OPENAI_FINAL_FAIL] All retry attempts exhausted. Last error: ${lastError?.message}`);
  
  return {
    replyText: null,
    model: currentModel,
    originalModel: model,
    usedFallback,
    hadError: true,
    errorType: lastError?.message || 'UNKNOWN_OPENAI_ERROR',
  };
}

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

  // Load user + history
  const [userProfile, rawHistory] = await Promise.all([
    getUserProfile(uid),
    getConversationHistory(uid, sessionId), // MODULE 1: Pass sessionId
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
  // gpt-4o models support vision
  // ═══════════════════════════════════════════════════════════════
  if (imageUrl) {
    // gpt-4o models support vision
    if (model === "gpt-4o-mini") {
      model = isPremium ? "gpt-4o" : "gpt-4o-mini";
      console.log(`[${uid}] Model kept for vision → ${model}`);
    }
  }

  console.log(
    `[${uid}] Intent: ${intent}, Model: ${model}, Temp: ${temperature}, MaxTokens: ${maxTokens}, Image: ${!!imageUrl}`
  );

  // ═══════════════════════════════════════════════════════════════
  // MODULE 3: Deep Analysis Trigger Detection
  // ═══════════════════════════════════════════════════════════════
  let turkishCultureAnalysis = null;
  let shouldDeepAnalyze = false;
  
  if (intent === "deep_relationship_issue" || intent === "pattern_analysis") {
    console.log(`[${uid}] 🔬 MODULE 3: Deep analysis triggered - Intent: ${intent}`);
    shouldDeepAnalyze = true;
    
    // Extract context from message
    const extractedContext = extractContextFromMessage(safeMessage);
    
    // Analyze with Turkish culture engine
    turkishCultureAnalysis = analyzeTurkishCulturalContext(extractedContext);
    
    console.log(`[${uid}] 🚩 MODULE 3: Detected ${turkishCultureAnalysis.length} red flag pattern(s)`);
    
    if (turkishCultureAnalysis.length > 0) {
      turkishCultureAnalysis.forEach(flag => {
        console.log(`[${uid}]    - ${flag.type} (${flag.severity})`);
      });
    }
  }

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
  // MODULE 3: Deep Analysis Context Injection
  // ═══════════════════════════════════════════════════════════════
  if (shouldDeepAnalyze && turkishCultureAnalysis && turkishCultureAnalysis.length > 0) {
    const redFlagSummary = generateRedFlagSummary(turkishCultureAnalysis);
    
    systemMessages.push({
      role: "system",
      content: `
🔬 DERIN ANALİZ MODU AKTİF (MODULE 3)

Kullanıcı ilişkisinde ciddi pattern'ler tespit edildi.
Türk kültürü bağlamında şu red flag'ler var:

${redFlagSummary}

ÖNEMLİ TALIMATLAR:
1. Bu pattern'leri kullanıcıya açıkla (yargılamadan)
2. Türk kültürü bağlamını ver (neden bu önemli?)
3. Somut aksiyon adımları öner
4. Empati göster ama gerçekçi ol
5. Red flag ciddiyse, net söyle

Eğer relationship context aktifse, ZIP'ten mesaj örnekleri de göster.
      `.trim()
    });
    
    console.log(`[${uid}] 🔬 MODULE 3: Deep analysis context injected into system prompt`);
  }

  // ═══════════════════════════════════════════════════════════════
  // MODULE 3.1: Intent-Based Question Policy
  // ═══════════════════════════════════════════════════════════════
  if (intent === "greeting") {
    // MODULE 3.1.1 HOTFIX 1: Natural greeting with ONE greeting question
    systemMessages.push({
      role: "system",
      content: `
💬 GREETING MODE (MODULE 3.1.1 HOTFIX)

User sent a simple greeting (selam, naber, etc.).
Your response:
"İyiyim kanka. Sende naber?"

RULES:
✅ ONE natural greeting question: "Sende naber?" or "Sen nasılsın?"
❌ NO generic topic questions: "Ne hakkında konuşalım?"
❌ NO extended conversation prompts

Keep it SHORT and NATURAL.
      `.trim()
    });
  } else if (intent === "message_drafting") {
    // MODULE 3.1.1 HOTFIX 3: Multi-choice question for message drafting
    systemMessages.push({
      role: "system",
      content: `
🎯 MESSAGE DRAFTING MODE (MODULE 3.1.1 HOTFIX)

User wants help writing a message.

STEP 1: Ask ONE multi-choice question (if context missing):
"Kanka 1) yeni tanıştınız 2) flört 3) sevgili 4) ex — hangisi?
 Hedef: A) ilgiyi artır B) randevu C) sınır koy D) barış"

STEP 2: Immediately provide 2-3 draft options anyway (don't wait):
- Soft: [yumuşak versiyon]
- Cool: [rahat versiyon]
- Spicy: [flört/cesur versiyon]

Max 1 question. Always provide drafts even before user answers.

FORBIDDEN:
❌ "Ne hakkında konuşmak istersin?"
❌ "Başka bir şey var mı?"
      `.trim()
    });
  } else if (intent === "context_missing") {
    systemMessages.push({
      role: "system",
      content: `
🔍 CONTEXT MISSING MODE (MODULE 3.1)

User wants help but request is vague. Your response:
1. Make reasonable assumption
2. Provide solution based on assumption
3. If truly critical info missing, ask 1 specific question

ALLOWED QUESTION (max 1):
✅ "Hangi ilişkiden bahsediyorsun?"
✅ "Kime/neyle ilgili bu?"

THEN provide direct advice. Don't wait for answer.
      `.trim()
    });
  } else if (intent === "deep_relationship_issue" || intent === "pattern_analysis") {
    // MODULE 3.1.1 HOTFIX 2: Evidence-gated question policy
    const hasEvidence = relationshipData && relationshipData.hasRetrieval && 
                       relationshipData.context && relationshipData.context.includes("📎 ALAKALI SOHBET");
    
    if (hasEvidence) {
      // Evidence exists - NO questions allowed
      systemMessages.push({
        role: "system",
        content: `
🔬 DEEP ANALYSIS MODE - EVIDENCE AVAILABLE (MODULE 3.1.1)

You have concrete evidence from relationship messages.
Provide grounded analysis WITHOUT asking questions.

Use probabilistic language:
✅ "Mesajlara bakınca [pattern] görüyorum"
✅ "X kez bu davranış var"
✅ "Bu [pattern]'e benziyor"
❌ "Kesinlikle manipülasyon" (unless evidence is very strong)

Provide analysis + action steps directly.
NO QUESTIONS.
        `.trim()
      });
    } else {
      // No evidence - Allow 1 targeted question
      systemMessages.push({
        role: "system",
        content: `
🔬 DEEP ANALYSIS MODE - NO EVIDENCE (MODULE 3.1.1)

No ZIP messages available for this relationship.
You can ask ONE targeted clarification question to reduce hallucination.

ALLOWED (max 1 targeted question):
✅ "Bu istek haftada kaç kez oluyor?"
✅ "Sen 'hayır' deyince trip/guilt yapıyor mu?"
✅ "Karşılıklı mı yoksa tek taraflı mı?"

FORBIDDEN:
❌ "Ne hakkında konuşmak istersin?"
❌ "Daha fazla bilgi verir misin?"

CRITICAL: After question, immediately provide boundary-setting suggestion.
Do NOT wait for answer. Give both question AND advice in same message.

Use probabilistic language:
✅ "Bu [pattern]'e benziyor"
✅ "Olabilir"
❌ "Kesinlikle manipülasyon"
        `.trim()
      });
    }
  } else if (intent === "normal") {
    // Small talk / normal conversation
    systemMessages.push({
      role: "system",
      content: `
💬 NORMAL CONVERSATION MODE - NO QUESTIONS (MODULE 3.1)

This is small talk or casual conversation.
Keep response SHORT (1-2 sentences).
NO follow-up questions.

Examples:
User: "Naber"
✅ "İyi kanka."
❌ "İyiyim! Sen nasılsın? Ne yapıyorsun?"

User: "İyiyim"
✅ "Güzel. Bir sorun olursa söyle."
❌ "İyi! Neyle ilgileniyorsun?"
      `.trim()
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
      content: `🔮 TAROT CONTEXT:\n${tarotContext}\n\nŞimdi kullanıcı bu tarot açılımı hakkında soru soruyor. Açılımdaki kartları ve yorumu referans alarak cevap ver. Tarot yorumcusu gibi konuş - spesifik, pattern-based, dürüst.`,
    });
  }

  // ═══════════════════════════════════════════════════════════════
  // RELATIONSHIP MEMORY V2: Smart retrieval with chunked storage
  // STEP 2 FIX: Proper gating - only use if isActive=true
  // ═══════════════════════════════════════════════════════════════
  let relationshipData = null;
  try {
    relationshipData = await getRelationshipContext(uid, safeMessage, history);
    
    // STEP 2: Relationship MUST be active to use context
    if (relationshipData && relationshipData.context) {
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
  // MODULE 2.5: ROBUST OPENAI CALL WITH RETRY + FALLBACK
  // ═══════════════════════════════════════════════════════════════
  let originalModel = model;
  let usedFallback = false;

  console.log(`[${uid}] Calling OpenAI with robust retry → ${model}`);

  const openaiResult = await callOpenAIWithRetry(uid, model, contextMessages, maxTokens);
  
  replyText = openaiResult.replyText;
  model = openaiResult.model;
  originalModel = openaiResult.originalModel;
  usedFallback = openaiResult.usedFallback;
  
  if (openaiResult.hadError) {
    openaiError = openaiResult.errorType;
  }

  // FALLBACK REPLY
  if (!replyText) {
    replyText =
      "Sistem şu an cevap üretemedi kanka. Bir daha dene, bu sefer olacak. 💪";
    console.warn(`[${uid}] Fallback reply used → ${openaiError}`);
  } else {
    // STEP 3: Check if response is too generic/empty (OUTPUT GUARD)
    const isGeneric = checkIfGenericResponse(replyText);
    
    if (isGeneric) {
      console.log(`[${uid}] ⚠️ Generic response detected, retrying with stronger prompt`);
      
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
      
      try {
        const retryCompletion = await openai.chat.completions.create({
          model,
          messages: retryMessages,
          max_completion_tokens: maxTokens,
          temperature: 0.4,
        });
        
        if (retryCompletion?.choices?.[0]?.message?.content) {
          const retryReply = retryCompletion.choices[0].message.content.trim();
          if (retryReply && retryReply.length > 10) {
            replyText = retryReply;
            console.log(`[${uid}] ✅ Generic retry successful → Reply length: ${replyText.length}`);
          }
        }
      } catch (retryError) {
        console.error(`[${uid}] Generic retry failed, keeping original response:`, retryError?.message);
      }
    }
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
      originalModel,
      usedFallback,
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