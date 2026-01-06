/**
 * ═══════════════════════════════════════════════════════════════
 * RELATIONSHIP PIPELINE
 * ═══════════════════════════════════════════════════════════════
 * Handles WhatsApp chat parsing, chunking, indexing and storage
 * 
 * Architecture:
 * - relationships/{uid}/{relationshipId} (master summary)
 * - relationships/{uid}/{relationshipId}/chunks/{chunkId} (lite index)
 * - Storage: relationship_chunks/{uid}/{relationshipId}/{chunkId}.txt
 * ═══════════════════════════════════════════════════════════════
 */

import { db as firestore, FieldValue } from "../config/firebaseAdmin.js";
import admin from "../config/firebaseAdmin.js";
import { openai } from "../config/openaiClient.js";
import crypto from "crypto";

const storage = admin.storage().bucket();

/**
 * Main pipeline entry point
 * @param {string} uid - User ID
 * @param {string} chatText - Raw WhatsApp chat text
 * @param {string} relationshipId - Optional existing relationship ID (for updates)
 * @param {boolean} forceUpdate - Force update even if mismatch detected
 * @returns {object} - { relationshipId, masterSummary, chunksCount, mismatchDetected?, reason? }
 */
export async function processRelationshipUpload(uid, chatText, relationshipId = null, forceUpdate = false) {
  console.log(`[${uid}] Starting relationship pipeline...`);
  
  // Generate relationship ID if new
  const relId = relationshipId || crypto.randomUUID();
  
  // Step 1: Parse messages
  const messages = parseWhatsAppMessages(chatText);
  console.log(`[${uid}] Parsed ${messages.length} messages`);
  
  if (messages.length === 0) {
    throw new Error("Sohbette mesaj bulunamadı");
  }
  
  // Step 2: Detect speakers
  const speakers = detectSpeakers(messages);
  console.log(`[${uid}] Detected speakers: ${speakers.join(", ")}`);
  
  // ═══════════════════════════════════════════════════════════════
  // MODULE 3: Mismatch detection if updating existing relationship
  // ═══════════════════════════════════════════════════════════════
  if (relationshipId && !forceUpdate) {
    const mismatchCheck = await detectRelationshipMismatch(uid, relationshipId, speakers);
    
    if (mismatchCheck.mismatch) {
      console.log(`[${uid}] Mismatch detected: ${mismatchCheck.reason}`);
      
      // Return early with mismatch warning
      return {
        mismatchDetected: true,
        reason: mismatchCheck.reason,
        suggestedAction: "create_new",
        relationshipId: null,
        masterSummary: null,
        chunksCount: 0,
        messagesCount: 0,
        speakers: [],
      };
    }
  }
  
  // ═══════════════════════════════════════════════════════════════
  // MODULE 3: Clean update - clear old data before writing new
  // ═══════════════════════════════════════════════════════════════
  if (relationshipId) {
    console.log(`[${uid}] Updating existing relationship ${relationshipId} - clearing old data`);
    
    try {
      // Clear Firestore chunks
      await clearFirestoreChunks(uid, relationshipId);
      
      // Clear Storage files
      await clearStorageFolder(uid, relationshipId);
      
      console.log(`[${uid}] Old data cleared successfully`);
    } catch (e) {
      console.error(`[${uid}] Error clearing old data:`, e);
      // Continue anyway - we'll overwrite
    }
  }
  
  // Step 3: Create time-based chunks
  const chunks = createTimeBasedChunks(messages);
  console.log(`[${uid}] Created ${chunks.length} chunks`);
  
  // Step 4: Process each chunk (summary + index)
  const chunkIndexes = [];
  for (let i = 0; i < chunks.length; i++) {
    const chunk = chunks[i];
    console.log(`[${uid}] Processing chunk ${i + 1}/${chunks.length}: ${chunk.dateRange}`);
    
    // Generate chunk summary and keywords with LLM
    const chunkMeta = await generateChunkIndex(chunk, speakers);
    
    // Save raw chunk to Storage
    const storagePath = `relationship_chunks/${uid}/${relId}/${chunk.id}.txt`;
    await saveChunkToStorage(storagePath, chunk.rawText);
    
    // Prepare index document
    chunkIndexes.push({
      chunkId: chunk.id,
      dateRange: chunk.dateRange,
      startDate: chunk.startDate,
      endDate: chunk.endDate,
      messageCount: chunk.messages.length,
      speakers: chunk.speakers,
      keywords: chunkMeta.keywords,
      topics: chunkMeta.topics,
      sentiment: chunkMeta.sentiment,
      summary: chunkMeta.summary,
      anchors: chunkMeta.anchors,
      storagePath: storagePath,
    });
  }
  
  // Step 5: Generate master summary
  console.log(`[${uid}] Generating master summary...`);
  const masterSummary = await generateMasterSummary(messages, speakers, chunkIndexes);
  
  // Step 5.5: Compute relationship stats
  console.log(`[${uid}] Computing relationship stats...`);
  const relationshipStats = computeRelationshipStats(messages, speakers);
  
  // Step 6: Save to Firestore
  console.log(`[${uid}] Saving to Firestore...`);
  
  // Save master document
  const relationshipRef = firestore
    .collection("relationships")
    .doc(uid)
    .collection("relations")
    .doc(relId);
  
  await relationshipRef.set({
    id: relId,
    speakers: speakers,
    totalMessages: messages.length,
    totalChunks: chunks.length,
    dateRange: {
      start: messages[0]?.date || null,
      end: messages[messages.length - 1]?.date || null,
    },
    masterSummary: masterSummary,
    statsCounts: relationshipStats.counts,
    statsBySpeaker: relationshipStats.bySpeaker,
    isActive: true,
    createdAt: FieldValue.serverTimestamp(),
    updatedAt: FieldValue.serverTimestamp(),
  });
  
  // Save chunk indexes as subcollection
  const chunksCollection = relationshipRef.collection("chunks");
  const batch = firestore.batch();
  
  for (const index of chunkIndexes) {
    const chunkRef = chunksCollection.doc(index.chunkId);
    batch.set(chunkRef, index);
  }
  
  await batch.commit();
  
  // Update user's active relationship pointer
  await firestore.collection("users").doc(uid).set({
    activeRelationshipId: relId,
  }, { merge: true });
  
  console.log(`[${uid}] Pipeline complete. RelationshipId: ${relId}`);
  
  return {
    relationshipId: relId,
    masterSummary,
    chunksCount: chunks.length,
    messagesCount: messages.length,
    speakers,
  };
}

