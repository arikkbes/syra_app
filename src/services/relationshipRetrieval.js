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
      console.log(`[${uid}] Relationship exists but isActive=false, skipping context`);
      return null;
    }
    
    // Build base context from master summary
    let context = buildMasterContext(relationship);
    
    // Check if user message needs retrieval
    const needsRetrieval = detectRetrievalNeed(userMessage, conversationHistory);
    
    if (needsRetrieval.needed) {
      console.log(`[${uid}] Retrieval triggered: ${needsRetrieval.reason}`);
      
      // Search for relevant chunks
      const relevantChunks = await searchChunks(
        uid, 
        activeRelationshipId, 
        needsRetrieval.query
      );
      
      if (relevantChunks.length > 0) {
        // Fetch raw content from best matching chunk
        const bestChunk = relevantChunks[0];
        const rawContent = await getChunkFromStorage(bestChunk.storagePath);
        
        if (rawContent) {
          // Generate focused excerpt based on user's question
          const excerpt = await generateExcerpt(
            rawContent, 
            userMessage, 
            needsRetrieval.query
          );
          
          context += `\n\n📎 ALAKALI SOHBET KESİTİ (${bestChunk.dateRange}):\n${excerpt}`;
          context += `\n\n⚠️ Alıntı yapacaksan SADECE yukarıdaki kesitte geçenleri kullan. Kesitte olmayan bir şey söyleme.`;
        }
      } else {
        context += `\n\n⚠️ Kullanıcının sorduğu spesifik konu/tarih için kayıtlarda eşleşme bulunamadı. Bunu kibarca belirt.`;
      }
    }
    
    return {
      context,
      relationshipId: activeRelationshipId,
      speakers: relationship.speakers,
      hasRetrieval: needsRetrieval.needed,
    };
    
  } catch (e) {
    console.error(`[${uid}] getRelationshipContext error:`, e);
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
 */
function detectRetrievalNeed(message, history) {
  const msgLower = message.toLowerCase();
  
  // Date patterns - expanded
  const datePatterns = [
    /(\d{1,2})\s*(ocak|şubat|mart|nisan|mayıs|haziran|temmuz|ağustos|eylül|ekim|kasım|aralık)/i,
    /(ocak|şubat|mart|nisan|mayıs|haziran|temmuz|ağustos|eylül|ekim|kasım|aralık)\s*(\d{4})?/i,
    /(\d{1,2})[\.\/](\d{1,2})[\.\/](\d{2,4})/i, // 22.05.2025 veya 22/05/2025
    /(\d{4})\s*(yılı|yılında|senesinde)/i, // 2025 yılında
    /geçen\s*(ay|hafta|yıl|gün|gece|akşam|sabah)/i,
    /(\d+)\s*(ay|hafta|gün)\s*önce/i,
    /ilk\s*(ay|hafta|gün|zaman)/i,
    /son\s*(ay|hafta|gün|zaman)/i,
    /başında|ortasında|sonunda/i,
    /dün|bugün|önceki\s*gün/i,
    /o\s*gün|o\s*gece|o\s*akşam/i,
  ];
  
  // Quote/reference patterns - expanded
  const quotePatterns = [
    /ne\s*dedi/i,
    /ne\s*demişti/i,
    /ne\s*yazdı/i,
    /ne\s*yazmıştı/i,
    /neydi/i,  // "konuşma neydi"
    /hatırlıyor\s*mu/i,
    /hatırla/i,
    /hatırlat/i,
    /o\s*zaman/i,
    /mesaj/i,
    /konuş/i, // konuşma, konuşmuştuk, konuştuk
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
    /bul\b/i, // "... bul"
    /ara\b/i, // "... ara"
    /getir/i,
    /göster/i,
    /oku/i,
    /çıkar/i, // "alıntı çıkar"
    /anlat/i,
    /öğlen|sabah|akşam|gece/i, // zaman referansları
  ];
  
  // Check date patterns
  for (const pattern of datePatterns) {
    const match = msgLower.match(pattern);
    if (match) {
      console.log(`Retrieval triggered by date pattern: ${match[0]}`);
      return {
        needed: true,
        reason: "date_reference",
        query: match[0],
      };
    }
  }
  
  // Check quote patterns
  for (const pattern of quotePatterns) {
    if (pattern.test(msgLower)) {
      // Extract potential search terms
      const searchTerms = extractSearchTerms(message);
      console.log(`Retrieval triggered by quote pattern: ${pattern}, terms: ${searchTerms}`);
      return {
        needed: true,
        reason: "quote_request",
        query: searchTerms || message.slice(0, 100),
      };
    }
  }
  
  return { needed: false };
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
