/**
 * ═══════════════════════════════════════════════════════════════
 * TURKISH CULTURE ENGINE - MODULE 3
 * ═══════════════════════════════════════════════════════════════
 * Detects culturally-specific patterns in Turkish relationships
 * Uses micro-cultural knowledge for deeper insights
 */

/**
 * Analyze Turkish cultural context from extracted relationship info
 * @param {Object} extractedInfo - Info extracted from user message and chunks
 * @returns {Array} Array of red flags with cultural context
 */
export function analyzeTurkishCulturalContext(extractedInfo) {
  const redFlags = [];
  
  // ═══════════════════════════════════════════════════════════════
  // PATTERN 1: Remote Financial Dependency
  // ═══════════════════════════════════════════════════════════════
  if (extractedInfo.notLivingTogether && extractedInfo.frequentMoneyRequests) {
    redFlags.push({
      type: "REMOTE_FINANCIAL_DEPENDENCY",
      severity: "HIGH",
      pattern: "Aynı evde yaşamıyorlar ama sürekli maddi destek isteniyor",
      explanation: `Aynı evde yaşamadığı halde sürekli maddi destek (para, yemek, vs.) istemesi dikkat çekici. 
                    Bu genellikle iki şeyden biridir:
                    1) Gerçek ihtiyaç (nadir) 
                    2) Dependency pattern - seni maddi kaynak olarak görebiliyor (daha yaygın)
                    
                    Özellikle flört aşamasındaysa, bu davranış ilişkinin temeline zarar verebilir.`,
      culturalNote: "Türkiye'de geleneksel olarak 'geçimi sağlama' beklentisi var, ama bu manipülasyon aracı olarak da kullanılabiliyor.",
      actionable: [
        "Net sınır koy: 'Kendi ihtiyaçlarını kendin karşılaman gerekiyor'",
        "Neden bu kadar sık istediğini sor (yargılamadan)",
        "Karşılıklılık olup olmadığını değerlendir"
      ]
    });
  }
  
  // ═══════════════════════════════════════════════════════════════
  // PATTERN 2: One-Sided Caretaking
  // ═══════════════════════════════════════════════════════════════
  if (extractedInfo.frequentDailyNeedsRequests && !extractedInfo.reciprocal) {
    redFlags.push({
      type: "ONE_SIDED_CARETAKING",
      severity: "MEDIUM",
      pattern: "Tek taraflı bakım/destek ilişkisi",
      explanation: `Her ihtiyacı için sana başvurması (yemek, ulaşım, vs.) dikkat çekici. 
                    Sağlıklı ilişkide iki taraf da birbirine destek olur.
                    Tek taraflıysa, bu 'bağımlılık' veya 'rahatlık' ilişkisine işaret edebilir.`,
      culturalNote: "Türk kültüründe 'fedakarlık' övülür ama bu manipülatörler tarafından istismar edilebilir.",
      actionable: [
        "Karşılığında ne alıyorsun? Onu düşün.",
        "'Bana da destek ol' de - nasıl tepki vereceğini gör",
        "Reddetmeyi dene - direkt öfkelenirse dikkat et"
      ]
    });
  }
  
  // ═══════════════════════════════════════════════════════════════
  // PATTERN 3: Emotional Manipulation via Basic Needs
  // ═══════════════════════════════════════════════════════════════
  if (extractedInfo.guiltTrip && extractedInfo.basicNeeds) {
    redFlags.push({
      type: "EMOTIONAL_MANIPULATION_VIA_NEEDS",
      severity: "HIGH",
      pattern: "Temel ihtiyaçlar üzerinden suçluluk hissettirme",
      explanation: `"Aç kaldım senin yüzünden", "Bana bakmıyorsun" gibi cümleler manipulation.
                    Temel ihtiyaçları senin sorumluluğunmuş gibi göstererek suçluluk hissettiriyor.
                    Bu guilt trip taktiği - duygusal şantaj.`,
      culturalNote: "Türkiye'de 'sevgili = eş gibi davranmalı' beklentisi var. Bu, manipülasyon için kullanılabiliyor.",
      actionable: [
        "Bu cümleleri duydun mu? Geri adım atma.",
        "Net söyle: 'Senin ihtiyaçların senin sorumluluğun'",
        "Bu davranış devam ederse, ilişkiyi sorgula"
      ]
    });
  }
  
  // ═══════════════════════════════════════════════════════════════
  // PATTERN 4: Excessive Control Disguised as Care
  // ═══════════════════════════════════════════════════════════════
  if (extractedInfo.excessiveChecking || extractedInfo.locationTracking) {
    redFlags.push({
      type: "CONTROL_AS_CARE",
      severity: "HIGH",
      pattern: "İlgi gibi gözüken aşırı kontrol",
      explanation: `"Neredesin?", "Kiminle?", "Ne yapıyorsun?" sürekli sorulması ilgi değil, kontrol.
                    Türk kültüründe bu "merak ediyorum çünkü seviyorum" olarak normalize edilmiş.
                    Ama sağlıklı ilişkide güven vardır, sürekli kontrol değil.`,
      culturalNote: "Türkiye'de kıskançlık 'sevginin göstergesi' olarak görülür. Değildir. Güvensizliğin göstergesidir.",
      actionable: [
        "Sık sık hesap vermek zorunda kalıyor musun? Red flag.",
        "Özgürlük iste: 'Sana güveniyorum, sen de bana güven'",
        "Direkt kıskançlık/kontrol ise, sınır koy"
      ]
    });
  }
  
  // ═══════════════════════════════════════════════════════════════
  // PATTERN 5: Love Bombing + Withdrawal Cycle
  // ═══════════════════════════════════════════════════════════════
  if (extractedInfo.loveBombing && extractedInfo.suddenWithdrawal) {
    redFlags.push({
      type: "LOVE_BOMBING_CYCLE",
      severity: "CRITICAL",
      pattern: "Aşırı ilgi → Ani soğukluk döngüsü",
      explanation: `Önce aşırı ilgi, hediye, sürekli mesaj (love bombing).
                    Sonra aniden soğuk, mesaj atmıyor, kayıp (withdrawal).
                    Bu manipülasyon taktiği - seni duygusal roller coaster'a sokuyor.
                    Amacı: Seni kendine bağımlı hale getirmek.`,
      culturalNote: "Türk dizilerinde bu 'aşk-nefret' ilişkisi romantize edilir. Gerçekte toksik bir döngüdür.",
      actionable: [
        "Bu döngüyü fark et: İlgi → Soğukluk → Tekrar ilgi",
        "Döngüye girme - predictable ol sen",
        "Eğer sürekli tekrarlanıyorsa, ilişkiden çık"
      ]
    });
  }
  
  // ═══════════════════════════════════════════════════════════════
  // PATTERN 6: Silent Treatment as Punishment
  // ═══════════════════════════════════════════════════════════════
  if (extractedInfo.silentTreatment) {
    redFlags.push({
      type: "SILENT_TREATMENT",
      severity: "MEDIUM",
      pattern: "Susarak cezalandırma",
      explanation: `Tartışma sonrası gün/haftalarca konuşmama = silent treatment.
                    Bu pasif-agresif davranış, sağlıklı iletişim değil.
                    Amaç: Seni suçlu hissettirip özür diletmek.`,
      culturalNote: "Türkiye'de 'küsmek' normalleştirilmiş. Ama silent treatment manipülasyon aracıdır.",
      actionable: [
        "Bu davranışa ödül verme - peşinden koşma",
        "Sakin kal: 'Konuşmak istediğinde buradayım'",
        "Sürekli tekrarlanıyorsa, bu davranışı kabul etmediğini belirt"
      ]
    });
  }
  
  // ═══════════════════════════════════════════════════════════════
  // PATTERN 7: Triangulation (Third Party Drama)
  // ═══════════════════════════════════════════════════════════════
  if (extractedInfo.triangulation) {
    redFlags.push({
      type: "TRIANGULATION",
      severity: "HIGH",
      pattern: "Üçüncü kişi üzerinden kıskançlık/drama",
      explanation: `"Ex'im şöyle yapıyordu", "Falanca bana ilgi gösteriyor" gibi cümleler.
                    Amaç: Seni kıskandırıp daha çok çaba göstermeni sağlamak.
                    Manipulation taktiği: Triangulation.`,
      culturalNote: "Türk kültüründe 'kıskançlık = sevgi' inancı bu taktiği güçlendirir.",
      actionable: [
        "Bu tür cümlelere tepki verme",
        "Sakin kal: 'Benimle karşılaştırma yapma'",
        "Devam ederse, güvensizlik sinyali - ilişkiyi değerlendir"
      ]
    });
  }
  
  return redFlags;
}