/**
 * Parse WhatsApp export text into structured messages
 */
function parseWhatsAppMessages(text) {
  const messages = [];
  const lines = text.split("\n");
  
  // Common WhatsApp date patterns
  // [01/01/2024, 10:30:45] Name: Message
  // 01/01/2024, 10:30 - Name: Message
  // 01.01.2024, 10:30 - Name: Message
  const patterns = [
    /^\[(\d{1,2}\/\d{1,2}\/\d{2,4}),?\s+(\d{1,2}:\d{2}(?::\d{2})?)\]\s+([^:]+):\s*(.*)$/,
    /^(\d{1,2}\/\d{1,2}\/\d{2,4}),?\s+(\d{1,2}:\d{2}(?::\d{2})?)\s+-\s+([^:]+):\s*(.*)$/,
    /^(\d{1,2}\.\d{1,2}\.\d{2,4}),?\s+(\d{1,2}:\d{2}(?::\d{2})?)\s+-\s+([^:]+):\s*(.*)$/,
  ];
  
  let currentMessage = null;
  
  for (const line of lines) {
    let matched = false;
    
    for (const pattern of patterns) {
      const match = line.match(pattern);
      if (match) {
        // Save previous message
        if (currentMessage) {
          messages.push(currentMessage);
        }
        
        const [, datePart, timePart, sender, content] = match;
        const dateStr = normalizeDate(datePart, timePart);
        
        currentMessage = {
          date: dateStr,
          timestamp: new Date(dateStr).getTime() || Date.now(),
          sender: sender.trim(),
          content: content.trim(),
        };
        
        matched = true;
        break;
      }
    }
    
    // Continuation of previous message (multi-line)
    if (!matched && currentMessage && line.trim()) {
      currentMessage.content += "\n" + line.trim();
    }
  }
  
  // Don't forget last message
  if (currentMessage) {
    messages.push(currentMessage);
  }
  
  // Filter out system messages
  return messages.filter(m => 
    !m.content.includes("Messages and calls are end-to-end encrypted") &&
    !m.content.includes("created group") &&
    !m.content.includes("added you") &&
    !m.content.includes("changed the subject") &&
    !m.content.includes("<Media omitted>") &&
    m.content.length > 0
  );
}

