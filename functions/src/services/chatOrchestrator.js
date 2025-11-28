/**
 * ═══════════════════════════════════════════════════════════════
 * CHAT ORCHESTRATOR
 * ═══════════════════════════════════════════════════════════════
 * Orchestrates all chat logic:
 * - Intent detection
 * - Trait extraction
 * - Gender detection
 * - Pattern recognition
 * - Outcome prediction
 * - Persona building
 * - OpenAI completion
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

/**
 * Process chat request and generate AI response
 * 
 * @param {string} uid - User ID
 * @param {string} message - User message
 * @param {string} replyTo - Message being replied to (optional)
 * @param {boolean} isPremium - Premium status
 * 
 * @returns {Object} { reply, extractedTraits, outcomePrediction, patterns, meta }
 */
export async function processChat(uid, message, replyTo, isPremium) {
  const startTime = Date.now();

  if (!openai) {
    throw new Error("OpenAI not configured");
  }

  // Sanitize message
  const safeMessage = String(message).slice(0, 5000);

  // -----------------------------------------------------------------------
  // LOAD USER PROFILE & HISTORY
  // -----------------------------------------------------------------------
  const [userProfile, historyData] = await Promise.all([
    getUserProfile(uid),
    getConversationHistory(uid),
  ]);

  const history = historyData.messages || [];
  const conversationSummary = historyData.summary;

  console.log(
    `[${uid}] Processing - Premium: ${isPremium}, History: ${history.length}, Summary: ${!!conversationSummary}`
  );

  // -----------------------------------------------------------------------
  // INTENT DETECTION
  // -----------------------------------------------------------------------
  const intent = detectIntentType(safeMessage, history);
  const { model, temperature, maxTokens } = getChatConfig(
    intent,
    isPremium,
    userProfile
  );

  console.log(
    `[${uid}] Intent: ${intent}, Model: ${model}, Temp: ${temperature}, MaxTokens: ${maxTokens}`
  );

  // -----------------------------------------------------------------------
  // GENDER DETECTION (Hybrid)
  // -----------------------------------------------------------------------
  let detectedGender = await detectGenderSmart(safeMessage, userProfile);

  if (detectedGender !== userProfile.gender && detectedGender !== "belirsiz") {
    await updateUserGender(uid, detectedGender);
    userProfile.gender = detectedGender;
    console.log(`[${uid}] Gender detected: ${detectedGender}`);
  } else if (detectedGender === "belirsiz" && userProfile.genderAttempts < 3) {
    await incrementGenderAttempts(uid);
  }

  // -----------------------------------------------------------------------
  // DEEP TRAIT EXTRACTION
  // -----------------------------------------------------------------------
  const extractedTraits = await extractDeepTraits(safeMessage, replyTo, history);

  console.log(
    `[${uid}] Traits - Tone: ${extractedTraits.tone}, Urgency: ${extractedTraits.urgency}, Flags: R${extractedTraits.flags.red.length}/G${extractedTraits.flags.green.length}`
  );

  // -----------------------------------------------------------------------
  // PATTERN RECOGNITION (Premium only)
  // -----------------------------------------------------------------------
  const patterns = await detectUserPatterns(history, userProfile, isPremium);

  if (patterns) {
    console.log(
      `[${uid}] Patterns detected - Mistakes: ${patterns.repeatingMistakes?.length || 0}, Type: ${patterns.relationshipType}`
    );
  }

  // -----------------------------------------------------------------------
  // OUTCOME PREDICTION (Premium only)
  // -----------------------------------------------------------------------
  const outcomePrediction = await predictOutcome(safeMessage, history, isPremium);

  if (outcomePrediction) {
    console.log(
      `[${uid}] Outcome - Interest: ${outcomePrediction.interestLevel}%, Date: ${outcomePrediction.dateProbability}%`
    );
  }

  // -----------------------------------------------------------------------
  // UPDATE USER PROFILE WITH TRAITS
  // -----------------------------------------------------------------------
  const newTone = normalizeTone(extractedTraits?.tone);
  userProfile.lastTone = newTone;

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

  // Save profile updates (fire-and-forget)
  updateUserProfile(uid, userProfile).catch((e) => {
    console.error(`[${uid}] User profile save error:`, e);
  });

  // -----------------------------------------------------------------------
  // BUILD DYNAMIC PERSONA
  // -----------------------------------------------------------------------
  const persona = buildUltimatePersona(
    isPremium,
    userProfile,
    extractedTraits,
    patterns,
    conversationSummary
  );

  // -----------------------------------------------------------------------
  // REPLY CONTEXT (replyTo feature)
  // -----------------------------------------------------------------------
  const replyContext = replyTo
    ? `
🎯 ÖZEL YANIT MODU:
Kullanıcı şu mesaja yanıt veriyor: "${String(replyTo).slice(0, 400)}"

• Cevabını özellikle bu mesaja göre kurgula.
• Kullanıcının yanıtladığı mesaj ana odak olsun.
`
    : "Kullanıcı özel bir mesaja yanıt vermiyor. Normal sohbet.";

  // -----------------------------------------------------------------------
  // RICH CONTEXT (Premium extra context)
  // -----------------------------------------------------------------------
  const enrichedContext =
    isPremium && (history.length > 5 || conversationSummary)
      ? `
📊 KAPSAMLI CONTEXT:

${
  conversationSummary
    ? `UZUN VADELİ ÖZET:
${conversationSummary}`
    : ""
}

İSTATİSTİK:
• Toplam mesaj: ${userProfile.messageCount}
• Aktif history: ${history.length}
• İlişki aşaması: ${userProfile.relationshipStage}
• Attachment: ${userProfile.attachmentStyle}
• Son ton: ${userProfile.lastTone}

${
  outcomePrediction
    ? `
OUTCOME (içsel – direkt söyleme, ima et):
• İlgi: %${outcomePrediction.interestLevel}
• Buluşma: %${outcomePrediction.dateProbability}
• Prospect: ${outcomePrediction.relationshipProspect}
• Riskler: ${outcomePrediction.risks?.join(", ") || "yok"}
• Fırsatlar: ${outcomePrediction.opportunities?.join(", ") || "var"}
`
    : ""
}

${
  patterns
    ? `
PATTERN:
• Tekrarlayan hata sayısı: ${patterns.repeatingMistakes?.length || 0}
• İlişki tipi: ${patterns.relationshipType}
• Attachment: ${patterns.attachmentIndicators}
`
    : ""
}
`
      : "";

  // -----------------------------------------------------------------------
  // BUILD MESSAGES FOR OPENAI
  // -----------------------------------------------------------------------
  const systemMessages = [
    { role: "system", content: persona },
    { role: "system", content: replyContext },
  ];

  if (enrichedContext) {
    systemMessages.push({
      role: "system",
      content: enrichedContext,
    });
  }

  if (
    extractedTraits.urgency === "high" ||
    extractedTraits.urgency === "critical"
  ) {
    systemMessages.push({
      role: "system",
      content:
        "⚠️ ACİL DURUM: Daha empatik, daha net ve hızlı çözüm odaklı yanıt ver.",
    });
  }

  if (extractedTraits.needsSupport) {
    systemMessages.push({
      role: "system",
      content:
        "💙 Kullanıcı duygusal destek istiyor. Destekleyici, yargılamayan ve sakin bir tonda ol.",
    });
  }

  const recentHistory = history.slice(-10);

  const contextMessages = [
    ...systemMessages,
    ...recentHistory,
    { role: "user", content: safeMessage },
  ];

  // -----------------------------------------------------------------------
  // MAIN OPENAI COMPLETION
  // -----------------------------------------------------------------------
  let replyText = "Kanka beynim dondu, tekrar dene.";

  try {
    const completion = await openai.chat.completions.create({
      model,
      messages: contextMessages,
      temperature,
      max_tokens: maxTokens,
      presence_penalty: 0.6,
      frequency_penalty: 0.3,
    });

    replyText = completion?.choices?.[0]?.message?.content?.trim() || replyText;

    if (
      isPremium &&
      (intent === "deep" || intent === "deep_analysis") &&
      replyText.length < 150
    ) {
      console.warn(
        `[${uid}] Premium deep response unusually short: ${replyText.length} chars`
      );
    }
  } catch (e) {
    console.error("🔥 OpenAI completion error:", e);
    replyText =
      intent === "emergency"
        ? "Kanka şu an sistem yoğun ama ben buradayım. Derin nefes al, biraz sonra tekrar dene."
        : "Kanka sistem biraz yavaşladı, bir daha dener misin?";
  }

  // -----------------------------------------------------------------------
  // SAVE CONVERSATION HISTORY (async, fire-and-forget)
  // -----------------------------------------------------------------------
  saveConversationHistory(uid, safeMessage, replyText, historyData).catch(
    (e) => {
      console.error(`[${uid}] History save error:`, e);
    }
  );

  // -----------------------------------------------------------------------
  // PERFORMANCE LOG
  // -----------------------------------------------------------------------
  const processingTime = Date.now() - startTime;
  console.log(
    `[${uid}] Processing time: ${processingTime}ms, Intent: ${intent}, Model: ${model}`
  );

  // -----------------------------------------------------------------------
  // RETURN STRUCTURED RESULT
  // -----------------------------------------------------------------------
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
      hasLongTermMemory: !!conversationSummary,
      hasPatterns: !!patterns,
    },
  };
}