/**
 * Extract contextual info from user message
 * @param {string} message - User's message
 * @returns {Object} Extracted context
 */
export function extractContextFromMessage(message) {
  const lower = message.toLowerCase();
  
  return {
    // Money/dependency keywords
    frequentMoneyRequests: 
      (lower.includes('sürekli') || lower.includes('hep')) && 
      (lower.includes('para') || lower.includes('yemek') || lower.includes('maddiyat')),
    
    frequentDailyNeedsRequests:
      (lower.includes('sürekli') || lower.includes('her')) &&
      (lower.includes('istiyor') || lower.includes('istiyor')),
    
    // Living situation
    notLivingTogether:
      lower.includes('aynı evde değil') || 
      lower.includes('yan yana değil') ||
      lower.includes('uzaktayız') ||
      lower.includes('görüşmüyoruz'),
    
    // Reciprocity
    reciprocal:
      lower.includes('karşılıklı') ||
      lower.includes('o da') ||
      lower.includes('ikimiz de'),
    
    // Manipulation indicators
    guiltTrip:
      lower.includes('suçluyor') ||
      lower.includes('bana bakmıyor') ||
      lower.includes('yüzünden') ||
      lower.includes('aç kaldım'),
    
    basicNeeds:
      lower.includes('yemek') ||
      lower.includes('aç') ||
      lower.includes('temel ihtiyaç'),
    
    // Control patterns
    excessiveChecking:
      (lower.includes('sürekli') || lower.includes('hep')) &&
      (lower.includes('neredesin') || lower.includes('ne yapıyorsun') || lower.includes('kiminle')),
    
    locationTracking:
      lower.includes('lokasyon') ||
      lower.includes('konum') ||
      lower.includes('nerede olduğumu bilmek'),
    
    // Love bombing / withdrawal
    loveBombing:
      lower.includes('aşırı ilgi') ||
      lower.includes('çok mesaj') ||
      lower.includes('sürekli yanımda'),
    
    suddenWithdrawal:
      lower.includes('aniden soğuk') ||
      lower.includes('kayboldu') ||
      lower.includes('mesaj atmıyor'),
    
    // Silent treatment
    silentTreatment:
      lower.includes('konuşmuyor') ||
      lower.includes('küsmüş') ||
      lower.includes('susma'),
    
    // Triangulation
    triangulation:
      lower.includes('ex') ||
      lower.includes('eski') ||
      lower.includes('başkası') ||
      lower.includes('kıskandır'),
  };
}

/**
 * Generate summary text for red flags
 * @param {Array} redFlags - Array of detected red flags
 * @returns {string} Formatted summary
 */
export function generateRedFlagSummary(redFlags) {
  if (redFlags.length === 0) {
    return null;
  }
  
  let summary = `🚩 Tespit edilen pattern'ler:\n\n`;
  
  redFlags.forEach((flag, index) => {
    summary += `${index + 1}. ${flag.type}\n`;
    summary += `   Şiddet: ${flag.severity}\n`;
    summary += `   ${flag.explanation}\n`;
    if (flag.culturalNote) {
      summary += `   💡 Kültürel not: ${flag.culturalNote}\n`;
    }
    summary += `\n`;
  });
  
  return summary;
}
