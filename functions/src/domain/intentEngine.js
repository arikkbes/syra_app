/**
 * ═══════════════════════════════════════════════════════════════
 * INTENT DETECTION ENGINE
 * ═══════════════════════════════════════════════════════════════
 * Detects user intent from message content and conversation history
 */

import { MODEL_GPT4O, MODEL_GPT4O_MINI } from "../utils/constants.js";

/**
 * Detect intent type from user message
 * 
 * Intent types:
 * - technical: Programming/tech questions
 * - emergency: Urgent emotional crisis
 * - deep_analysis: Long detailed analysis requests
 * - deep: Relationship deep-dive
 * - short: Quick questions
 * - normal: Standard conversation
 */
export function detectIntentType(text, history = []) {
  const msg = text.toLowerCase();
  const len = msg.length;

  const hasCode =
    msg.includes("http") ||
    msg.includes("flutter") ||
    msg.includes("dart") ||
    msg.includes("firebase") ||
    msg.includes("kod") ||
    msg.includes("{") ||
    msg.includes("}");

  const hasDeep =
    msg.includes("ilişki") ||
    msg.includes("sevgilim") ||
    msg.includes("flört") ||
    msg.includes("kavga") ||
    msg.includes("ayrıl") ||
    msg.includes("manipül") ||
    msg.includes("aldatma") ||
    msg.includes("toksik") ||
    msg.includes("red flag") ||
    msg.includes("green flag");

  const hasEmergency =
    msg.includes("çok kötüyüm") ||
    msg.includes("dayanamıyorum") ||
    msg.includes("bıktım") ||
    msg.includes("ne yapacağımı bilmiyorum") ||
    msg.includes("yardım et");

  const needsAnalysis =
    msg.includes("analiz") ||
    msg.includes("ne düşünüyorsun") ||
    msg.includes("yorumla") ||
    msg.includes("incele");

  const hasContext = history.length > 3;

  if (hasCode) return "technical";
  if (hasEmergency) return "emergency";
  if (needsAnalysis && len > 200) return "deep_analysis";
  if (hasDeep || len > 600) return "deep";
  if (len < 100 && !hasDeep && !hasContext) return "short";

  return "normal";
}

/**
 * Get optimal chat configuration based on intent
 * 
 * Returns: { model, temperature, maxTokens }
 */
export function getChatConfig(intent, isPremium, userProfile) {
  let model = MODEL_GPT4O_MINI;
  let temperature = 0.75;
  let maxTokens = isPremium ? 1000 : 400;

  const premiumBoost = isPremium && userProfile?.messageCount > 20;
  const vipUser = isPremium && userProfile?.messageCount > 100;

  switch (intent) {
    case "technical":
      model = MODEL_GPT4O;
      temperature = 0.45;
      maxTokens = isPremium ? 1200 : 500;
      break;

    case "emergency":
      model = vipUser ? MODEL_GPT4O : MODEL_GPT4O_MINI;
      temperature = 0.7;
      maxTokens = isPremium ? 1200 : 450;
      break;

    case "deep_analysis":
      model = isPremium ? MODEL_GPT4O : MODEL_GPT4O_MINI;
      temperature = 0.8;
      maxTokens = isPremium ? 2000 : 500;
      break;

    case "deep":
      model = premiumBoost ? MODEL_GPT4O : MODEL_GPT4O_MINI;
      temperature = isPremium ? 0.85 : 0.7;
      maxTokens = isPremium ? 1500 : 450;
      break;

    case "short":
      model = MODEL_GPT4O_MINI;
      temperature = 0.65;
      maxTokens = isPremium ? 600 : 250;
      break;

    default:
      model = premiumBoost ? MODEL_GPT4O : MODEL_GPT4O_MINI;
      temperature = 0.75;
      maxTokens = isPremium ? 1000 : 400;
  }

  return { model, temperature, maxTokens };
}
