/**
 * ═══════════════════════════════════════════════════════════════
 * TRAIT EXTRACTION ENGINE
 * ═══════════════════════════════════════════════════════════════
 * Deep psychological analysis and trait extraction from messages
 */

import { openai } from "../config/openaiClient.js";

/**
 * Extract deep psychological traits from user message
 * 
 * Returns detailed analysis including:
 * - Red/green flags
 * - Emotional tone
 * - Urgency level
 * - Relationship stage
 * - Communication style
 * - Attachment indicators
 */
export async function extractDeepTraits(message, replyTo, history) {
  if (!openai) {
    return getDefaultTraits();
  }

  try {
    const hint =
      history.length > 5
        ? `Geçmiş sohbet var (${history.length} mesaj).`
        : `Yeni kullanıcı.`;

    const prompt = `
MESAJ:
"${message}"

${replyTo ? `YANITLANAN MESAJ: "${replyTo}"` : ""}

${hint}

Aşağıdaki JSON formatında analiz üret:

{
  "flags": { "red": [], "green": [] },
  "tone": "happy|sad|angry|flirty|neutral|anxious|confused|desperate|hopeful",
  "intent": "advice|vent|analysis|casual|emergency|manipulation_check",
  "urgency": "low|medium|high|critical",
  "relationshipStage": "early|dating|committed|complicated|over|none",
  "emotionalState": "stable|unstable|confused|hurt|excited|desperate|hopeful",
  "confidenceLevel": "low|medium|high",
  "needsSupport": true|false,
  "communicationStyle": "direct|passive|aggressive|passive_aggressive|healthy",
  "attachmentStyle": "secure|anxious|avoidant|fearful|unknown"
}
`;

    const raw = await openai.chat.completions.create({
      model: "gpt-4o-mini",
      messages: [
        { role: "system", content: "Sadece JSON döndür." },
        { role: "user", content: prompt },
      ],
      temperature: 0.3,
      max_tokens: 450,
    });

    let txt = raw.choices[0].message.content.trim();
    txt = txt.replace(/```json|```/g, "").trim();

    return JSON.parse(txt);
  } catch (e) {
    console.error("Trait extraction error:", e);
    return getDefaultTraits();
  }
}

/**
 * Default traits structure when extraction fails
 */
function getDefaultTraits() {
  return {
    flags: { red: [], green: [] },
    tone: "neutral",
    intent: "casual",
    urgency: "low",
    relationshipStage: "none",
    emotionalState: "stable",
    confidenceLevel: "medium",
    needsSupport: false,
    communicationStyle: "direct",
    attachmentStyle: "unknown",
  };
}
