/**
 * ═══════════════════════════════════════════════════════════════
 * RELATIONSHIP RETRIEVAL SERVICE
 * ═══════════════════════════════════════════════════════════════
 * Handles context injection and on-demand chunk retrieval for chat
 * 
 * Used by chatOrchestrator to:
 * 1. Always inject master summary as context
 * 2. Detect when user needs specific retrieval (date, quote, reference)
 * 3. Fetch relevant chunks and generate excerpts
 * ═══════════════════════════════════════════════════════════════
 */

import { db as firestore } from "../config/firebaseAdmin.js";
import { getChunkFromStorage, searchChunks } from "./relationshipPipeline.js";
import { openai } from "../config/openaiClient.js";

/**
 * Get relationship context for chat
 * Returns master summary (always) + retrieval results (if needed)
 */
export async function getRelationshipContext(uid, userMessage, conversationHistory = []) {
  try {
    // Get user's active relationship
    const userDoc = await firestore.collection("users").doc(uid).get();
    const activeRelationshipId = userDoc.data()?.activeRelationshipId;
    
    if (!activeRelationshipId) {
      return null;
    }
    
    // Get relationship master document
    const relationshipRef = firestore
      .collection("relationships")
      .doc(uid)
      .collection("relations")
      .doc(activeRelationshipId);
    
    const relationshipDoc = await relationshipRef.get();
    
    if (!relationshipDoc.exists) {
      return null;
    }
    
    const relationship = relationshipDoc.data();
    
    // Check if relationship is active
    if (relationship.isActive === false) {
      console.log(`[${uid}:${activeRelationshipId}] Relationship exists but isActive=false, skipping context`);
      return null;
    }
    
    // Build base context from master summary
    let context = buildMasterContext(relationship);
    
    // Check if user message needs retrieval
    const needsRetrieval = detectRetrievalNeed(userMessage, conversationHistory);
    
    // ═══════════════════════════════════════════════════════════════
    // TASK A: Debug logging (1/6)
    // ═══════════════════════════════════════════════════════════════
    console.log(`[${uid}:${activeRelationshipId}] detectRetrievalNeed result:`, {
      needed: needsRetrieval.needed,
      reason: needsRetrieval.reason,
      query: needsRetrieval.query,
      parsedDate: needsRetrieval.parsedDate ? {
        displayText: needsRetrieval.parsedDate.displayText,
        startISO: needsRetrieval.parsedDate.startISO,
        endISO: needsRetrieval.parsedDate.endISO,
      } : null,
      confidence: needsRetrieval.confidence,
    });
    
    if (needsRetrieval.needed) {
      console.log(`[${uid}:${activeRelationshipId}] Retrieval triggered: ${needsRetrieval.reason}`);
      
      // Search for relevant chunks
      const relevantChunks = await searchChunks(
        uid, 
        activeRelationshipId, 
        needsRetrieval.query,
        needsRetrieval.dateHint // TASK B: pass dateHint to searchChunks
      );
      
      // ═══════════════════════════════════════════════════════════════
      // TASK A: Debug logging (2/6)
      // ═══════════════════════════════════════════════════════════════
      console.log(`[${uid}:${activeRelationshipId}] searchChunks result:`, {
        relevantChunksLength: relevantChunks.length,
        top3: relevantChunks.slice(0, 3).map(c => ({
          chunkId: c.chunkId,
          dateRange: c.dateRange,
          startDate: c.startDate,
          endDate: c.endDate,
          score: c.score,
        })),
      });
      
      if (relevantChunks.length > 0) {
        // Fetch raw content from best matching chunk
        const bestChunk = relevantChunks[0];
        
        // ═══════════════════════════════════════════════════════════════
        // TASK A: Debug logging (3/6) - Before storage download
        // ═══════════════════════════════════════════════════════════════
        console.log(`[${uid}:${activeRelationshipId}] Downloading chunk:`, {
          storagePath: bestChunk.storagePath,
        });
        
        const rawContent = await getChunkFromStorage(bestChunk.storagePath);
        
        // ═══════════════════════════════════════════════════════════════
        // TASK A: Debug logging (4/6) - After storage download
        // ═══════════════════════════════════════════════════════════════
        console.log(`[${uid}:${activeRelationshipId}] Storage download result:`, {
          storagePath: bestChunk.storagePath,
          downloadedBytes: rawContent ? rawContent.length : 0,
          success: !!rawContent,
        });
        
        if (rawContent) {
          // Generate focused excerpt based on user's question
          const excerpt = await generateExcerpt(
            rawContent, 
            userMessage, 
            needsRetrieval.query
          );
          
          // ═══════════════════════════════════════════════════════════════
          // TASK A: Debug logging (5/6) - After excerpt generation
          // ═══════════════════════════════════════════════════════════════
          console.log(`[${uid}:${activeRelationshipId}] Excerpt generated:`, {
            excerptChars: excerpt ? excerpt.length : 0,
          });
          
          // TASK E: Quote safety - only quote if excerpt exists
          if (excerpt) {
            context += `\n\n📎 ALAKALI SOHBET KESİTİ (${bestChunk.dateRange}):\n${excerpt}`;
            context += `\n\n⚠️ ALINTI KURALI: SADECE yukarıdaki kesitte geçen kesin ifadeleri kullan. Kesitte olmayan hiçbir şey söyleme veya uydurma. Max 2 kısa alıntı yap.`;
          }
        } else {
          // ═══════════════════════════════════════════════════════════════
          // TASK A: Debug logging (6/6) - Storage error
          // ═══════════════════════════════════════════════════════════════
          console.error(`[${uid}:${activeRelationshipId}] Storage error: Failed to download chunk from ${bestChunk.storagePath}`);
        }
      } else {
        // ═══════════════════════════════════════════════════════════════
        // TASK D: Disambiguation + Fallback (relevantChunks = 0)
        // ═══════════════════════════════════════════════════════════════
        console.log(`[${uid}:${activeRelationshipId}] Fallback: relevantChunks=0, using masterSummary`);
        context += `\n\n⚠️ Kullanıcının sorduğu spesifik konu/tarih için kayıtlarda eşleşme bulunamadı.`;
        context += `\n\n📌 Kullanıcıya kibarca söyle ve şunu sor: "Hangi dönemden bahsediyorsun? (son 1 ay / 3 ay / daha eski) ya da spesifik ay-yıl söyleyebilir misin (örn: Mayıs 2025)?"`;
      }
      
      // ═══════════════════════════════════════════════════════════════
      // TASK A: Final logging before LLM call
      // ═══════════════════════════════════════════════════════════════
      const includedExcerpt = relevantChunks.length > 0 && context.includes("📎 ALAKALI SOHBET KESİTİ");
      const finalContextChars = context.length;
      
      console.log(`[${uid}:${activeRelationshipId}] Final context stats:`, {
        includedExcerpt,
        finalContextChars,
        masterSummaryChars: context.split("📎 ALAKALI SOHBET")[0].length,
      });
    }
    
    return {
      context,
      relationshipId: activeRelationshipId,
      speakers: relationship.speakers,
      hasRetrieval: needsRetrieval.needed,
    };
    
  } catch (e) {
    console.error(`[${uid}] getRelationshipContext error:`, e);
    // TASK A: Error logging
    console.error(`[${uid}] Error stack:`, e.stack);
    return null;
  }
}