/**
 * Normalize date string to ISO format
 */
function normalizeDate(datePart, timePart) {
  try {
    // Handle DD/MM/YYYY or DD.MM.YYYY
    const dateMatch = datePart.match(/(\d{1,2})[\/\.](\d{1,2})[\/\.](\d{2,4})/);
    if (!dateMatch) return new Date().toISOString();
    
    let [, day, month, year] = dateMatch;
    if (year.length === 2) {
      year = parseInt(year) > 50 ? `19${year}` : `20${year}`;
    }
    
    // Handle time
    const timeMatch = timePart.match(/(\d{1,2}):(\d{2})(?::(\d{2}))?/);
    if (!timeMatch) return new Date().toISOString();
    
    const [, hour, minute, second = "00"] = timeMatch;
    
    return new Date(
      parseInt(year),
      parseInt(month) - 1,
      parseInt(day),
      parseInt(hour),
      parseInt(minute),
      parseInt(second)
    ).toISOString();
  } catch (e) {
    return new Date().toISOString();
  }
}

/**
 * Detect unique speakers in conversation
 */
function detectSpeakers(messages) {
  const speakerCounts = {};
  
  for (const msg of messages) {
    speakerCounts[msg.sender] = (speakerCounts[msg.sender] || 0) + 1;
  }
  
  // Return top 2 speakers (main participants)
  return Object.entries(speakerCounts)
    .sort((a, b) => b[1] - a[1])
    .slice(0, 2)
    .map(([speaker]) => speaker);
}

/**
 * Create time-based chunks (adaptive: weekly for dense, monthly for sparse)
 */
function createTimeBasedChunks(messages) {
  if (messages.length === 0) return [];
  
  const chunks = [];
  const sortedMessages = [...messages].sort((a, b) => a.timestamp - b.timestamp);
  
  // Calculate overall density
  const totalDays = (sortedMessages[sortedMessages.length - 1].timestamp - sortedMessages[0].timestamp) / (1000 * 60 * 60 * 24);
  const avgMessagesPerDay = messages.length / Math.max(totalDays, 1);
  
  // Determine chunk strategy
  // High density (>50 msg/day): weekly chunks
  // Medium density (10-50 msg/day): bi-weekly chunks
  // Low density (<10 msg/day): monthly chunks
  let chunkDays;
  if (avgMessagesPerDay > 50) {
    chunkDays = 7;
  } else if (avgMessagesPerDay > 10) {
    chunkDays = 14;
  } else {
    chunkDays = 30;
  }
  
  console.log(`Chunk strategy: ${chunkDays} days (${avgMessagesPerDay.toFixed(1)} msg/day avg)`);
  
  let currentChunk = [];
  let chunkStartDate = null;
  let chunkNumber = 1;
  
  for (const msg of sortedMessages) {
    const msgDate = new Date(msg.timestamp);
    
    if (!chunkStartDate) {
      chunkStartDate = msgDate;
    }
    
    const daysSinceStart = (msgDate - chunkStartDate) / (1000 * 60 * 60 * 24);
    
    // Start new chunk if exceeded days OR chunk too large (>1000 messages)
    if (daysSinceStart >= chunkDays || currentChunk.length >= 1000) {
      if (currentChunk.length > 0) {
        chunks.push(finalizeChunk(currentChunk, chunkNumber));
        chunkNumber++;
      }
      currentChunk = [msg];
      chunkStartDate = msgDate;
    } else {
      currentChunk.push(msg);
    }
  }
  
  // Don't forget last chunk
  if (currentChunk.length > 0) {
    chunks.push(finalizeChunk(currentChunk, chunkNumber));
  }
  
  return chunks;
}

