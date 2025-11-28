/**
 * ═══════════════════════════════════════════════════════════════
 * GENDER DETECTION ENGINE
 * ═══════════════════════════════════════════════════════════════
 * Hybrid gender detection using pattern matching and AI
 */

import { openai } from "../config/openaiClient.js";
import { GENDER_DETECTION_ATTEMPTS } from "../utils/constants.js";

/**
 * Detect gender from text patterns
 */
export function detectGenderFromPattern(text) {
  const msg = text.toLowerCase();

  const malePatterns = [
    /\b(kız|kızla|ona|sevgilim)\b/,
    /\b(erkek arkadaş|erkek)\b.*değil/,
    /\bbro\b/,
    /\bagam\b/,
  ];

  const femalePatterns = [
    /\b(erkek|erkekle|sevgilim|ona)\b/,
    /\b(kız arkadaş|kadın)\b.*değil/,
    /\bsis\b/,
    /\bkızım\b/,
  ];

  const maleScore = malePatterns.filter((p) => p.test(msg)).length;
  const femaleScore = femalePatterns.filter((p) => p.test(msg)).length;

  if (maleScore > femaleScore) return "erkek";
  if (femaleScore > maleScore) return "kadın";
  return "belirsiz";
}

/**
 * Smart gender detection combining patterns and AI
 * 
 * Strategy:
 * 1. Return if already detected
 * 2. Try pattern matching first
 * 3. Use AI if patterns fail and attempts remain
 */
export async function detectGenderSmart(message, userProfile) {
  // Already detected and confident
  if (userProfile.gender && userProfile.gender !== "belirsiz") {
    return userProfile.gender;
  }

  // Max attempts reached
  if (userProfile.genderAttempts >= GENDER_DETECTION_ATTEMPTS) {
    return userProfile.gender || "belirsiz";
  }

  // Try pattern matching first (fast and free)
  const patternGender = detectGenderFromPattern(message);
  if (patternGender !== "belirsiz") {
    return patternGender;
  }

  // Use AI for detection if attempts remain
  if (openai && userProfile.genderAttempts < GENDER_DETECTION_ATTEMPTS) {
    try {
      const genderRes = await openai.chat.completions.create({
        model: "gpt-4o-mini",
        messages: [
          {
            role: "system",
            content: "Sen bir gender detection uzmanısın. Sadece tek kelime döndür.",
          },
          {
            role: "user",
            content: `Mesaj: "${message.slice(0, 300)}"\n\nTek kelime: "erkek", "kadın" veya "belirsiz"`,
          },
        ],
        temperature: 0,
        max_tokens: 10,
      });

      const gender = genderRes.choices[0].message.content.trim().toLowerCase();
      if (gender === "erkek" || gender === "kadın") {
        return gender;
      }
    } catch (e) {
      console.error("AI gender detection error:", e);
    }
  }

  return "belirsiz";
}