/**
 * Build context string from master summary
 */
function buildMasterContext(relationship) {
  const ms = relationship.masterSummary || {};
  const speakers = relationship.speakers || [];
  
  let context = `📱 İLİŞKİ HAFIZASI\n`;
  context += `Konuşmacılar: ${speakers.join(" & ")}\n`;
  context += `Toplam mesaj: ${relationship.totalMessages || "?"}\n`;
  
  if (ms.shortSummary) {
    context += `\n📋 ÖZET:\n${ms.shortSummary}\n`;
  }
  
  // Personalities
  if (ms.personalities) {
    context += `\n👤 KİŞİLİKLER:\n`;
    for (const [name, data] of Object.entries(ms.personalities)) {
      if (data.traits?.length) {
        context += `• ${name}: ${data.traits.join(", ")}\n`;
      }
      if (data.communicationStyle) {
        context += `  İletişim: ${data.communicationStyle}\n`;
      }
    }
  }
  
  // Dynamics
  if (ms.dynamics) {
    context += `\n💫 DİNAMİKLER:\n`;
    if (ms.dynamics.conflictStyle) {
      context += `• Tartışma tarzı: ${ms.dynamics.conflictStyle}\n`;
    }
    if (ms.dynamics.loveLanguages?.length) {
      context += `• Sevgi dilleri: ${ms.dynamics.loveLanguages.join(", ")}\n`;
    }
  }
  
  // Patterns
  if (ms.patterns) {
    if (ms.patterns.recurringIssues?.length) {
      context += `\n⚠️ TEKRAR EDEN SORUNLAR:\n`;
      ms.patterns.recurringIssues.forEach(issue => {
        context += `• ${issue}\n`;
      });
    }
    if (ms.patterns.strengths?.length) {
      context += `\n✅ GÜÇLÜ YANLAR:\n`;
      ms.patterns.strengths.forEach(s => {
        context += `• ${s}\n`;
      });
    }
  }
  
  context += `\n📌 KURALLAR:\n`;
  context += `• Bu bağlamı kullanıcı bu ilişkiden bahsederken referans al\n`;
  context += `• Yeni bir kişiden bahsediyorsa bu ilişkiyle karıştırma\n`;
  context += `• Spesifik alıntı yapman istenirse ve excerpt verilmemişse, "hatırlayamıyorum, detay verir misin?" de\n`;
  
  return context;
}

