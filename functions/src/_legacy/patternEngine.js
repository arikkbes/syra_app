/**
 * ═══════════════════════════════════════════════════════════════
 * PATTERN DETECTION ENGINE
 * ═══════════════════════════════════════════════════════════════
 * Detects behavioral patterns in user conversations
 * Premium-only feature
 */

import { openai } from "../config/openaiClient.js";
import { PATTERN_DETECTION_MIN_MESSAGES, MODEL_GPT4O_MINI } from "../utils/constants.js";

/**
 * Detect user behavioral patterns (Premium only)
 * 
 * Analyzes conversation history to identify:
 * - Repeating mistakes
 * - Communication patterns
 * - Relationship type
 * - Attachment indicators
 */
export async function detectUserPatterns(history, userProfile, isPremium) {
  if (!isPremium || !openai || history.length < PATTERN_DETECTION_MIN_MESSAGES) {
    return null;
  }

  try {
    const recent = history
      .slice(-20)
      .map((m) => `${m.role === "user" ? "USER" : "SYRA"}: ${m.content}`)
      .join("\n");

    const patternPrompt = `
KULLANICI SOHBET GEÇMİŞİ:
${recent}

KULLANICI PROFİLİ:
- Mesaj Sayısı: ${userProfile.messageCount}
- Cinsiyet: ${userProfile.gender}
- İlişki Aşaması: ${userProfile.relationshipStage}

Kullanıcının ilişki & iletişim PATTERN'lerini analiz et.

JSON formatında döndür:
{
  "repeatingMistakes": [],
  "communicationPatterns": [],
  "attachmentIndicators": "secure|anxious|avoidant|fearful|mixed",
  "growthAreas": [],
  "strengths": [],
  "relationshipType": "casual|serious|toxic|healthy|undefined"
}
`;

    const patternRes = await openai.chat.completions.create({
      model: MODEL_GPT4O_MINI,
      messages: [
        {
          role: "system",
          content:
            "Sen bir ilişki davranış pattern analistisin. Sadece JSON döndür.",
        },
        { role: "user", content: patternPrompt },
      ],
      temperature: 0.4,
      max_tokens: 400,
    });

    let txt = patternRes.choices[0].message.content.trim();
    txt = txt.replace(/```json\n?/g, "").replace(/```\n?/g, "").trim();

    return JSON.parse(txt);
  } catch (e) {
    console.error("Pattern detection error:", e);
    return null;
  }
}
