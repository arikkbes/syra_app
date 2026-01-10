/**
 * ═══════════════════════════════════════════════════════════════
 * INTENT DETECTION ENGINE
 * ═══════════════════════════════════════════════════════════════
 * Detects user intent from message content and conversation history
 */

import { 
  MODEL_FREE_DEFAULT,
  MODEL_PREMIUM_DEFAULT 
} from "../utils/constants.js";

/**
 * Detect intent type from user message
 * 
 * Intent types:
 * - greeting: Simple greeting only (selam, naber, etc.) - MODULE 3.1.1
 * - message_drafting: User wants help writing a message (MODULE 3.1)
 * - context_missing: User wants something but target/relationship unclear (MODULE 3.1)
 * - technical: Programming/tech questions
 * - emergency: Urgent emotional crisis
 * - deep_analysis: Long detailed analysis requests
 * - deep_relationship_issue: Money, dependency, manipulation keywords (MODULE 3)
 * - pattern_analysis: Frequency indicators like "sürekli", "hep" (MODULE 3)
 * - deep: Relationship deep-dive
 * - short: Quick questions
 * - normal: Standard conversation
 */
export function detectIntentType(text, history = []) {
  const msg = text.toLowerCase();
  const len = msg.length;

  // MODULE 3.1.1 HOTFIX: Greeting detection
  const GREETING_ONLY = [
    "selam", "merhaba", "naber", "mrb", "hey", 
    "iyi misin", "nasılsın", "selamlar", "slm"
  ];
  
  const isGreetingOnly = GREETING_ONLY.some(g => msg.includes(g)) && len < 30;
  
  if (isGreetingOnly) {
    return "greeting";
  }

  // MODULE 3.1: Message drafting detection
  const MESSAGE_DRAFTING_TRIGGERS = [
    "ne yazayım", "ne yazsam", "mesaja ne cevap", "cevap yaz",
    "ss", "ekran görüntüsü", "screenshot", "mesaj yaz",
    "nasıl cevap", "ne desem", "yazmalı mıyım"
  ];
  
  const hasMessageDrafting = MESSAGE_DRAFTING_TRIGGERS.some(t => msg.includes(t));
  
  if (hasMessageDrafting) {
    return "message_drafting";
  }

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
  
  // MODULE 3: Deep analysis triggers
  const DEEP_ANALYSIS_TRIGGERS = {
    money_dependency: [
      "maddiyat", "para", "yemek", "geçim", "bağımlı",
      "maddi", "nafaka", "borç", "ödeme"
    ],
    frequency_indicators: [
      "sürekli", "hep", "her zaman", "hiç", "asla",
      "daima", "devamlı", "bitmek bilmez"
    ],
    manipulation_keywords: [
      "manipüle", "kontrol", "izin vermiyor", "baskı",
      "suçluyor", "tehdit", "kıskançlık", "kıskanç",
      "güven vermiyor", "özgürlük yok"
    ],
    living_situation: [
      "aynı evde değil", "yan yana değil", "uzaktayız",
      "görüşmüyoruz", "uzaktan", "farklı şehir"
    ]
  };
  
  // Check for deep relationship issue
  const hasMoneyDependency = DEEP_ANALYSIS_TRIGGERS.money_dependency.some(k => msg.includes(k));
  const hasFrequencyIndicator = DEEP_ANALYSIS_TRIGGERS.frequency_indicators.some(k => msg.includes(k));
  const hasManipulation = DEEP_ANALYSIS_TRIGGERS.manipulation_keywords.some(k => msg.includes(k));
  const hasLivingSituation = DEEP_ANALYSIS_TRIGGERS.living_situation.some(k => msg.includes(k));
  
  // Deep relationship issue: Money + Frequency OR Manipulation
  if ((hasMoneyDependency && hasFrequencyIndicator) || hasManipulation) {
    return "deep_relationship_issue";
  }
  
  // Pattern analysis: Frequency + behavior keywords
  if (hasFrequencyIndicator && (msg.includes("istiyor") || msg.includes("yapıyor"))) {
    return "pattern_analysis";
  }

  const hasContext = history.length > 3;

  if (hasCode) return "technical";
  if (hasEmergency) return "emergency";
  if (needsAnalysis && len > 200) return "deep_analysis";
  if (hasDeep || len > 600) return "deep";
  if (len < 100 && !hasDeep && !hasContext) return "short";

  // MODULE 3.1: context_missing detection
  // User wants something but it's vague
  const VAGUE_REQUEST_INDICATORS = [
    "yardım et", "ne yapayım", "ne yapmalı", "nasıl olur",
    "bi şey sor", "bir şey sor"
  ];
  
  const hasVagueRequest = VAGUE_REQUEST_INDICATORS.some(i => msg.includes(i));
  const hasNoContext = !hasDeep && history.length < 2;
  
  if (hasVagueRequest && hasNoContext) {
    return "context_missing";
  }

  return "normal";
}

/**
 * Get optimal chat configuration based on intent
 * TASK A: Conservative temperature (0.3-0.5) and tier-based model routing
 * Uses gpt-5.2 (premium) and gpt-5-mini (free)
 * 
 * Returns: { model, temperature, maxTokens }
 */
export function getChatConfig(intent, isPremium, userProfile) {
  // TASK A: Base model selection on tier
  let model = isPremium ? MODEL_PREMIUM_DEFAULT : MODEL_FREE_DEFAULT;
  
  // Conservative temperature range (0.3-0.5)
  let temperature = 0.4;
  let maxTokens = isPremium ? 1000 : 400;

  const premiumBoost = isPremium && userProfile?.messageCount > 20;
  const vipUser = isPremium && userProfile?.messageCount > 100;

  switch (intent) {
    case "technical":
      model = MODEL_PREMIUM_DEFAULT; // Use premium model for technical
      temperature = 0.35; // Very conservative for technical accuracy
      maxTokens = isPremium ? 1200 : 500;
      break;

    case "emergency":
      model = vipUser ? MODEL_PREMIUM_DEFAULT : (isPremium ? MODEL_PREMIUM_DEFAULT : MODEL_FREE_DEFAULT);
      temperature = 0.4;
      maxTokens = isPremium ? 1200 : 450;
      break;

    case "deep_analysis":
      model = isPremium ? MODEL_PREMIUM_DEFAULT : MODEL_FREE_DEFAULT;
      temperature = 0.45;
      maxTokens = isPremium ? 2000 : 500;
      break;

    case "deep":
      model = premiumBoost ? MODEL_PREMIUM_DEFAULT : (isPremium ? MODEL_PREMIUM_DEFAULT : MODEL_FREE_DEFAULT);
      temperature = 0.45;
      maxTokens = isPremium ? 1500 : 450;
      break;

    case "short":
      model = MODEL_FREE_DEFAULT; // Always use mini for short queries
      temperature = 0.35;
      maxTokens = isPremium ? 600 : 250;
      break;

    default:
      model = premiumBoost ? MODEL_PREMIUM_DEFAULT : (isPremium ? MODEL_PREMIUM_DEFAULT : MODEL_FREE_DEFAULT);
      temperature = 0.4;
      maxTokens = isPremium ? 1000 : 400;
  }

  return { model, temperature, maxTokens };
}