/**
 * Detect if user message needs chunk retrieval
 * Returns { needed, reason, query, dateHint?, confidence? }
 */
function detectRetrievalNeed(message, history) {
  const msgLower = message.toLowerCase();
  const msgNormalized = normalizeTurkish(msgLower);
  
  // ═══════════════════════════════════════════════════════════════
  // TASK B: Date parsing with normalized dates + ISO range
  // ═══════════════════════════════════════════════════════════════
  
  // Try to parse date from message
  const parsedDate = parseMessageDate(message);
  if (parsedDate) {
    return {
      needed: true,
      reason: "date_reference",
      query: parsedDate.displayText,
      dateHint: {
        startISO: parsedDate.startISO,
        endISO: parsedDate.endISO,
      },
      confidence: parsedDate.confidence,
      parsedDate: parsedDate,
    };
  }
  
  // Quote/reference patterns - expanded
  const quotePatterns = [
    /ne\s*dedi/i,
    /ne\s*demişti/i,
    /ne\s*yazdı/i,
    /ne\s*yazmıştı/i,
    /neydi/i,
    /hatırlıyor\s*mu/i,
    /hatırla/i,
    /hatırlat/i,
    /o\s*zaman/i,
    /mesaj/i,
    /konuş/i,
    /sohbet/i,
    /söylediği/i,
    /yazdığı/i,
    /alıntı/i,
    /örnek/i,
    /spesifik/i,
    /tam\s*olarak/i,
    /özür\s*dile/i,
    /tartış/i,
    /kavga/i,
    /kriz/i,
    /ayrıl/i,
    /barış/i,
    /bul\b/i,
    /ara\b/i,
    /getir/i,
    /göster/i,
    /oku/i,
    /çıkar/i,
    /anlat/i,
  ];
  
  // Check quote patterns
  for (const pattern of quotePatterns) {
    if (pattern.test(msgLower)) {
      const searchTerms = extractSearchTerms(message);
      return {
        needed: true,
        reason: "quote_request",
        query: searchTerms || message.slice(0, 100),
        confidence: 0.7,
      };
    }
  }
  
  // ═══════════════════════════════════════════════════════════════
  // TASK C: Keyword-based retrieval (ucuz yöntem)
  // ═══════════════════════════════════════════════════════════════
  const memoryKeywords = [
    "hatirla", "hatırlıyor", "soylemisti", "demisti", "yazmisti",
    "ne zaman", "o gun", "o zaman", "gecmiste", "once",
    "neydi", "kim", "nasil", "ne", "konusmus"
  ];
  
  if (memoryKeywords.some(kw => msgNormalized.includes(kw))) {
    const searchTerms = extractSearchTerms(message);
    if (searchTerms) {
      return {
        needed: true,
        reason: "keyword_match",
        query: searchTerms,
        confidence: 0.6,
      };
    }
  }
  
  return { needed: false };
}

/**
 * Parse date from message and return ISO range
 */
