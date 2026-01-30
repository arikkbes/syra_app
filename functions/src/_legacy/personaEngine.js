/**
 * ═══════════════════════════════════════════════════════════════
 * PERSONA ENGINE - MINIMAL, CHATGPT-FIRST
 * ═══════════════════════════════════════════════════════════════
 * Builds SYRA's minimal persona for natural conversation
 */

import { GENERIC_FILLER_PHRASES } from "../utils/constants.js";

/**
 * Normalize tone from extracted traits or text
 */
export function normalizeTone(t) {
  if (!t) return "neutral";
  const s = t.toLowerCase();

  if (s.includes("üzgün") || s.includes("sad") || s.includes("depressed") || s.includes("kırıl"))
    return "sad";
  if (s.includes("mutlu") || s.includes("happy") || s.includes("excited") || s.includes("heyecan"))
    return "happy";
  if (s.includes("agresif") || s.includes("angry") || s.includes("sinirli") || s.includes("öfkeli"))
    return "angry";
  if (s.includes("flört") || s.includes("flirty") || s.includes("romantic") || s.includes("aşık"))
    return "flirty";
  if (s.includes("anxious") || s.includes("kaygılı") || s.includes("endişeli") || s.includes("stresli"))
    return "anxious";
  if (s.includes("confused") || s.includes("kafası karışık") || s.includes("şaşkın"))
    return "confused";
  if (s.includes("desperate") || s.includes("umutsuz") || s.includes("çaresiz"))
    return "desperate";
  if (s.includes("hopeful") || s.includes("umutlu") || s.includes("pozitif"))
    return "hopeful";

  return "neutral";
}

/**
 * Build SYRA's ultimate persona with all context
 * @param {string} mode - Conversation mode: 'standard', 'dost_aci'
 * @param {boolean} hasActiveRelationship - Whether user has active relationship context
 * @param {boolean} isRelationshipQuery - Whether current query is relationship-related
 */
export function buildUltimatePersona(
  isPremium,
  userProfile,
  extractedTraits,
  patterns,
  conversationSummary,
  mode = 'standard',
  hasActiveRelationship = false,
  isRelationshipQuery = false
) {
  const gender = userProfile.gender || "belirsiz";
  const genderPronoun =
    gender === "erkek" ? "kardeşim" : gender === "kadın" ? "kanka" : "kanka";

  const baseTone = userProfile.lastTone || "neutral";
  const currentTone = extractedTraits?.tone
    ? normalizeTone(extractedTraits.tone)
    : baseTone;

  const toneModifier = getToneModifier(currentTone);
  const fillerPreview = GENERIC_FILLER_PHRASES.map((phrase) => `"${phrase}"`).join(", ");
  const memoryContext = conversationSummary
    ? `\n\nHAFIZA NOTU: ${conversationSummary}`
    : "";

  const shouldUseRelationshipAddOn = hasActiveRelationship && isRelationshipQuery;
  
  const corePersona = `
SEN SYRA'SIN.
1) KİMLİK: Türkçe konuşan, doğal ve akıcı bir kanka/coach; "${genderPronoun}" diye hitap et; ton: ${toneModifier}. Filler cümlelerden kaçın (örn: ${fillerPreview}).
2) ZIP/KANIT KURALI: ZIP/konuşma kanıtı iddialarını sadece gerçek veri varsa söyle; yoksa "bulamadım" de, uydurma yapma.
3) UZUNLUK: Kısa soru -> kısa yanıt; derin konu -> daha detaylı. 0-2 doğal soru sorabilirsin; zorunlu değil.${memoryContext}
`;

  const relationshipAddOn = shouldUseRelationshipAddOn
    ? "\nİLİŞKİ NOTU: Empatik ve net ol; gerekirse 1-3 somut adım öner; yargılayıcı olma."
    : "";

  return corePersona + relationshipAddOn;
}

/**
 * Get tone modifier text based on detected emotional state
 */
function getToneModifier(tone) {
  const modifiers = {
    sad: "Yumuşak, empatik, teselli edici",
    happy: "Enerjik, pozitif, destekleyici",
    angry: "Sakinleştirici, anlayışlı, yatıştırıcı",
    flirty: "Eğlenceli, nazik, rehberlik eden",
    anxious: "Güven verici, sakinleştirici, net",
    confused: "Netleştirici, açıklayıcı, yol gösterici",
    desperate: "Umut verici, destekleyici, güçlendirici",
    hopeful: "Pozitif, gerçekçi, motive edici",
    neutral: "Samimi, arkadaşça, profesyonel",
  };

  return modifiers[tone] || modifiers.neutral;
}

/**
 * Get mode-specific behavior modifier
 */
function getModeModifier(mode) {
  const modifiers = {
    standard: `
🎯 NORMAL MOD:
• Dengeli ve arkadaşça yaklaş
• Hem empatik hem pratik ol
• Orta uzunlukta, okunabilir yanıtlar ver
• Hem analiz hem çözüm sun
•`,
    dost_aci: `
💪 DOST ACI SÖYLER MODU:
• Daha direkt ve net ol
• Gerçekleri olduğu gibi söyle (ama hala empatik)
• "İşte gerçek şu:" tarzı netliği koru
• Kendi kendini kandırmaları nazikçe ama kesin şekilde kır
• Zor soruları sor: "Gerçekten bu mu istediğin?"
• Rahat ettirici yalanlar yerine rahatsız edici gerçekleri ver
• Abartılı empati değil, tough love yaklaşımı
• "Senin iyiliğin için söylüyorum" tonunu kullan
•`,
  };

  if (mode === "mentor") return modifiers.dost_aci;
  if (mode === "deep") return modifiers.standard;
  return modifiers[mode] || modifiers.standard;
}

/**
 * Detect if user message is relationship-related
 * TASK B: Strengthened detection - only strong relationship terms
 * Used to determine if relationship add-on should be activated
 */
export function isRelationshipQuery(message) {
  if (!message) return false;
  
  const msg = message.toLowerCase();
  
  // TASK B: Strong relationship-specific keywords only
  const strongRelationshipKeywords = [
    "ilişki", "sevgili", "flört", "partner", "erkek arkadaş", "kız arkadaş",
    "sevdiğim", "hoşlandığım", "aşık", "buluşma", "date", "randevu",
    "konuştuğum kişi", "görüştüğüm kişi", "çıktığım kişi", "evlili", "nişanlı",
    "red flag", "green flag", "manipül", "gaslighting", "toxic", "toksik",
    "aldatma", "aldatıyor", "ayrıl", "barış", "kavga", "kıskançlık", "kıskan",
    "attachment", "bağlanma", "kaçıngan", "kaygılı bağlanma",
    "ghosting", "ghost yaptı", "love bombing", "breadcrumbing"
  ];
  
  // Check for strong keywords
  const hasStrongKeyword = strongRelationshipKeywords.some(keyword => msg.includes(keyword));
  
  if (hasStrongKeyword) {
    return true;
  }
  
  // TASK B: Chat-related words only count if combined with relationship entity
  const chatWords = ["mesaj", "cevap", "yazmıyor", "aramıyor", "yanıt"];
  const relationshipEntities = ["o", "sevgilim", "partnerım", "erkek arkadaşım", "kız arkadaşım", "eşim"];
  
  const hasChatWord = chatWords.some(w => msg.includes(w));
  const hasRelationshipEntity = relationshipEntities.some(e => msg.includes(e));
  
  // Only return true if BOTH chat word AND relationship entity present
  if (hasChatWord && hasRelationshipEntity) {
    return true;
  }
  
  return false;
}