/**
 * Finalize a chunk with metadata
 */
function finalizeChunk(messages, chunkNumber) {
  const startDate = messages[0].date;
  const endDate = messages[messages.length - 1].date;
  
  // Build raw text
  const rawText = messages
    .map(m => `[${m.date}] ${m.sender}: ${m.content}`)
    .join("\n");
  
  // Get unique speakers in this chunk
  const speakers = [...new Set(messages.map(m => m.sender))];
  
  // Format date range for display
  const start = new Date(startDate);
  const end = new Date(endDate);
  const dateRange = `${start.toLocaleDateString("tr-TR")} - ${end.toLocaleDateString("tr-TR")}`;
  
  return {
    id: `chunk_${chunkNumber.toString().padStart(3, "0")}`,
    messages,
    rawText,
    speakers,
    startDate,
    endDate,
    dateRange,
  };
}

/**
 * Generate chunk index using LLM (summary, keywords, topics, anchors)
 */
async function generateChunkIndex(chunk, allSpeakers) {
  // Truncate if too long for LLM
  const maxChars = 15000;
  let textForAnalysis = chunk.rawText;
  if (textForAnalysis.length > maxChars) {
    // Sample: beginning + middle + end
    const partSize = Math.floor(maxChars / 3);
    const middle = Math.floor(textForAnalysis.length / 2);
    textForAnalysis = 
      textForAnalysis.slice(0, partSize) +
      "\n\n[...]\n\n" +
      textForAnalysis.slice(middle - partSize/2, middle + partSize/2) +
      "\n\n[...]\n\n" +
      textForAnalysis.slice(-partSize);
  }
  
  const prompt = `Aşağıdaki WhatsApp sohbet kesitini analiz et.

SOHBET:
${textForAnalysis}

Şu JSON formatında döndür:
{
  "summary": "<2-3 cümlelik bu dönemin özeti, Türkçe>",
  "keywords": ["<en önemli 5-10 anahtar kelime>"],
  "topics": ["<bu dönemde konuşulan ana konular, 3-5 adet>"],
  "sentiment": "<'positive', 'negative', 'neutral' veya 'mixed'>",
  "anchors": [
    {
      "type": "<'conflict', 'love', 'apology', 'plan', 'memory', 'milestone'>",
      "quote": "<ilgili kısa alıntı, max 100 karakter>",
      "context": "<1 cümlelik bağlam>"
    }
  ]
}

NOT:
- anchors: Bu dönemdeki önemli anlardan 3-5 tane seç (tartışma, sevgi ifadesi, özür, plan, anı, dönüm noktası)
- Sadece JSON döndür, başka bir şey yazma`;

  try {
    const completion = await openai.chat.completions.create({
      model: "gpt-4o-mini",
      messages: [
        { role: "system", content: "Sen bir sohbet analiz asistanısın. Kısa ve öz JSON döndürüyorsun." },
        { role: "user", content: prompt },
      ],
      temperature: 0.5,
      max_tokens: 1000,
      response_format: { type: "json_object" },
    });
    
    const result = JSON.parse(completion.choices[0].message.content);
    
    return {
      summary: result.summary || "",
      keywords: result.keywords || [],
      topics: result.topics || [],
      sentiment: result.sentiment || "neutral",
      anchors: result.anchors || [],
    };
  } catch (e) {
    console.error("generateChunkIndex error:", e);
    return {
      summary: `${chunk.messages.length} mesaj, ${chunk.dateRange}`,
      keywords: [],
      topics: [],
      sentiment: "neutral",
      anchors: [],
    };
  }
}

