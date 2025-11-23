import { onRequest } from "firebase-functions/v2/https";
import admin from "firebase-admin";
import OpenAI from "openai";
import * as dotenv from "dotenv";

// =============================================================================
// 🔥 SYRA AI - ULTIMATE VIRAL EDITION v12.0 FINAL (FIXED)
// =============================================================================

dotenv.config();

if (!admin.apps.length) {
  admin.initializeApp();
}
const db = admin.firestore();

const openaiApiKey = process.env.OPENAI_API_KEY;

if (!openaiApiKey) {
  console.error("❌ OPENAI_API_KEY bulunamadı!");
}

const openai = openaiApiKey ? new OpenAI({ apiKey: openaiApiKey }) : null;

// Constants
const DAILY_BACKEND_LIMIT = 150;
const MAX_HISTORY_MESSAGES = 30;
const GENDER_DETECTION_ATTEMPTS = 3;
const SUMMARY_THRESHOLD = 20;
const PATTERN_DETECTION_MIN_MESSAGES = 10;

// =============================================================================
// 🧠 ADVANCED INTENT DETECTION ENGINE
// =============================================================================
function detectIntentType(text, history = []) {
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

// =============================================================================
// 🎯 ULTRA SMART MODEL SELECTION
// =============================================================================
function getChatConfig(intent, isPremium, userProfile) {
  let model = "gpt-4o-mini";
  let temperature = 0.75;
  let maxTokens = isPremium ? 1000 : 400;

  const premiumBoost = isPremium && userProfile?.messageCount > 20;
  const vipUser = isPremium && userProfile?.messageCount > 100;

  switch (intent) {
    case "technical":
      model = "gpt-4o";
      temperature = 0.45;
      maxTokens = isPremium ? 1200 : 500;
      break;

    case "emergency":
      model = vipUser ? "gpt-4o" : "gpt-4o-mini";
      temperature = 0.7;
      maxTokens = isPremium ? 1200 : 450;
      break;

    case "deep_analysis":
      model = isPremium ? "gpt-4o" : "gpt-4o-mini";
      temperature = 0.8;
      maxTokens = isPremium ? 2000 : 500;
      break;

    case "deep":
      model = premiumBoost ? "gpt-4o" : "gpt-4o-mini";
      temperature = isPremium ? 0.85 : 0.7;
      maxTokens = isPremium ? 1500 : 450;
      break;

    case "short":
      model = "gpt-4o-mini";
      temperature = 0.65;
      maxTokens = isPremium ? 600 : 250;
      break;

    default:
      model = premiumBoost ? "gpt-4o" : "gpt-4o-mini";
      temperature = 0.75;
      maxTokens = isPremium ? 1000 : 400;
  }

  return { model, temperature, maxTokens };
}

// =============================================================================
// 🎭 ADVANCED TONE & EMOTION SYSTEM
// =============================================================================
function normalizeTone(t) {
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

// =============================================================================
// 🧬 HYBRID GENDER DETECTION
// =============================================================================
function detectGenderFromPattern(text) {
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

  const maleScore = malePatterns.filter(p => p.test(msg)).length;
  const femaleScore = femalePatterns.filter(p => p.test(msg)).length;

  if (maleScore > femaleScore) return "erkek";
  if (femaleScore > maleScore) return "kadın";
  return "belirsiz";
}

async function detectGenderSmart(message, userProfile) {
  if (userProfile.gender && userProfile.gender !== "belirsiz") {
    return userProfile.gender;
  }

  if (userProfile.genderAttempts >= GENDER_DETECTION_ATTEMPTS) {
    return userProfile.gender || "belirsiz";
  }

  const patternGender = detectGenderFromPattern(message);
  if (patternGender !== "belirsiz") {
    return patternGender;
  }

  if (userProfile.genderAttempts < GENDER_DETECTION_ATTEMPTS) {
    try {
      const genderRes = await openai.chat.completions.create({
        model: "gpt-4o-mini",
        messages: [
          { role: "system", content: "Sen bir gender detection uzmanısın. Sadece tek kelime döndür." },
          { role: "user", content: `Mesaj: "${message.slice(0, 300)}"\n\nTek kelime: "erkek", "kadın" veya "belirsiz"` }
        ],
        temperature: 0,
        max_tokens: 10
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

// =============================================================================
// 📚 CONVERSATION MEMORY SYSTEM
// =============================================================================
async function getConversationHistory(uid) {
  try {
    const historyRef = db.collection("conversation_history").doc(uid);
    const historySnap = await historyRef.get();

    if (!historySnap.exists) {
      return { messages: [], summary: null };
    }

    const data = historySnap.data();
    return {
      messages: data.messages || [],
      summary: data.summary || null,
      lastSummaryAt: data.lastSummaryAt || null
    };
  } catch (e) {
    console.error("History load error:", e);
    return { messages: [], summary: null };
  }
}
// =============================================================================
// 📚 SAVE CONVERSATION HISTORY (Transaction + Summary)
// =============================================================================
async function saveConversationHistory(uid, userMsg, botMsg, oldHistory) {
  const historyRef = db.collection("conversation_history").doc(uid);

  try {
    await db.runTransaction(async (transaction) => {
      const doc = await transaction.get(historyRef);
      let data = doc.exists ? doc.data() : { messages: [], summary: null };
      let messages = data.messages || [];
      let summary = data.summary;
      const now = Date.now();

      // Yeni mesajları ekle
      messages.push(
        { role: "user", content: userMsg, timestamp: now },
        { role: "assistant", content: botMsg, timestamp: now }
      );

      // SUMMARY MODE
      if (
        messages.length > SUMMARY_THRESHOLD &&
        (!data.lastSummaryAt ||
          messages.length - data.lastSummaryAt > SUMMARY_THRESHOLD)
      ) {
        const oldMessages = messages.slice(0, -10);

        const summaryText = await createConversationSummary(
          oldMessages,
          summary
        );

        summary = summaryText;
        messages = messages.slice(-MAX_HISTORY_MESSAGES);
        data.lastSummaryAt = messages.length;
      } else if (messages.length > MAX_HISTORY_MESSAGES) {
        messages = messages.slice(-MAX_HISTORY_MESSAGES);
      }

      transaction.set(historyRef, {
        messages,
        summary,
        lastSummaryAt: data.lastSummaryAt || 0,
        lastUpdated: now,
      });
    });
  } catch (e) {
    console.error("Transaction failed, retrying:", e);

    // Retry fallback
    try {
      await db.runTransaction(async (transaction) => {
        const doc = await transaction.get(historyRef);

        let messages = doc.exists ? doc.data().messages || [] : [];
        const now = Date.now();

        messages.push(
          { role: "user", content: userMsg, timestamp: now },
          { role: "assistant", content: botMsg, timestamp: now }
        );

        if (messages.length > MAX_HISTORY_MESSAGES) {
          messages = messages.slice(-MAX_HISTORY_MESSAGES);
        }

        transaction.set(historyRef, {
          messages,
          summary: doc.exists ? doc.data().summary : null,
          lastUpdated: now,
        });
      });
    } catch (retryError) {
      console.error("Retry also failed:", retryError);
    }
  }
}

// =============================================================================
// 📚 CREATE SUMMARY (Long-term memory booster)
// =============================================================================
async function createConversationSummary(messages, existingSummary) {
  try {
    const conversationText = messages
      .map((m) => `${m.role === "user" ? "USER" : "SYRA"}: ${m.content}`)
      .join("\n");

    const summaryPrompt = existingSummary
      ? `
MEVCUT ÖZET:
${existingSummary}

YENİ KONUŞMALAR:
${conversationText}

Bu konuşmaları mevcut özete EKLE.
Önemli detayları, pattern'leri, vibe'ı koru.
ÖZET (max 300 kelime):
`
      : `
KONUŞMA:
${conversationText}

Bu konuşmayı ÖZETLE.
Önemli detayları, ilişki vibe'ını, tavsiyeleri ve kullanıcı davranış pattern'lerini çıkar.
ÖZET (max 300 kelime):
`;

    const summaryRes = await openai.chat.completions.create({
      model: "gpt-4o-mini",
      messages: [
        {
          role: "system",
          content:
            "Sen bir konuşma özetleme uzmanısın. Kısa ve çok net özet çıkar.",
        },
        { role: "user", content: summaryPrompt },
      ],
      temperature: 0.3,
      max_tokens: 500,
    });

    return summaryRes.choices[0].message.content.trim();
  } catch (e) {
    console.error("Summary creation error:", e);
    return existingSummary || null;
  }
}

// =============================================================================
// 🧪 PATTERN RECOGNITION ENGINE
// =============================================================================
async function detectUserPatterns(history, userProfile, isPremium) {
  if (!isPremium || history.length < PATTERN_DETECTION_MIN_MESSAGES) {
    return null;
  }

  try {
    const recent = history
      .slice(-20)
      .map((m) => `${m.role === "user" ? "USER" : "SYRA"}: ${m.content}`)
      .join("\n");

    const patternPrompt = `
KULLANICI SOHBET GEÇMİŞİ:
${recent}

KULLANICI PROFİLİ:
- Mesaj Sayısı: ${userProfile.messageCount}
- Cinsiyet: ${userProfile.gender}
- İlişki Aşaması: ${userProfile.relationshipStage}

Kullanıcının ilişki & iletişim PATTERN'lerini analiz et.

JSON formatında döndür:
{
  "repeatingMistakes": [],
  "communicationPatterns": [],
  "attachmentIndicators": "secure|anxious|avoidant|fearful|mixed",
  "growthAreas": [],
  "strengths": [],
  "relationshipType": "casual|serious|toxic|healthy|undefined"
}
`;

    const patternRes = await openai.chat.completions.create({
      model: "gpt-4o-mini",
      messages: [
        {
          role: "system",
          content: "Sen bir ilişki davranış pattern analistisin. Sadece JSON döndür.",
        },
        { role: "user", content: patternPrompt },
      ],
      temperature: 0.4,
      max_tokens: 400,
    });

    let txt = patternRes.choices[0].message.content.trim();
    txt = txt.replace(/```json\n?/g, "").replace(/```\n?/g, "").trim();

    return JSON.parse(txt);
  } catch (e) {
    console.error("Pattern detection error:", e);
    return null;
  }
}
// =============================================================================
// 🎨 ULTIMATE DYNAMIC PERSONA ENGINE (FIXED – NO DUPLICATE)
// =============================================================================
function buildUltimatePersona(isPremium, userProfile, extractedTraits, patterns, conversationSummary) {
  const { gender, lastTone, relationshipStage, messageCount } = userProfile;

  // --------------------------------------------------------------------------
  // CORE PERSONA
  // --------------------------------------------------------------------------
  const corePersona = `
Sen SYRA'sın – dünyanın en zeki, en realist, en sokak-zekalı ilişki koçu AI'ısın.

KİŞİLİK:
• Kanka vibe (samimi + doğal)
• Realist & dobra
• Sokak zekalı (vibe, frame, enerji okuma)
• Psikolojik analiz uzmanı
• Viral cevap verme modu
• Gerektiğinde sert, gerektiğinde yumuşak
• Pattern'leri hatırlayan koç
• ASLA robotik değil
`;

  // --------------------------------------------------------------------------
  // GENDER PERSONALIZATION
  // --------------------------------------------------------------------------
  const genderContext =
    gender === "erkek"
      ? `
💪 Kullanıcı ERKEK
DİL: "kanka", "bro", "agam"
TON: maskülen + net
TAKTİK: frame, enerji dengesi, özgüven
`
      : gender === "kadın"
      ? `
👑 Kullanıcı KADIN
DİL: "kanka", "canım", "tatlım"
TON: empatik + destekleyici
TAKTİK: self-worth, sınır koyma, içgörü
`
      : `
🤝 Kullanıcı belirsiz
DİL: nötr + kanka vibe
`;

  // --------------------------------------------------------------------------
  // EMOTIONAL TONE CONTEXT
  // --------------------------------------------------------------------------
  const emotionalTone =
    lastTone && lastTone !== "neutral"
      ? `
DUYGUSAL DURUM: ${lastTone.toUpperCase()}
${lastTone === "sad" ? "Üzgün → daha yumuşak & empatik konuş" : ""}
${lastTone === "angry" ? "Sinirli → sakinleştir, doğrula ama körükleme" : ""}
${lastTone === "anxious" ? "Kaygılı → yatıştır, somut adımlar ver" : ""}
${lastTone === "flirty" ? "Flörtöz → vibe’a gir, ama aşırıya kaçma" : ""}
${lastTone === "desperate" ? "Çaresiz → desteği arttır, çözüm ver" : ""}
${lastTone === "happy" ? "Mutlu → enerjiyi devam ettir" : ""}
`
      : "";

  // --------------------------------------------------------------------------
  // RELATIONSHIP STAGE CONTEXT
  // --------------------------------------------------------------------------
  const stageContext =
    relationshipStage && relationshipStage !== "none"
      ? `
İLİŞKİ AŞAMASI: ${relationshipStage}
${relationshipStage === "early" ? "Yeni tanışma → vibe + mystery" : ""}
${relationshipStage === "dating" ? "Dating → enerji dengesi + uyum testi" : ""}
${relationshipStage === "committed" ? "İlişki → iletişim + trust + derinlik" : ""}
${relationshipStage === "complicated" ? "Karışık → red flag analizi + net tavsiye" : ""}
${relationshipStage === "over" ? "Bitti → closure + recovery + growth" : ""}
`
      : "";

  // --------------------------------------------------------------------------
  // EXPERIENCE CONTEXT BASED ON MESSAGE COUNT
  // --------------------------------------------------------------------------
  const experienceContext =
    messageCount > 100
      ? `
🧠 VIP Kullanıcı (${messageCount}+ mesaj)
→ Bu kullanıcı seni uzun süredir kullanıyor.
→ Pattern'lerini BİL ve referans ver.
→ Daha samimi + rahat konuşabilirsin.
`
      : messageCount > 30
      ? `
📊 Düzenli Kullanıcı
→ Artık bu kullanıcıyı tanıyorsun.
→ Tavsiyelerde tutarlılık şart.
`
      : messageCount > 5
      ? `
📝 Yeni Kullanıcı
→ İlk izlenim hala kritik.
`
      : `
🆕 İlk Mesajlar
→ Değer ver, hızlı güven kur.
`;

  // --------------------------------------------------------------------------
  // PATTERN CONTEXT
  // --------------------------------------------------------------------------
  const patternContext = patterns
    ? `
PATTERN ANALİZİ:
Tekrarlayan hatalar: ${patterns.repeatingMistakes?.join(", ") || "yok"}
İletişim biçimi: ${patterns.communicationPatterns?.join(", ") || "belirsiz"}
Attachment: ${patterns.attachmentIndicators || "belirsiz"}

${patterns.repeatingMistakes?.length > 0 ? 
`⚠️ Bu kullanıcı aynı hatayı sık tekrarlıyor → cevabında bunu imalı şekilde belirt.` 
: ""}
`
    : "";

  // --------------------------------------------------------------------------
  // LONG-TERM MEMORY CONTEXT
  // --------------------------------------------------------------------------
  const summaryContext = conversationSummary
    ? `
📚 UZUN VADELİ HAFIZA:
${conversationSummary}

→ Gerektikçe geçmiş konuşmalara referans ver.
`
    : "";

  // --------------------------------------------------------------------------
  // PREMIUM MODE
  // --------------------------------------------------------------------------
  const tierContext = isPremium
    ? `
✨ PREMIUM KULLANICI:
→ Uzun, derin, psikolojik analiz serbest.
→ Attachment + energy + behavior breakdown yap.
→ Red flag / green flag analizine izin var.
→ Mini terapi vibe → ama sokak zekalı.
→ Outcome Prediction bilgisini cevaba YEDİR.
→ SS’lik cevap ver.
`
    : `
🆓 FREE KULLANICI:
→ 2-3 cümle kısa, net, teaser.
→ Detay verme, premium’a yönlendir.
`;

  return (
    corePersona +
    genderContext +
    emotionalTone +
    stageContext +
    experienceContext +
    patternContext +
    summaryContext +
    tierContext
  );
}

// =============================================================================
// 🧪 ULTRA DEEP TRAIT EXTRACTION ENGINE
// =============================================================================
async function extractDeepTraits(message, replyTo, history) {
  try {
    const hint =
      history.length > 5
        ? `Geçmiş sohbet var (${history.length} mesaj).`
        : `Yeni kullanıcı.`;

    const prompt = `
MESAJ:
"${message}"

${replyTo ? `YANITLANAN MESAJ: "${replyTo}"` : ""}

${hint}

Aşağıdaki JSON formatında analiz üret:

{
  "flags": { "red": [], "green": [] },
  "tone": "happy|sad|angry|flirty|neutral|anxious|confused|desperate|hopeful",
  "intent": "advice|vent|analysis|casual|emergency|manipulation_check",
  "urgency": "low|medium|high|critical",
  "relationshipStage": "early|dating|committed|complicated|over|none",
  "emotionalState": "stable|unstable|confused|hurt|excited|desperate|hopeful",
  "confidenceLevel": "low|medium|high",
  "needsSupport": true|false,
  "communicationStyle": "direct|passive|aggressive|passive_aggressive|healthy",
  "attachmentStyle": "secure|anxious|avoidant|fearful|unknown"
}
`;

    const raw = await openai.chat.completions.create({
      model: "gpt-4o-mini",
      messages: [
        { role: "system", content: "Sadece JSON döndür." },
        { role: "user", content: prompt },
      ],
      temperature: 0.3,
      max_tokens: 450,
    });

    let txt = raw.choices[0].message.content.trim();
    txt = txt.replace(/```json|```/g, "").trim();

    return JSON.parse(txt);
  } catch (e) {
    console.error("Trait extraction error:", e);
    return {
      flags: { red: [], green: [] },
      tone: "neutral",
      intent: "casual",
      urgency: "low",
      relationshipStage: "none",
      emotionalState: "stable",
      confidenceLevel: "medium",
      needsSupport: false,
      communicationStyle: "direct",
      attachmentStyle: "unknown",
    };
  }
}

// =============================================================================
// 🎯 OUTCOME PREDICTION ENGINE (Premium only)
// =============================================================================
async function predictOutcome(message, history, isPremium) {
  if (!isPremium || history.length < 6) return null;

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
      model: "gpt-4o-mini",
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
// =============================================================================
// 🚀 MAIN ULTRA CHAT HANDLER
// =============================================================================
export const flortIQChat = onRequest(
  { cors: true, timeoutSeconds: 120 }, // Uzun processing için timeout artırıldı
  async (req, res) => {
    // -------------------------------------------------------------------------
    // CORS & METHOD CHECK
    // -------------------------------------------------------------------------
    if (req.method === "OPTIONS") {
      res.set("Access-Control-Allow-Origin", "*");
      res.set("Access-Control-Allow-Headers", "Content-Type");
      res.set("Access-Control-Allow-Methods", "POST, OPTIONS");
      return res.status(204).send("");
    }

    if (req.method !== "POST") {
      return res.status(405).json({ error: "Sadece POST kabul edilir." });
    }

    if (!openai) {
      return res.status(500).json({
        error: "OpenAI yapılandırması eksik.",
      });
    }

    const startTime = Date.now();

    try {
      const { message, uid, replyTo } = req.body || {};

      // -----------------------------------------------------------------------
      // 🛡️ VALIDATION & BASIC FILTER
      // -----------------------------------------------------------------------
      if (!uid) {
        return res.status(400).json({ error: "UID eksik." });
      }

      if (!message || !message.trim()) {
        return res.status(400).json({ error: "Mesaj boş." });
      }

      let safeMessage = message.trim().replace(/\s+/g, " ");

      if (safeMessage.length < 2) {
        return res.status(200).json({
          reply: "Kanka biraz daha açar mısın? Ne demek istediğini anlamadım.",
          extractedTraits: {
            flags: { red: [], green: [] },
            tone: "neutral",
            intent: "casual",
            urgency: "low",
          },
        });
      }

      const isGibberish = /^[a-z]{1,3}$|^(.)\1{5,}$/i.test(safeMessage);
      if (isGibberish) {
        return res.status(200).json({
          reply: "Hmm, anlamadım kanka. Düzgün bir şeyler yaz bakalım :)",
          extractedTraits: {
            flags: { red: [], green: [] },
            tone: "neutral",
            intent: "casual",
            urgency: "low",
          },
        });
      }

      if (safeMessage.length > 3000) {
        safeMessage = safeMessage.slice(0, 3000);
      }

      // -----------------------------------------------------------------------
      // 👤 USER PROFILE LOAD & DAILY LIMIT
      // -----------------------------------------------------------------------
      const userRef = db.collection("users").doc(uid);
      const snap = await userRef.get();

      const now = Date.now();
      const today = new Date();
      today.setHours(0, 0, 0, 0);
      const todayTS = today.getTime();

      let userProfile = snap.data() || {
        createdAt: now,
        premium: false,
        dailyCount: 0,
        lastReset: todayTS,
        lastTone: "neutral",
        gender: "belirsiz",
        genderAttempts: 0,
        messageCount: 0,
        relationshipStage: "none",
        lastActive: now,
        attachmentStyle: "unknown",
        totalAdviceGiven: 0,
      };

      // günlük reset
      if (!userProfile.lastReset || userProfile.lastReset < todayTS) {
        userProfile.dailyCount = 0;
        userProfile.lastReset = todayTS;
      }

      const isPremium = !!userProfile.premium;

      // backend rate limit (günlük)
      if (userProfile.dailyCount >= DAILY_BACKEND_LIMIT) {
        return res.status(429).json({
          error: "Backend limit aşıldı.",
          message: "Kanka bugünlük limitin doldu. Yarın tekrar gel veya premium'a geç! 🔥",
        });
      }

      userProfile.dailyCount += 1;
      userProfile.messageCount = (userProfile.messageCount || 0) + 1;
      userProfile.lastActive = now;

      // -----------------------------------------------------------------------
      // 👤 SMART GENDER DETECTION
      // -----------------------------------------------------------------------
      const detectedGender = await detectGenderSmart(safeMessage, userProfile);

      if (detectedGender !== userProfile.gender) {
        userProfile.gender = detectedGender;
      }

      if (
        userProfile.gender === "belirsiz" &&
        (userProfile.genderAttempts || 0) < GENDER_DETECTION_ATTEMPTS
      ) {
        userProfile.genderAttempts = (userProfile.genderAttempts || 0) + 1;
      }

      // -----------------------------------------------------------------------
      // 📚 CONVERSATION HISTORY LOAD
      // -----------------------------------------------------------------------
      const historyData = await getConversationHistory(uid);
      const history = historyData.messages || [];
      const conversationSummary = historyData.summary || null;

      // -----------------------------------------------------------------------
      // 🎯 INTENT DETECTION & MODEL SELECTION
      // -----------------------------------------------------------------------
      const intent = detectIntentType(safeMessage, history);
      const { model, temperature, maxTokens } = getChatConfig(
        intent,
        isPremium,
        userProfile
      );

      console.log(
        `[${uid}] Intent: ${intent}, Model: ${model}, Tokens: ${maxTokens}, Premium: ${isPremium}, MsgCount: ${userProfile.messageCount}`
      );

      // -----------------------------------------------------------------------
      // 🧪 DEEP TRAIT EXTRACTION
      // -----------------------------------------------------------------------
      const extractedTraits = await extractDeepTraits(
        safeMessage,
        replyTo,
        history
      );

      // -----------------------------------------------------------------------
      // 🔍 PATTERN RECOGNITION (Premium only)
      // -----------------------------------------------------------------------
      const patterns = await detectUserPatterns(
        history,
        userProfile,
        isPremium
      );

      // -----------------------------------------------------------------------
      // 🎯 OUTCOME PREDICTION (Premium only)
      // -----------------------------------------------------------------------
      const outcomePrediction = await predictOutcome(
        safeMessage,
        history,
        isPremium
      );

      // -----------------------------------------------------------------------
      // 💾 UPDATE USER PROFILE WITH TRAITS
      // -----------------------------------------------------------------------
      const newTone = normalizeTone(extractedTraits?.tone);
      userProfile.lastTone = newTone;

      if (
        extractedTraits.relationshipStage &&
        extractedTraits.relationshipStage !== "none"
      ) {
        userProfile.relationshipStage = extractedTraits.relationshipStage;
      }

      if (
        extractedTraits.attachmentStyle &&
        extractedTraits.attachmentStyle !== "unknown"
      ) {
        userProfile.attachmentStyle = extractedTraits.attachmentStyle;
      }

      userProfile.totalAdviceGiven = (userProfile.totalAdviceGiven || 0) + 1;

      userRef.set(userProfile, { merge: true }).catch((e) => {
        console.error("User profile save error:", e);
      });

      // -----------------------------------------------------------------------
      // 🎨 BUILD DYNAMIC PERSONA
      // -----------------------------------------------------------------------
      const persona = buildUltimatePersona(
        isPremium,
        userProfile,
        extractedTraits,
        patterns,
        conversationSummary
      );

      // -----------------------------------------------------------------------
      // 🔗 REPLY CONTEXT (replyTo özelliği)
      // -----------------------------------------------------------------------
      const replyContext = replyTo
        ? `
🎯 ÖZEL YANIT MODU:
Kullanıcı şu mesaja yanıt veriyor: "${String(replyTo).slice(0, 400)}"

• Cevabını özellikle bu mesaja göre kurgula.
• Kullanıcının yanıtladığı mesaj ana odak olsun.
`
        : "Kullanıcı özel bir mesaja yanıt vermiyor. Normal sohbet.";

      // -----------------------------------------------------------------------
      // 📊 RICH CONTEXT (Premium extra context)
      // -----------------------------------------------------------------------
      const enrichedContext =
        isPremium && (history.length > 5 || conversationSummary)
          ? `
📊 KAPSAMLI CONTEXT:

${
  conversationSummary
    ? `UZUN VADELİ ÖZET:
${conversationSummary}`
    : ""
}

İSTATİSTİK:
• Toplam mesaj: ${userProfile.messageCount}
• Aktif history: ${history.length}
• İlişki aşaması: ${userProfile.relationshipStage}
• Attachment: ${userProfile.attachmentStyle}
• Son ton: ${userProfile.lastTone}

${
  outcomePrediction
    ? `
OUTCOME (içsel – direkt söyleme, ima et):
• İlgi: %${outcomePrediction.interestLevel}
• Buluşma: %${outcomePrediction.dateProbability}
• Prospect: ${outcomePrediction.relationshipProspect}
• Riskler: ${outcomePrediction.risks?.join(", ") || "yok"}
• Fırsatlar: ${outcomePrediction.opportunities?.join(", ") || "var"}
`
    : ""
}

${
  patterns
    ? `
PATTERN:
• Tekrarlayan hata sayısı: ${
        patterns.repeatingMistakes?.length || 0
      }
• İlişki tipi: ${patterns.relationshipType}
• Attachment: ${patterns.attachmentIndicators}
`
    : ""
}
`
          : "";

      // -----------------------------------------------------------------------
      // 💬 BUILD MESSAGES FOR OPENAI
      // -----------------------------------------------------------------------
      const systemMessages = [
        { role: "system", content: persona },
        { role: "system", content: replyContext },
      ];

      if (enrichedContext) {
        systemMessages.push({
          role: "system",
          content: enrichedContext,
        });
      }

      if (
        extractedTraits.urgency === "high" ||
        extractedTraits.urgency === "critical"
      ) {
        systemMessages.push({
          role: "system",
          content:
            "⚠️ ACİL DURUM: Daha empatik, daha net ve hızlı çözüm odaklı yanıt ver.",
        });
      }

      if (extractedTraits.needsSupport) {
        systemMessages.push({
          role: "system",
          content:
            "💙 Kullanıcı duygusal destek istiyor. Destekleyici, yargılamayan ve sakin bir tonda ol.",
        });
      }

      const recentHistory = history.slice(-10);

      const contextMessages = [
        ...systemMessages,
        ...recentHistory,
        { role: "user", content: safeMessage },
      ];

      // -----------------------------------------------------------------------
      // 🤖 MAIN OPENAI COMPLETION
      // -----------------------------------------------------------------------
      let replyText = "Kanka beynim dondu, tekrar dene.";

      try {
        const completion = await openai.chat.completions.create({
          model,
          messages: contextMessages,
          temperature,
          max_tokens: maxTokens,
          presence_penalty: 0.6,
          frequency_penalty: 0.3,
        });

        replyText =
          completion?.choices?.[0]?.message?.content?.trim() || replyText;

        if (
          isPremium &&
          (intent === "deep" || intent === "deep_analysis") &&
          replyText.length < 150
        ) {
          console.warn(
            `[${uid}] Premium deep response unusually short: ${replyText.length} chars`
          );
        }
      } catch (e) {
        console.error("🔥 OpenAI completion error:", e);
        replyText =
          intent === "emergency"
            ? "Kanka şu an sistem yoğun ama ben buradayım. Derin nefes al, biraz sonra tekrar dene."
            : "Kanka sistem biraz yavaşladı, bir daha dener misin?";
      }

      // -----------------------------------------------------------------------
      // 📚 SAVE CONVERSATION HISTORY (async, fire-and-forget)
      // -----------------------------------------------------------------------
      saveConversationHistory(uid, safeMessage, replyText, historyData).catch(
        (e) => {
          console.error("History save error:", e);
        }
      );

      // -----------------------------------------------------------------------
      // 📊 PERFORMANCE LOG
      // -----------------------------------------------------------------------
      const processingTime = Date.now() - startTime;
      console.log(
        `[${uid}] Processing time: ${processingTime}ms, Intent: ${intent}, Model: ${model}`
      );

      // -----------------------------------------------------------------------
      // ✅ FINAL RESPONSE
      // -----------------------------------------------------------------------
      return res.status(200).json({
        reply: replyText,
        extractedTraits,
        outcomePrediction: isPremium ? outcomePrediction : undefined,
        patterns: isPremium ? patterns : undefined,
        meta: {
          intent,
          model,
          premium: isPremium,
          messageCount: userProfile.messageCount,
          processingTime,
          hasLongTermMemory: !!conversationSummary,
          hasPatterns: !!patterns,
        },
      });
    } catch (e) {
      console.error("🔥 CRITICAL ERROR:", e);
      return res.status(500).json({
        error: "Sunucu hatası.",
        message: "Kanka bir sorun oluştu. Tekrar dener misin?",
        details:
          process.env.NODE_ENV === "development"
            ? String(e).slice(0, 300)
            : undefined,
      });
    }
  }
);
