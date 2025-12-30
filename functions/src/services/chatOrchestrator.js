/**
 * ═══════════════════════════════════════════════════════════════
 * CHAT ORCHESTRATOR - FIXED + STABLE VERSION (FINAL)
 * ═══════════════════════════════════════════════════════════════
 * Handles all chat logic, trait extraction, persona building,
 * OpenAI calls and Firestore-safe conversation history saving.
 */

import { openai } from "../config/openaiClient.js";
import { detectIntentType, getChatConfig } from "../domain/intentEngine.js";
import { buildUltimatePersona, normalizeTone } from "../domain/personaEngine.js";
import { extractDeepTraits } from "../domain/traitEngine.js";
import { predictOutcome } from "../domain/outcomePredictionEngine.js";
import { detectUserPatterns } from "../domain/patternEngine.js";
import { detectGenderSmart } from "../domain/genderEngine.js";

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
 * MAIN CHAT PROCESSOR
 * @param {string} uid
 * @param {string} message
 * @param {string} replyTo
 * @param {boolean} isPremium
 * @param {string} imageUrl - Optional image URL for vision analysis
 * @param {string} mode - Conversation mode: 'standard', 'deep', 'mentor'
 * @param {string} tarotContext - Optional tarot reading context for follow-up questions
 */
export async function processChat(uid, message, replyTo, isPremium, imageUrl = null, mode = 'standard', tarotContext = null) {
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
    getConversationHistory(uid),
  ]);

  const history = rawHistory?.messages || [];
  const conversationSummary = rawHistory?.summary || null;

  console.log(
    `[${uid}] Processing - Premium: ${isPremium}, Mode: ${mode}, History: ${history.length}, Summary: ${!!conversationSummary}`
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
  // ═══════════════════════════════════════════════════════════════
  if (imageUrl) {
    // gpt-4o veya gpt-4-turbo vision destekliyor
    if (model === "gpt-4o-mini" || model === "gpt-3.5-turbo") {
      model = isPremium ? "gpt-4o" : "gpt-4o-mini";
      console.log(`[${uid}] Model upgraded for vision → ${model}`);
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

  // Persona
  const persona = buildUltimatePersona(
    isPremium,
    userProfile,
    extractedTraits,
    patterns,
    conversationSummary,
    mode
  );

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

  // System messages
  const systemMessages = [
    { role: "system", content: persona },
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
  // ═══════════════════════════════════════════════════════════════
  try {
    const relationshipData = await getRelationshipContext(uid, safeMessage, history);
    
    if (relationshipData && relationshipData.context) {
      systemMessages.push({
        role: "system",
        content: relationshipData.context,
      });
      
      console.log(`[${uid}] 📱 Relationship context loaded (retrieval: ${relationshipData.hasRetrieval})`);
    }
  } catch (memErr) {
    console.error(`[${uid}] Failed to load relationship context (non-critical):`, memErr);
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

  // OPENAI CALL
  try {
    console.log(`[${uid}] Calling OpenAI → ${model}`);

    const completion = await openai.chat.completions.create({
      model,
      messages: contextMessages,
      temperature,
      max_tokens: maxTokens,
      presence_penalty: 0.6,
      frequency_penalty: 0.3,
    });

    if (
      completion &&
      completion.choices &&
      completion.choices[0]?.message?.content
    ) {
      replyText = completion.choices[0].message.content.trim();
      console.log(
        `[${uid}] OpenAI success → Reply length: ${replyText.length}`
      );
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

  await saveConversationHistory(uid, safeMessage, replyText, safeHistoryObject).catch(
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
      premium: isPremium,
      messageCount: userProfile.messageCount,
      processingTime,
      hadError: !!openaiError,
      errorType: openaiError,
    },
  };
}