/**
 * Generate master summary for entire relationship
 */
async function generateMasterSummary(messages, speakers, chunkIndexes) {
  // Combine all chunk summaries
  const chunkSummaries = chunkIndexes
    .map(c => `${c.dateRange}: ${c.summary}`)
    .join("\n");
  
  // Sample some messages for personality analysis
  const sampleSize = Math.min(100, messages.length);
  const step = Math.floor(messages.length / sampleSize);
  const sampledMessages = messages
    .filter((_, i) => i % step === 0)
    .slice(0, sampleSize)
    .map(m => `${m.sender}: ${m.content.slice(0, 200)}`)
    .join("\n");
  
  const prompt = `Aşağıdaki ilişki verilerini analiz et ve kapsamlı bir özet oluştur.

KONUŞMACLAR: ${speakers.join(", ")}
TOPLAM MESAJ: ${messages.length}
DÖNEM ÖZETLERİ:
${chunkSummaries}

ÖRNEK MESAJLAR:
${sampledMessages}

Şu JSON formatında döndür:
{
  "shortSummary": "<3-4 cümlelik genel ilişki özeti>",
  "personalities": {
    "${speakers[0] || "Kişi1"}": {
      "traits": ["<3-5 kişilik özelliği>"],
      "communicationStyle": "<iletişim tarzı, 1 cümle>",
      "emotionalPattern": "<duygusal örüntü, 1 cümle>"
    },
    "${speakers[1] || "Kişi2"}": {
      "traits": ["<3-5 kişilik özelliği>"],
      "communicationStyle": "<iletişim tarzı, 1 cümle>",
      "emotionalPattern": "<duygusal örüntü, 1 cümle>"
    }
  },
  "dynamics": {
    "powerBalance": "<'balanced', 'user_dominant', 'partner_dominant'>",
    "attachmentPattern": "<'secure', 'anxious', 'avoidant', 'mixed'>",
    "conflictStyle": "<nasıl tartışıyorlar, 1-2 cümle>",
    "loveLanguages": ["<sevgi dilleri>"]
  },
  "patterns": {
    "recurringIssues": ["<tekrar eden sorunlar, 3-5 adet>"],
    "strengths": ["<ilişkinin güçlü yanları, 3-5 adet>"],
    "redFlags": ["<kırmızı bayraklar varsa, 0-3 adet>"],
    "greenFlags": ["<yeşil bayraklar, 0-3 adet>"]
  },
  "timeline": {
    "phases": [
      {
        "name": "<dönem adı>",
        "period": "<tarih aralığı>",
        "description": "<1-2 cümle açıklama>"
      }
    ]
  }
}

ÖNEMLİ: Sadece JSON döndür. Türkçe yaz.`;

  try {
    const completion = await openai.chat.completions.create({
      model: "gpt-4o-mini",
      messages: [
        { role: "system", content: "Sen bir ilişki analiz uzmanısın. Derinlemesine ama öz analizler yapıyorsun." },
        { role: "user", content: prompt },
      ],
      temperature: 0.7,
      max_tokens: 2000,
      response_format: { type: "json_object" },
    });
    
    return JSON.parse(completion.choices[0].message.content);
  } catch (e) {
    console.error("generateMasterSummary error:", e);
    return {
      shortSummary: `${speakers.join(" ve ")} arasındaki ${messages.length} mesajlık sohbet analizi.`,
      personalities: {},
      dynamics: {},
      patterns: {},
      timeline: {},
    };
  }
}

/**
 * Save chunk raw text to Firebase Storage
 */
