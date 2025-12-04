/**
 * ═══════════════════════════════════════════════════════════════
 * OUTCOME PREDICTION ENGINE
 * ═══════════════════════════════════════════════════════════════
 * Predicts relationship outcomes based on conversation analysis
 * Premium-only feature
 */

import { openai } from "../config/openaiClient.js";
import { MODEL_GPT4O_MINI } from "../utils/constants.js";

/**
 * Predict relationship outcome (Premium only)
 * 
 * Analyzes conversation history to predict:
 * - Interest level
 * - Date probability
 * - Relationship prospects
 * - Timeline and risks
 */
export async function predictOutcome(message, history, isPremium) {
  if (!isPremium || !openai || history.length < 6) {
    return null;
  }

  try {
    const recent = history
      .slice(-8)
      .map((m) => `${m.role.toUpperCase()}: ${m.content}`)
      .join("\n");

    const prompt = `
SOHBET:
${recent}

SON MESAJ: "${message}"

Aşağıdaki JSON formatında outcome prediction yap:

{
  "interestLevel": 0-100,
  "dateProbability": 0-100,
  "relationshipProspect": "very_low|low|medium|high|very_high",
  "timeline": "short_term|medium_term|long_term|uncertain",
  "risks": [],
  "opportunities": [],
  "recommendation": "string"
}
`;

    const raw = await openai.chat.completions.create({
      model: MODEL_GPT4O_MINI,
      messages: [
        { role: "system", content: "Sadece JSON döndür." },
        { role: "user", content: prompt },
      ],
      temperature: 0.4,
      max_tokens: 350,
    });

    let txt = raw.choices[0].message.content.trim();
    txt = txt.replace(/```json|```/g, "").trim();

    return JSON.parse(txt);
  } catch (e) {
    console.error("Outcome prediction error:", e);
    return null;
  }
}
