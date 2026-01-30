/**
 * OPENAI CLIENT CONFIGURATION (Functions v2 Secrets uyumlu)
 */

import OpenAI from "openai";

// ✅ Öncelik: Secret env, sonra fallback (yerelde test için)
const openaiApiKey =
  process.env.OPENAI_API_KEY_SECRET ||
  process.env.OPENAI_API_KEY ||
  "";

export const openai = openaiApiKey
  ? new OpenAI({
      apiKey: openaiApiKey,
      timeout: 30000,
      maxRetries: 2,
    })
  : null;

export const isOpenAIAvailable = () => !!openai;

export function requireOpenAI() {
  if (!openai) {
    throw new Error(
      "OpenAI not configured: OPENAI_API_KEY_SECRET is missing (Firebase Functions secret)."
    );
  }
  return openai;
}