async function saveChunkToStorage(path, text) {
  try {
    const file = storage.file(path);
    await file.save(text, {
      contentType: "text/plain; charset=utf-8",
      metadata: {
        cacheControl: "private, max-age=31536000",
      },
    });
  } catch (e) {
    console.error(`saveChunkToStorage error (${path}):`, e);
    throw e;
  }
}

/**
 * Retrieve chunk from Storage
 */
export async function getChunkFromStorage(storagePath) {
  try {
    const file = storage.file(storagePath);
    const [content] = await file.download();
    return content.toString("utf-8");
  } catch (e) {
    console.error(`getChunkFromStorage error (${storagePath}):`, e);
    return null;
  }
}

/**
 * Search chunks by keyword/topic/date
 * @param {string} uid
 * @param {string} relationshipId
 * @param {string} query - Search query
 * @param {object} dateHint - Optional { startISO, endISO } for date range matching
 */
export async function searchChunks(uid, relationshipId, query, dateHint = null) {
  const chunksRef = firestore
    .collection("relationships")
    .doc(uid)
    .collection("relations")
    .doc(relationshipId)
    .collection("chunks");
  
  const snapshot = await chunksRef.get();
  const chunks = snapshot.docs.map(doc => doc.data());
  
  const queryLower = query.toLowerCase();
  const queryNormalized = normalizeTurkish(queryLower);
  const results = [];
  
  for (const chunk of chunks) {
    let score = 0;
    
    // ═══════════════════════════════════════════════════════════════
    // TASK B: Date range matching (primary scoring if dateHint exists)
    // ═══════════════════════════════════════════════════════════════
    if (dateHint && dateHint.startISO && dateHint.endISO && chunk.startDate && chunk.endDate) {
      // Check if chunk overlaps with requested date range
      // chunk.startDate <= dateHint.endISO AND chunk.endDate >= dateHint.startISO
      const chunkStart = new Date(chunk.startDate).getTime();
      const chunkEnd = new Date(chunk.endDate).getTime();
      const queryStart = new Date(dateHint.startISO).getTime();
      const queryEnd = new Date(dateHint.endISO).getTime();
      
      if (chunkStart <= queryEnd && chunkEnd >= queryStart) {
        // Overlapping date range - HIGH SCORE
        score += 10;
        
        // Bonus if it's a perfect match (contains the entire query range)
        if (chunkStart <= queryStart && chunkEnd >= queryEnd) {
          score += 5;
        }
      }
    }
    
    // ═══════════════════════════════════════════════════════════════
    // TASK C: Keyword-based matching (works even without patterns)
    // ═══════════════════════════════════════════════════════════════
    
    // Keyword match (normalized)
    if (chunk.keywords?.some(k => {
      const kNorm = normalizeTurkish(k.toLowerCase());
      return kNorm.includes(queryNormalized) || queryNormalized.includes(kNorm);
    })) {
      score += 3;
    }
    
    // Topic match (normalized)
    if (chunk.topics?.some(t => {
      const tNorm = normalizeTurkish(t.toLowerCase());
      return tNorm.includes(queryNormalized) || queryNormalized.includes(tNorm);
    })) {
      score += 2;
    }
    
    // Summary match (normalized)
    if (chunk.summary) {
      const summaryNorm = normalizeTurkish(chunk.summary.toLowerCase());
      if (summaryNorm.includes(queryNormalized)) {
        score += 1;
      }
    }
    
    // Legacy date match (fallback if no dateHint but query looks like date)
    if (!dateHint && chunk.dateRange) {
      const dateRangeNorm = normalizeTurkish(chunk.dateRange.toLowerCase());
      if (dateRangeNorm.includes(queryNormalized)) {
        score += 4;
      }
    }
    
    if (score > 0) {
      results.push({ ...chunk, score });
    }
  }
  
  return results.sort((a, b) => b.score - a.score).slice(0, 5);
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
 * Compute relationship statistics from messages
 * @param {Array} messages - Parsed messages
 * @param {Array} speakers - List of speakers
 * @returns {object} - { counts, bySpeaker }
 */
function computeRelationshipStats(messages, speakers) {
  // Initialize counters
  const messageCount = {};
  const loveYouCount = {};
  const apologyCount = {};
  const emojiCount = {};
  
  // Patterns for detection
  const lovePatterns = [
    /\bseni seviyorum\b/i,
    /\bseviyorum\b/i,
    /\bi love you\b/i,
    /\blove you\b/i,
    /\başkımsın\b/i,
    /\bcanımsın\b/i,
  ];
  
  const apologyPatterns = [
    /\bözür\b/i,
    /\bpardon\b/i,
    /\bsorry\b/i,
    /\bkusura bakma\b/i,
    /\bafedersin\b/i,
    /\baffet\b/i,
  ];
  
  // Basic emoji regex (matches common emoji ranges)
  const emojiRegex = /[\u{1F600}-\u{1F64F}\u{1F300}-\u{1F5FF}\u{1F680}-\u{1F6FF}\u{1F700}-\u{1F77F}\u{1F780}-\u{1F7FF}\u{1F800}-\u{1F8FF}\u{1F900}-\u{1F9FF}\u{1FA00}-\u{1FA6F}\u{1FA70}-\u{1FAFF}\u{2600}-\u{26FF}\u{2700}-\u{27BF}]/gu;
  
  // Initialize speaker counts
  for (const speaker of speakers) {
    messageCount[speaker] = 0;
    loveYouCount[speaker] = 0;
    apologyCount[speaker] = 0;
    emojiCount[speaker] = 0;
  }
  
  // Process each message
  for (const msg of messages) {
    const sender = msg.sender;
    const content = msg.content || "";
    
    // Skip if sender not in speakers list
    if (!speakers.includes(sender)) continue;
    
    // Count messages
    messageCount[sender]++;
    
    // Count "I love you"
    for (const pattern of lovePatterns) {
      if (pattern.test(content)) {
        loveYouCount[sender]++;
        break; // Count only once per message
      }
    }
    
    // Count apologies
    for (const pattern of apologyPatterns) {
      if (pattern.test(content)) {
        apologyCount[sender]++;
        break;
      }
    }
    
    // Count emojis
    const emojis = content.match(emojiRegex);
    if (emojis) {
      emojiCount[sender] += emojis.length;
    }
  }
  
  // Determine winners for each category
  function findWinner(counts) {
    const entries = Object.entries(counts);
    if (entries.length === 0) return "none";
    
    const sorted = entries.sort((a, b) => b[1] - a[1]);
    const max = sorted[0][1];
    
    // No data
    if (max === 0) return "none";
    
    // Check if balanced (within 10% difference for 2 speakers)
    if (speakers.length === 2) {
      const diff = Math.abs(sorted[0][1] - sorted[1][1]);
      const avg = (sorted[0][1] + sorted[1][1]) / 2;
      if (avg > 0 && diff / avg < 0.1) {
        return "balanced";
      }
    }
    
    return sorted[0][0];
  }
  
  const bySpeaker = {
    whoSentMoreMessages: findWinner(messageCount),
    whoSaidILoveYouMore: findWinner(loveYouCount),
    whoApologizedMore: findWinner(apologyCount),
    whoUsedMoreEmojis: findWinner(emojiCount),
  };
  
  return {
    counts: {
      messageCount,
      loveYou: loveYouCount,
      apology: apologyCount,
      emoji: emojiCount,
    },
    bySpeaker,
  };
}

/**
 * ═══════════════════════════════════════════════════════════════
 * MODULE 3: HELPER FUNCTIONS FOR CLEAN UPDATE/FORGET
 * ═══════════════════════════════════════════════════════════════
 */

/**
 * Clear all Firestore chunks for a relationship
 * @param {string} uid - User ID
 * @param {string} relationshipId - Relationship ID
 */
export async function clearFirestoreChunks(uid, relationshipId) {
  try {
    console.log(`[${uid}] Clearing Firestore chunks for relationship ${relationshipId}`);
    
    const relationshipRef = firestore
      .collection("relationships")
      .doc(uid)
      .collection("relations")
      .doc(relationshipId);
    
    const chunksSnapshot = await relationshipRef.collection("chunks").get();
    
    if (chunksSnapshot.empty) {
      console.log(`[${uid}] No chunks to clear`);
      return;
    }
    
    // Delete in batches (Firestore limit = 500)
    let batch = firestore.batch();
    let batchCount = 0;
    
    for (const doc of chunksSnapshot.docs) {
      batch.delete(doc.ref);
      batchCount++;
      
      if (batchCount >= 500) {
        await batch.commit();
        batch = firestore.batch();
        batchCount = 0;
      }
    }
    
    // Commit remaining
    if (batchCount > 0) {
      await batch.commit();
    }
    
    console.log(`[${uid}] Cleared ${chunksSnapshot.docs.length} Firestore chunks`);
  } catch (e) {
    console.error(`[${uid}] Error clearing Firestore chunks:`, e);
    throw e;
  }
}

/**
 * Clear all Storage files for a relationship
 * @param {string} uid - User ID
 * @param {string} relationshipId - Relationship ID
 */
export async function clearStorageFolder(uid, relationshipId) {
  try {
    console.log(`[${uid}] Clearing Storage folder for relationship ${relationshipId}`);
    
    const prefix = `relationship_chunks/${uid}/${relationshipId}/`;
    const [files] = await storage.getFiles({ prefix });
    
    if (files.length === 0) {
      console.log(`[${uid}] No storage files to clear`);
      return;
    }
    
    // Delete all files
    await Promise.all(files.map(file => file.delete()));
    
    console.log(`[${uid}] Cleared ${files.length} Storage files`);
  } catch (e) {
    console.error(`[${uid}] Error clearing Storage folder:`, e);
    throw e;
  }
}

/**
 * Detect if new upload is a mismatch with existing relationship
 * @param {string} uid - User ID
 * @param {string} relationshipId - Existing relationship ID
 * @param {Array} newSpeakers - Speakers from new upload
 * @returns {Promise<{mismatch: boolean, reason: string}>}
 */
export async function detectRelationshipMismatch(uid, relationshipId, newSpeakers) {
  try {
    console.log(`[${uid}] Checking mismatch for relationship ${relationshipId}`);
    
    // Get existing relationship data
    const relationshipRef = firestore
      .collection("relationships")
      .doc(uid)
      .collection("relations")
      .doc(relationshipId);
    
    const relationshipDoc = await relationshipRef.get();
    
    if (!relationshipDoc.exists) {
      return { mismatch: false, reason: "No existing relationship" };
    }
    
    const existingSpeakers = relationshipDoc.data().speakers || [];
    
    // Simple mismatch heuristic: check if speakers match
    if (existingSpeakers.length !== newSpeakers.length) {
      return {
        mismatch: true,
        reason: `Farklı kişi sayısı: eskide ${existingSpeakers.length}, yenide ${newSpeakers.length}`,
      };
    }
    
    // Check if any speaker name is completely different
    const existingSet = new Set(existingSpeakers.map(s => s.toLowerCase().trim()));
    const newSet = new Set(newSpeakers.map(s => s.toLowerCase().trim()));
    
    let matchCount = 0;
    for (const newSpeaker of newSet) {
      if (existingSet.has(newSpeaker)) {
        matchCount++;
      }
    }
    
    // If less than 50% match, it's likely a different relationship
    const matchRate = matchCount / newSpeakers.length;
    
    if (matchRate < 0.5) {
      return {
        mismatch: true,
        reason: `Farklı kişiler: ${newSpeakers.join(", ")} (eskide: ${existingSpeakers.join(", ")})`,
      };
    }
    
    return { mismatch: false, reason: "Speakers match" };
  } catch (e) {
    console.error(`[${uid}] Error detecting mismatch:`, e);
    return { mismatch: false, reason: "Error checking mismatch" };
  }
}