function parseMessageDate(message) {
  const msgLower = message.toLowerCase();
  
  // TR month names mapping
  const monthMap = {
    ocak: 0, subat: 1, şubat: 1, mart: 2, nisan: 3,
    mayis: 4, mayıs: 4, haziran: 5, temmuz: 6,
    agustos: 7, ağustos: 7, eylul: 8, eylül: 8,
    ekim: 9, kasim: 10, kasım: 10, aralik: 11, aralık: 11,
  };
  
  // Pattern 1: "22 Mayıs 2025" or "22 Mayıs"
  const p1 = /(\d{1,2})\s*(ocak|şubat|subat|mart|nisan|mayıs|mayis|haziran|temmuz|ağustos|agustos|eylül|eylul|ekim|kasım|kasim|aralık|aralik)\s*(\d{4})?/i;
  const m1 = msgLower.match(p1);
  if (m1) {
    const day = parseInt(m1[1]);
    const monthName = normalizeTurkish(m1[2]);
    const month = monthMap[monthName];
    const year = m1[3] ? parseInt(m1[3]) : new Date().getFullYear();
    
    const date = new Date(year, month, day);
    const startISO = new Date(year, month, day, 0, 0, 0).toISOString();
    const endISO = new Date(year, month, day, 23, 59, 59).toISOString();
    
    return {
      displayText: `${day} ${m1[2]} ${year}`,
      startISO,
      endISO,
      confidence: 0.95,
    };
  }
  
  // Pattern 2: "Mayıs 2025" (whole month)
  const p2 = /(ocak|şubat|subat|mart|nisan|mayıs|mayis|haziran|temmuz|ağustos|agustos|eylül|eylul|ekim|kasım|kasim|aralık|aralik)\s*(\d{4})/i;
  const m2 = msgLower.match(p2);
  if (m2) {
    const monthName = normalizeTurkish(m2[1]);
    const month = monthMap[monthName];
    const year = parseInt(m2[2]);
    
    const startISO = new Date(year, month, 1, 0, 0, 0).toISOString();
    const lastDay = new Date(year, month + 1, 0).getDate();
    const endISO = new Date(year, month, lastDay, 23, 59, 59).toISOString();
    
    return {
      displayText: `${m2[1]} ${year}`,
      startISO,
      endISO,
      confidence: 0.9,
    };
  }
  
  // Pattern 3: "dd.mm.yyyy" or "dd/mm/yyyy"
  const p3 = /(\d{1,2})[\.\/](\d{1,2})[\.\/](\d{2,4})/;
  const m3 = message.match(p3);
  if (m3) {
    let [, day, month, year] = m3;
    day = parseInt(day);
    month = parseInt(month) - 1;
    year = parseInt(year);
    if (year < 100) year += 2000;
    
    const startISO = new Date(year, month, day, 0, 0, 0).toISOString();
    const endISO = new Date(year, month, day, 23, 59, 59).toISOString();
    
    return {
      displayText: `${day}.${month + 1}.${year}`,
      startISO,
      endISO,
      confidence: 0.95,
    };
  }
  
  // Pattern 4: "yyyy-mm-dd"
  const p4 = /(\d{4})-(\d{1,2})-(\d{1,2})/;
  const m4 = message.match(p4);
  if (m4) {
    const [, year, month, day] = m4;
    const startISO = new Date(parseInt(year), parseInt(month) - 1, parseInt(day), 0, 0, 0).toISOString();
    const endISO = new Date(parseInt(year), parseInt(month) - 1, parseInt(day), 23, 59, 59).toISOString();
    
    return {
      displayText: `${day}.${month}.${year}`,
      startISO,
      endISO,
      confidence: 0.95,
    };
  }
  
  // Pattern 5: Relative dates
  if (/geçen\s*(hafta|ay)/i.test(msgLower)) {
    const now = new Date();
    const isWeek = /hafta/.test(msgLower);
    const daysAgo = isWeek ? 7 : 30;
    
    const endISO = now.toISOString();
    const start = new Date(now);
    start.setDate(start.getDate() - daysAgo);
    const startISO = start.toISOString();
    
    return {
      displayText: isWeek ? "geçen hafta" : "geçen ay",
      startISO,
      endISO,
      confidence: 0.7,
    };
  }
  
  if (/(\d+)\s*(ay|hafta|gün)\s*önce/i.test(msgLower)) {
    const match = msgLower.match(/(\d+)\s*(ay|hafta|gün)\s*önce/i);
    const num = parseInt(match[1]);
    const unit = match[2];
    const now = new Date();
    
    let daysAgo = num;
    if (unit.includes("hafta")) daysAgo *= 7;
    if (unit.includes("ay")) daysAgo *= 30;
    
    const start = new Date(now);
    start.setDate(start.getDate() - daysAgo);
    
    return {
      displayText: `${num} ${unit} önce`,
      startISO: start.toISOString(),
      endISO: now.toISOString(),
      confidence: 0.6,
    };
  }
  
  // Pattern 6: "o gün", "o gece" etc - contextual, low confidence
  if (/o\s*(gün|gece|akşam|zaman)/i.test(msgLower)) {
    return {
      displayText: "o gün (belirsiz)",
      startISO: null,
      endISO: null,
      confidence: 0.3,
    };
  }
  
  return null;
}

/**
 * Normalize Turkish characters for comparison
 */
