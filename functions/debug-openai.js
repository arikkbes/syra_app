/**
 * ═══════════════════════════════════════════════════════════════
 * DEBUG HELPER - OpenAI Connection Tester
 * ═══════════════════════════════════════════════════════════════
 * functions/ klasöründe şu komutla çalıştır:
 * node debug-openai.js
 */

import * as dotenv from "dotenv";
import OpenAI from "openai";

dotenv.config();

console.log("═══════════════════════════════════════════════════════════");
console.log("🔍 SYRA AI - OpenAI Connection Debugger");
console.log("═══════════════════════════════════════════════════════════\n");

// Check environment
console.log("1️⃣ Checking environment variables...");
const apiKey = process.env.OPENAI_API_KEY;

if (!apiKey) {
  console.error("❌ OPENAI_API_KEY not found!");
  console.error("\nPlease:");
  console.error("  1. Create a .env file in functions/ directory");
  console.error("  2. Add: OPENAI_API_KEY=sk-your-key-here");
  console.error("  3. Make sure .env is in the same directory as this script\n");
  process.exit(1);
}

console.log("✅ OPENAI_API_KEY found");
console.log(`   Format: ${apiKey.slice(0, 10)}...${apiKey.slice(-4)}`);
console.log(`   Length: ${apiKey.length} characters\n`);

if (!apiKey.startsWith("sk-")) {
  console.warn("⚠️  Warning: Key doesn't start with 'sk-' - might be invalid\n");
}

// Test OpenAI connection
console.log("2️⃣ Testing OpenAI connection...");

const client = new OpenAI({ 
  apiKey,
  timeout: 30000,
  maxRetries: 1,
});

async function testConnection() {
  try {
    console.log("   Sending test request to OpenAI...");
    
    const start = Date.now();
    
    const completion = await client.chat.completions.create({
      model: "gpt-4o-mini",
      messages: [
        { role: "system", content: "Sen yardımsever bir asistansın." },
        { role: "user", content: "Merhaba!" }
      ],
      max_tokens: 50,
      temperature: 0.7,
    });

    const elapsed = Date.now() - start;

    console.log(`✅ OpenAI connection successful! (${elapsed}ms)\n`);
    
    console.log("3️⃣ Response details:");
    console.log(`   Model: ${completion.model}`);
    console.log(`   Finish reason: ${completion.choices[0].finish_reason}`);
    console.log(`   Usage: ${completion.usage.total_tokens} tokens`);
    console.log(`   Response: "${completion.choices[0].message.content}"\n`);

    // Test with gpt-4o
    console.log("4️⃣ Testing premium model (gpt-4o)...");
    
    try {
      const start2 = Date.now();
      
      const completion2 = await client.chat.completions.create({
        model: "gpt-4o",
        messages: [{ role: "user", content: "Test" }],
        max_tokens: 10,
      });
      
      const elapsed2 = Date.now() - start2;
      console.log(`✅ GPT-4o access confirmed! (${elapsed2}ms)\n`);
    } catch (e) {
      console.warn(`⚠️  GPT-4o test failed: ${e.message}`);
      console.warn("   This might be due to API plan limits\n");
    }

    console.log("═══════════════════════════════════════════════════════════");
    console.log("✅ ALL TESTS PASSED - OpenAI is working correctly!");
    console.log("═══════════════════════════════════════════════════════════\n");

  } catch (error) {
    console.error("❌ OpenAI connection failed!\n");
    console.error("Error details:");
    console.error(`   Type: ${error.constructor.name}`);
    console.error(`   Message: ${error.message}`);
    
    if (error.code) {
      console.error(`   Code: ${error.code}`);
    }
    
    if (error.status) {
      console.error(`   Status: ${error.status}`);
    }

    if (error.response) {
      console.error(`   Response: ${JSON.stringify(error.response.data, null, 2)}`);
    }

    console.error("\nCommon solutions:");
    console.error("  1. Check if API key is valid on platform.openai.com");
    console.error("  2. Ensure you have credits/billing set up");
    console.error("  3. Check for rate limits or API downtime");
    console.error("  4. Verify network connection\n");
    
    process.exit(1);
  }
}

testConnection();
