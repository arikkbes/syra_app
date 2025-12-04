/**
 * ═══════════════════════════════════════════════════════════════
 * OPENAI CLIENT CONFIGURATION - IMPROVED VERSION
 * ═══════════════════════════════════════════════════════════════
 * Creates and exports configured OpenAI client with better error handling
 */

import OpenAI from "openai";
import * as dotenv from "dotenv";

dotenv.config();

const openaiApiKey = process.env.OPENAI_API_KEY;

if (!openaiApiKey) {
  console.error("❌❌❌ CRITICAL ERROR: OPENAI_API_KEY not found in environment!");
  console.error("Please check:");
  console.error("1. .env file exists in functions/ directory");
  console.error("2. OPENAI_API_KEY=sk-... is defined in .env");
  console.error("3. .env is loaded correctly (dotenv.config() is working)");
  console.error("4. For Firebase Functions, set config: firebase functions:config:set openai.key='YOUR_KEY'");
} else if (!openaiApiKey.startsWith("sk-")) {
  console.error("❌ WARNING: OPENAI_API_KEY does not start with 'sk-'");
  console.error("Current key format:", openaiApiKey.slice(0, 10) + "...");
} else {
  console.log("✅ OpenAI API key found and validated");
  console.log("Key prefix:", openaiApiKey.slice(0, 10) + "...");
}

export const openai = openaiApiKey 
  ? new OpenAI({ 
      apiKey: openaiApiKey,
      timeout: 30000, // 30 second timeout
      maxRetries: 2,  // Retry failed requests twice
    }) 
  : null;


/**
 * Check if OpenAI client is available
 */
export const isOpenAIAvailable = () => {
  if (!openai) {
    console.error("OpenAI client is null - API key missing");
    return false;
  }
  return true;
};

/**
 * Test OpenAI connection (useful for debugging)
 */
export async function testOpenAIConnection() {
  if (!openai) {
    console.error("Cannot test - OpenAI client is null");
    return false;
  }

  try {
    console.log("Testing OpenAI connection...");
    const completion = await openai.chat.completions.create({
      model: "gpt-4o-mini",
      messages: [{ role: "user", content: "Hi" }],
      max_tokens: 10,
    });

    if (completion && completion.choices && completion.choices.length > 0) {
      console.log("✅ OpenAI connection test successful");
      return true;
    } else {
      console.error("❌ OpenAI returned unexpected response format");
      return false;
    }
  } catch (e) {
    console.error("❌ OpenAI connection test failed:", e.message);
    return false;
  }
}