function normalizeTurkish(text) {
  return text
    .toLowerCase()
    .replace(/ş/g, "s")
    .replace(/ı/g, "i")
    .replace(/ğ/g, "g")
    .replace(/ö/g, "o")
    .replace(/ü/g, "u")
    .replace(/ç/g, "c");
}

/**
 * Extract meaningful search terms from user message
 */
function extractSearchTerms(message) {
  // Remove common words
  const stopWords = [
    "ne", "neden", "nasıl", "kim", "ne zaman", "nerede",
    "bir", "bu", "şu", "o", "ve", "veya", "ile", "için",
    "mı", "mi", "mu", "mü", "mısın", "misin",
    "var", "yok", "değil", "evet", "hayır",
    "ben", "sen", "biz", "siz", "onlar",
    "bana", "sana", "bize", "size",
    "dedi", "demişti", "söyledi", "yazdı",
  ];
  
  const words = message
    .toLowerCase()
    .replace(/[^\wğüşıöçĞÜŞİÖÇ\s]/g, "")
    .split(/\s+/)
    .filter(w => w.length > 2 && !stopWords.includes(w));
  
  return words.slice(0, 5).join(" ");
}

/**
 * Generate focused excerpt from raw chunk based on user's question
 */
async function generateExcerpt(rawContent, userMessage, searchQuery) {
  // If content is small enough, return as is
  if (rawContent.length < 2000) {
    return rawContent;
  }
  
  const prompt = `Aşağıdaki WhatsApp sohbet kesitinden, kullanıcının sorusuyla en alakalı kısmı çıkar.

KULLANICI SORUSU: ${userMessage}
ARAMA TERİMİ: ${searchQuery}

SOHBET KESİTİ:
${rawContent.slice(0, 8000)}

GÖREV:
1. Soruyla en alakalı 10-20 mesajı bul
2. Bağlam için öncesi-sonrasıyla birlikte ver
3. Orijinal formatı koru ([tarih] isim: mesaj)
4. Maksimum 1500 karakter

Sadece alakalı mesajları döndür, başka bir şey yazma.`;

  try {
    const completion = await openai.chat.completions.create({
      model: "gpt-4o-mini",
      messages: [
        { role: "system", content: "Sohbet kesitlerinden alakalı bölümleri çıkaran bir asistansın." },
        { role: "user", content: prompt },
      ],
      temperature: 0.3,
      max_tokens: 800,
    });
    
    return completion.choices[0].message.content.trim();
  } catch (e) {
    console.error("generateExcerpt error:", e);
    // Fallback: return beginning of content
    return rawContent.slice(0, 1500) + "\n[...]";
  }
}

/**
 * Toggle relationship active status
 */
export async function toggleRelationshipActive(uid, relationshipId, isActive) {
  try {
    await firestore
      .collection("relationships")
      .doc(uid)
      .collection("relations")
      .doc(relationshipId)
      .update({ isActive, updatedAt: new Date().toISOString() });
    
    return true;
  } catch (e) {
    console.error(`toggleRelationshipActive error:`, e);
    return false;
  }
}

/**
 * Delete relationship and all associated data
 */
export async function deleteRelationship(uid, relationshipId) {
  try {
    const relationshipRef = firestore
      .collection("relationships")
      .doc(uid)
      .collection("relations")
      .doc(relationshipId);
    
    // Delete chunks subcollection
    const chunksSnapshot = await relationshipRef.collection("chunks").get();
    const batch = firestore.batch();
    chunksSnapshot.docs.forEach(doc => batch.delete(doc.ref));
    await batch.commit();
    
    // Delete main document
    await relationshipRef.delete();
    
    // Clear active pointer if this was active
    const userDoc = await firestore.collection("users").doc(uid).get();
    if (userDoc.data()?.activeRelationshipId === relationshipId) {
      await firestore.collection("users").doc(uid).update({
        activeRelationshipId: null,
      });
    }
    
    // Note: Storage files will remain (could add cleanup later)
    
    return true;
  } catch (e) {
    console.error(`deleteRelationship error:`, e);
    return false;
  }
}

/**
 * Get list of user's relationships
 */
export async function getUserRelationships(uid) {
  try {
    const snapshot = await firestore
      .collection("relationships")
      .doc(uid)
      .collection("relations")
      .orderBy("createdAt", "desc")
      .get();
    
    return snapshot.docs.map(doc => ({
      id: doc.id,
      ...doc.data(),
    }));
  } catch (e) {
    console.error(`getUserRelationships error:`, e);
    return [];
  }
}
