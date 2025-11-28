/**
 * ═══════════════════════════════════════════════════════════════
 * OPENAI CLIENT CONFIGURATION
 * ═══════════════════════════════════════════════════════════════
 * Creates and exports configured OpenAI client
 */

import OpenAI from "openai";
import * as dotenv from "dotenv";

dotenv.config();

const openaiApiKey = process.env.OPENAI_API_KEY;

if (!openaiApiKey) {
  console.error("❌ OPENAI_API_KEY bulunamadı!");
}

// Create and export OpenAI client
export const openai = openaiApiKey ? new OpenAI({ apiKey: openaiApiKey }) : null;

// Check if OpenAI is available
export const isOpenAIAvailable = () => openai !== null;
