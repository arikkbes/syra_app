/**
 * ═══════════════════════════════════════════════════════════════
 * RELATIONSHIP RETRIEVAL SERVICE (PHASE 1)
 * ═══════════════════════════════════════════════════════════════
 * Deterministic retrieval only. No LLM excerpt selection.
 * - REL_BRIEF: metadata only
 * - EVIDENCE: deterministic evidence pack
 * - WINDOW: 20–60 message window
 */

import { db as firestore } from "../config/firebaseAdmin.js";
import { openai } from "../config/openaiClient.js";
import {
  getActiveRelationshipContext,
  buildParticipantContextPrompt,
  mapSpeakerToRole,
  isRelationshipEligible,
} from "./relationshipContext.js";
import { getSupabaseClient } from "./supabaseClient.js";
import { getChunkFromStorage } from "./relationshipPipeline.js";

const MAX_EVIDENCE_ITEMS = 12;
const EMBEDDING_MODEL = "text-embedding-3-small";
const MAX_TEXT_LENGTH = 2000;

const TURKISH_STOPWORDS = new Set([
  "mi", "mu", "ki", "de", "da", "ya", "ve", "bir", "bu", "su",
  "o", "ne", "ama", "ile", "icin", "gibi", "var", "yok",
  "dedi", "yazdi", "soyledi", "demis", "sordu", "sormis", "neden",
  "goster", "getir", "kanit", "bul", "mesaj", "alinti", "timestamp", "proof", "quote",
]);

function keywordWeight(word) {
  if (word.length >= 7) return 4;
  if (word.length >= 5) return 3;
  if (word.length >= 4) return 2;
  return 1;
}

function isDateOutsideRange(dateHint, dateRange) {
  if (!dateHint?.start || !dateHint?.end) return false;
  if (!dateRange?.start || !dateRange?.end) return false;
  const hintStart = new Date(dateHint.start);
  const hintEnd = new Date(dateHint.end);
  const rangeStart = new Date(dateRange.start);
  const rangeEnd = new Date(dateRange.end);
  if (Number.isNaN(hintStart.getTime()) || Number.isNaN(hintEnd.getTime())) return false;
  if (Number.isNaN(rangeStart.getTime()) || Number.isNaN(rangeEnd.getTime())) return false;
  return hintEnd < rangeStart || hintStart > rangeEnd;
}

export async function getActiveRelationshipSnapshot(uid, options = {}) {
  const { forceIncludeInactive = false } = options;
  const relationshipContext = await getActiveRelationshipContext(uid, {
    forceIncludeInactive,
  });
  if (!relationshipContext) {
    return null;
  }

  const { relationshipId } = relationshipContext;
  const relationshipRef = firestore
    .collection("relationships")
    .doc(uid)
    .collection("relations")
    .doc(relationshipId);

  const relationshipDoc = await relationshipRef.get();
  if (!relationshipDoc.exists) {
    return null;
  }

  const relationship = relationshipDoc.data();
  if (!isRelationshipEligible(relationship, forceIncludeInactive)) {
    return null;
  }

  return {
    relationshipId,
    relationship,
    relationshipContext,
    participantPrompt: buildParticipantContextPrompt(relationshipContext),
  };
}

export async function getRelationshipBrief(uid, options = {}) {
  const snapshot = await getActiveRelationshipSnapshot(uid, options);
  if (!snapshot) return null;

  const { relationshipId, relationship, relationshipContext } = snapshot;

  return {
    relationshipId,
    isActive: relationship.isActive !== false,
    totalMessages: relationship.totalMessages ?? null,
    speakers: relationship.speakers || [],
    dateRange: relationship.dateRange || {},
    lastUploadAt:
      relationship.lastUploadAt ||
      relationship.updatedAt ||
      relationship.createdAt ||
      null,
    selfParticipant: relationshipContext?.selfParticipant || null,
    partnerParticipant: relationshipContext?.partnerParticipant || null,
  };
}

export function formatRelationshipBrief(brief) {
  const speakersText = brief.speakers.length
    ? brief.speakers.join(", ")
    : "yok";

  const dateStart = brief.dateRange?.start || "bilinmiyor";
  const dateEnd = brief.dateRange?.end || "bilinmiyor";
  const messageCount =
    typeof brief.totalMessages === "number"
      ? String(brief.totalMessages)
      : "bilinmiyor";
  const lastUploadAt = brief.lastUploadAt || "bilinmiyor";
  const activeText = brief.isActive ? "evet" : "hayır";

  return [
    "Elimdeki ilişki metaverisi:",
    `• Tarih aralığı: ${dateStart} → ${dateEnd}`,
    `• Toplam mesaj: ${messageCount}`,
    `• Konuşmacılar: ${speakersText}`,
    `• Son yükleme: ${lastUploadAt}`,
    `• Aktif: ${activeText}`,
    "İçerik/psikolojik özet kullanmıyorum. İstersen kanıt veya belirli tarih aralığı isteyebilirsin.",
  ].join("\n");
}

export async function buildEvidencePack(uid, userMessage, options = {}) {
  const snapshot = await getActiveRelationshipSnapshot(uid, options);
  if (!snapshot) {
    return { error: "no_active_relationship" };
  }

  const { relationshipId, relationshipContext, relationship } = snapshot;
  const { query, dateHint, dateOnly } = buildSearchQuery(userMessage);
  const explicitKeyword = extractExplicitKeywordFromQuery(userMessage);
  const keywordMode = !!explicitKeyword;
  let effectiveQuery = keywordMode ? explicitKeyword : query;
  const matchCount = keywordMode ? 30 : 12;

  // ── Alias / actor resolution ──────────────────────────────────────
  const participantAliases = relationship.participantAliases || {};
  const speakers = relationship.speakers || [];
  const actorInfo = extractActorNameFromQuery(userMessage);
  let speakerFilter = null;
  let aliasNeeded = null;
  let aliasOriginalQuery = null;

  if (actorInfo) {
    const normName = normalizeTurkishText(actorInfo.name).toLowerCase();
    const directMatch = speakers.find(
      (s) => normalizeTurkishText(s).toLowerCase() === normName
    );
    if (directMatch) {
      speakerFilter = directMatch;
    } else if (participantAliases[normName]) {
      speakerFilter = participantAliases[normName];
    } else {
      aliasNeeded = actorInfo.name;
      aliasOriginalQuery = userMessage;
    }
    console.log(
      `[buildEvidencePack] uid=${uid} speakerConstraint=${speakerFilter || "none"} aliasNeeded=${aliasNeeded || "none"}`
    );
  }

  if (aliasNeeded) {
    return { items: [], query: effectiveQuery, dateHint, dateOnly, aliasNeeded, aliasOriginalQuery };
  }

  if (speakerFilter && actorInfo?.restQuery) {
    effectiveQuery = normalizeQueryText(actorInfo.restQuery) || effectiveQuery;
  }

  if (dateHint && isDateOutsideRange(dateHint, relationship?.dateRange)) {
    return { error: "date_out_of_range", dateRange: relationship?.dateRange };
  }

  if (!effectiveQuery) {
    return { items: [], query: "", dateHint, dateOnly, needsTopicHint: dateOnly };
  }

  const semanticReady = relationship.semanticIndex?.ready === true;
  let chunkIds = [];
  let fallbackUsed = false;

  console.log(`[buildEvidencePack] uid=${uid} semanticReady=${semanticReady}`);

  if (semanticReady) {
    try {
      chunkIds = await semanticSearchChunkIds(
        uid,
        relationshipId,
        effectiveQuery,
        dateHint,
        matchCount
      );
    } catch (e) {
      console.error(`[${uid}] Semantic chunk search failed, using keyword fallback:`, e);
      fallbackUsed = true;
    }
  } else {
    fallbackUsed = true;
  }

  if (fallbackUsed) {
    chunkIds = await keywordFallbackChunkIds(uid, relationshipId, effectiveQuery);
    console.log(
      `[buildEvidencePack] uid=${uid} fallbackUsed=true matchedChunkCount=${chunkIds.length}`
    );
  }

  if (!chunkIds.length) {
    return {
      items: [], query: effectiveQuery, dateHint, dateOnly,
      speakerConstraint: speakerFilter,
      speakerHasNoMatch: !!speakerFilter,
      keywordInOtherSpeaker: false, contextEvidence: [],
      aliasNeeded: null, aliasOriginalQuery: null,
    };
  }

  const items = [];
  const seen = new Set();
  let speakerHasNoMatch = !!speakerFilter;
  let keywordInOtherSpeaker = false;
  const contextEvidence = [];
  const MAX_FALLBACK_ITEMS = 5;
  const targetCount =
    chunkIds.length >= 2
      ? Math.min(fallbackUsed ? MAX_FALLBACK_ITEMS : MAX_EVIDENCE_ITEMS, chunkIds.length)
      : chunkIds.length;

  for (const chunkId of chunkIds) {
    if (items.length >= targetCount) break;

    const chunkIndex = await fetchChunkIndex(uid, relationshipId, chunkId);
    if (!chunkIndex?.storagePath) continue;

    const rawChunk = await getChunkFromStorage(chunkIndex.storagePath);
    const messages = parseChunkMessages(rawChunk);
    if (!messages.length) continue;

    let messageIndex;
    if (speakerFilter) {
      const speakerIdxs = messages
        .map((m, i) => i)
        .filter((i) => messages[i].sender === speakerFilter);
      if (!speakerIdxs.length) {
        // Keyword exists in chunk but from a different sender
        if (messages.some((m) => containsNormalizedKeyword(m.content, effectiveQuery))) {
          keywordInOtherSpeaker = true;
          const otherEvidence = messages.find((m) =>
            containsNormalizedKeyword(m.content, effectiveQuery)
          );
          if (otherEvidence && contextEvidence.length < 2) {
            contextEvidence.push({
              timestamp: otherEvidence.timestamp,
              sender: otherEvidence.sender,
              matchedLine: extractMatchedLine(otherEvidence.content),
              role: mapSpeakerToRole(otherEvidence.sender, relationshipContext),
            });
          }
        }
        continue;
      }
      const speakerMsgs = speakerIdxs.map((i) => messages[i]);
      const bestSub = findBestMessageIndex(speakerMsgs, effectiveQuery);
      messageIndex = speakerIdxs[bestSub];
    } else {
      messageIndex = findBestMessageIndex(messages, effectiveQuery);
    }
    const matchedMessage = messages[messageIndex];
    if (!matchedMessage) continue;

    const key = `${matchedMessage.timestamp}|${matchedMessage.sender}|${messageIndex}`;
    if (seen.has(key)) continue;
    seen.add(key);

    const contextBefore = messages
      .slice(Math.max(0, messageIndex - 2), messageIndex)
      .map(formatMessageLine);
    const contextAfter = messages
      .slice(messageIndex + 1, messageIndex + 3)
      .map(formatMessageLine);

    const matchedLine = extractMatchedLine(matchedMessage.content);
    if (
      keywordMode &&
      !containsNormalizedKeyword(matchedLine, explicitKeyword) &&
      !containsNormalizedKeyword(matchedMessage.content, explicitKeyword)
    ) {
      continue;
    }

    items.push({
      timestamp: matchedMessage.timestamp,
      sender: matchedMessage.sender,
      matchedLine,
      contextBefore,
      contextAfter,
      role: mapSpeakerToRole(matchedMessage.sender, relationshipContext),
    });
  }

  console.log(
    `[buildEvidencePack] uid=${uid} fallbackUsed=${fallbackUsed} evidenceCount=${items.length} speakerConstraint=${speakerFilter || "none"}`
  );
  return {
    items, query: effectiveQuery, dateHint, dateOnly,
    speakerConstraint: speakerFilter,
    speakerHasNoMatch: speakerHasNoMatch && items.length === 0,
    keywordInOtherSpeaker,
    contextEvidence,
    aliasNeeded: null, aliasOriginalQuery: null,
  };
}

export async function persistParticipantAlias(uid, relationshipId, normAlias, speakerName) {
  await firestore
    .collection("relationships").doc(uid)
    .collection("relations").doc(relationshipId)
    .set({ participantAliases: { [normAlias]: speakerName } }, { merge: true });
}

export async function buildContextWindow(uid, userMessage, options = {}) {
  const snapshot = await getActiveRelationshipSnapshot(uid, options);
  if (!snapshot) {
    return { error: "no_active_relationship" };
  }

  const { relationshipId, relationship } = snapshot;
  const { query, dateHint, dateOnly } = buildSearchQuery(userMessage);

  if (dateHint && isDateOutsideRange(dateHint, relationship?.dateRange)) {
    return { error: "date_out_of_range", dateRange: relationship?.dateRange };
  }

  if (!query) {
    return { items: [], query: "", dateHint, dateOnly, needsTopicHint: dateOnly };
  }

  let chunkIds = [];
  try {
    chunkIds = await semanticSearchChunkIds(uid, relationshipId, query, dateHint);
  } catch (e) {
    console.error(`[${uid}] Semantic chunk search failed:`, e);
    return { items: [], query, dateHint, dateOnly };
  }

  if (!chunkIds.length) {
    return { items: [], query, dateHint, dateOnly };
  }

  const chunkIndex = await fetchChunkIndex(uid, relationshipId, chunkIds[0]);
  if (!chunkIndex?.storagePath) {
    return { items: [], query, dateHint, dateOnly };
  }

  const rawChunk = await getChunkFromStorage(chunkIndex.storagePath);
  const messages = parseChunkMessages(rawChunk);
  if (!messages.length) {
    return { items: [], query, dateHint, dateOnly };
  }

  const messageIndex = findBestMessageIndex(messages, query);
  const startIndex = Math.max(0, messageIndex - 20);
  const endIndex = Math.min(messages.length - 1, messageIndex + 20);
  const lines = messages.slice(startIndex, endIndex + 1).map(formatMessageLine);
  return {
    items: lines,
    query,
    dateHint,
    dateOnly,
  };
}

function buildSearchQuery(message) {
  const safeMessage = message || "";
  const parsedDate = parseMessageDate(safeMessage);
  if (parsedDate) {
    const cleanedMessage = stripCommandWords(
      normalizeText(safeMessage.replaceAll(parsedDate.matchedText, " "))
    );
    const query = normalizeQueryText(cleanedMessage);
    return {
      query,
      dateHint: {
        start: parsedDate.startISO,
        end: parsedDate.endISO,
      },
      dateOnly: !query,
    };
  }

  const normalized = normalizeQueryText(
    stripCommandWords(normalizeText(safeMessage))
  );
  return {
    query: normalized,
    dateHint: null,
    dateOnly: false,
  };
}

function extractExplicitKeywordFromQuery(message) {
  const normalized = normalizeTurkishText(message);
  if (!normalized) return null;

  const patterns = [
    /\b([a-z0-9]+)\s+kelimesi\s+gecen\b/,
    /\b([a-z0-9]+)\s+gecen\s+mesaj(?:lari|ları|lar|lari)?\b/,
    /\b([a-z0-9]+)\s+gecen\b/,
  ];

  for (const pattern of patterns) {
    const match = normalized.match(pattern);
    if (match && match[1]) return match[1];
  }

  return null;
}

function normalizeTurkishText(text) {
  return (text || "")
    .toLowerCase()
    .replace(/ş/g, "s")
    .replace(/ı/g, "i")
    .replace(/ğ/g, "g")
    .replace(/ö/g, "o")
    .replace(/ü/g, "u")
    .replace(/ç/g, "c");
}

function extractActorNameFromQuery(message) {
  const norm = normalizeTurkishText((message || "").trim()).toLowerCase();
  // Third-person trap: name followed by postposition → NOT an actor reference
  if (/^[a-z]{2,}\s*'?\s*(ile|yle|ye|nin|nun|e|a|ya|hakkinda|icin|de|da)\b/.test(norm)) return null;
  // Actor pattern: NAME + agent-verb [mi/mu]
  const m = norm.match(/^([a-z]{2,})\s+(dedi|yazdi|yazmis|soyledi|demis|sordu|sormis|neden|yapti|yapmis)\s*(mi|mu)?/i);
  if (!m) return null;
  const rawName = message.trim().split(/\s+/)[0];
  // Remove "NAME VERB [mi]" from front to get rest-query
  const stripped = norm.replace(/^[a-z]{2,}\s+(dedi|yazdi|yazmis|soyledi|demis|sordu|sormis|neden|yapti|yapmis)\s*(mi|mu)?\s*/i, "");
  return { name: rawName, restQuery: message.trim().slice(message.trim().length - stripped.length) };
}

function containsNormalizedKeyword(text, keyword) {
  if (!text || !keyword) return false;
  const normalizedText = normalizeTurkishText(text);
  const normalizedKeyword = normalizeTurkishText(keyword);
  return normalizedText.includes(normalizedKeyword);
}

function extractMatchedLine(content) {
  const lines = (content || "").split("\n");
  return lines[0]?.trim() || "";
}

function formatMessageLine(message) {
  const content = message.content?.split("\n")[0] || "";
  return `[${message.timestamp}] ${message.sender}: ${content}`;
}

function normalizeText(text) {
  return (text || "").replace(/\s+/g, " ").trim();
}

function normalizeQueryText(text) {
  const cleaned = normalizeText(text || "").replace(/^[:\-–—]+/, "").trim();
  return cleaned.length >= 3 ? cleaned : "";
}

function stripCommandWords(text) {
  let cleaned = text || "";
  const patterns = [
    /\b\d+\s*kanıt\b/gi,
    /\bkanıt\s*ver\b/gi,
    /\bkanıtla\b/gi,
    /\bkanıt\b/gi,
    /\balinti\b/gi,
    /\balıntı\b/gi,
    /\btimestamp\b/gi,
    /\bmesaj(?:lar|ları|ı|i)?\s*(göster|goster|getir)?\b/gi,
    /\bgöster\b/gi,
    /\bgoster\b/gi,
    /\bgetir\b/gi,
    /\bproof\b/gi,
    /\bquote\b/gi,
  ];

  patterns.forEach((pattern) => {
    cleaned = cleaned.replace(pattern, " ");
  });

  return normalizeText(cleaned);
}

async function createEmbeddings(inputs) {
  if (!openai) {
    throw new Error("OpenAI client not configured");
  }

  const response = await openai.embeddings.create({
    model: EMBEDDING_MODEL,
    input: inputs,
  });

  return response.data.map((item) => item.embedding);
}

async function semanticSearchChunkIds(
  uid,
  relationshipId,
  userMessage,
  dateHint,
  matchCount = 12
) {
  const cleanedQuery = normalizeText(userMessage);
  if (!cleanedQuery) return [];

  const [embedding] = await createEmbeddings([
    cleanedQuery.slice(0, MAX_TEXT_LENGTH),
  ]);

  const supabase = getSupabaseClient();
  const { data, error } = await supabase.rpc("match_chunks_v2", {
    match_count: matchCount,
    match_relationship_id: relationshipId,
    match_uid: uid,
    query_embedding: embedding,
    filter_start: dateHint?.start || null,
    filter_end: dateHint?.end || null,
  });

  if (error) {
    throw new Error(`Semantic chunk search failed: ${error.message}`);
  }

  return (data || [])
    .map((row) => row.message_id)
    .filter(Boolean);
}

async function fetchChunkIndex(uid, relationshipId, chunkId) {
  const chunkRef = firestore
    .collection("relationships")
    .doc(uid)
    .collection("relations")
    .doc(relationshipId)
    .collection("chunks")
    .doc(chunkId);

  const doc = await chunkRef.get();
  return doc.exists ? doc.data() : null;
}

async function keywordFallbackChunkIds(
  uid,
  relationshipId,
  query,
  maxChunks = 200,
  maxResults = 20
) {
  const rawTokens = normalizeText(query)
    .toLowerCase()
    .split(/\s+/)
    .filter((w) => w.length >= 3);
  const keywords = rawTokens.filter((w) => !TURKISH_STOPWORDS.has(w));

  if (!keywords.length) return [];

  const chunksSnap = await firestore
    .collection("relationships")
    .doc(uid)
    .collection("relations")
    .doc(relationshipId)
    .collection("chunks")
    .limit(maxChunks)
    .get();

  if (chunksSnap.empty) return [];

  const results = await Promise.allSettled(
    chunksSnap.docs.map(async (doc) => {
      const { storagePath } = doc.data();
      if (!storagePath) return null;
      const text = await getChunkFromStorage(storagePath);
      if (!text) return null;
      const normalized = normalizeText(text).toLowerCase();
      let score = 0;
      for (const kw of keywords) {
        if (normalized.includes(kw)) score += keywordWeight(kw);
      }
      if (score === 0) return null;
      return { chunkId: doc.id, score, chunkText: normalized };
    })
  );

  const candidates = results
    .filter((r) => r.status === "fulfilled" && r.value !== null)
    .map((r) => r.value);

  candidates.sort((a, b) => b.score - a.score);

  // Rare keyword coverage guarantee: words with weight>=3 must appear in top results
  const rareKws = keywords.filter((kw) => keywordWeight(kw) >= 3);
  const top = candidates.slice(0, maxResults);
  const topSet = new Set(top.map((c) => c.chunkId));
  for (const rw of rareKws) {
    if (top.some((c) => c.chunkText.includes(rw))) continue;
    const promoted = candidates.find(
      (c) => !topSet.has(c.chunkId) && c.chunkText.includes(rw)
    );
    if (promoted) {
      top.push(promoted);
      topSet.add(promoted.chunkId);
    }
  }

  return top.slice(0, maxResults).map((c) => c.chunkId);
}

function parseChunkMessages(text) {
  if (!text) return [];
  const lines = text.split("\n");
  const messages = [];
  const pattern = /^\[(.+?)\]\s+([^:]+):\s*(.*)$/;
  let current = null;

  for (const line of lines) {
    const match = line.match(pattern);
    if (match) {
      if (current) messages.push(current);
      current = {
        timestamp: match[1],
        sender: match[2].trim(),
        content: match[3] || "",
      };
    } else if (current) {
      current.content += `\n${line}`;
    }
  }

  if (current) messages.push(current);
  return messages;
}

function findBestMessageIndex(messages, query) {
  if (!messages.length) return 0;
  const normalizedQuery = normalizeText(query);
  if (!normalizedQuery) return Math.floor(messages.length / 2);

  const words = Array.from(
    new Set(
      normalizedQuery
        .toLowerCase()
        .split(/\s+/)
        .filter((word) => word.length >= 3)
    )
  );

  if (!words.length) return Math.floor(messages.length / 2);

  let bestIndex = 0;
  let bestScore = -1;

  messages.forEach((message, index) => {
    const content = normalizeText(message.content).toLowerCase();
    let score = 0;
    words.forEach((word) => {
      if (content.includes(word)) score += 1;
    });
    if (content.includes(normalizedQuery.toLowerCase())) {
      score += 2;
    }
    if (score > bestScore) {
      bestScore = score;
      bestIndex = index;
    }
  });

  if (bestScore <= 0) {
    return Math.floor(messages.length / 2);
  }

  return bestIndex;
}

function normalizeMonthName(text) {
  return (text || "")
    .toLowerCase()
    .replace(/ş/g, "s")
    .replace(/ı/g, "i")
    .replace(/ğ/g, "g")
    .replace(/ö/g, "o")
    .replace(/ü/g, "u")
    .replace(/ç/g, "c");
}

function parseMessageDate(message) {
  const msgLower = (message || "").toLowerCase();

  const monthMap = {
    ocak: 0,
    subat: 1,
    şubat: 1,
    mart: 2,
    nisan: 3,
    mayis: 4,
    mayıs: 4,
    haziran: 5,
    temmuz: 6,
    agustos: 7,
    ağustos: 7,
    eylul: 8,
    eylül: 8,
    ekim: 9,
    kasim: 10,
    kasım: 10,
    aralik: 11,
    aralık: 11,
  };

  const p1 =
    /(\d{1,2})\s*(ocak|şubat|subat|mart|nisan|mayıs|mayis|haziran|temmuz|ağustos|agustos|eylül|eylul|ekim|kasım|kasim|aralık|aralik)\s*(\d{4})?/i;
  const m1 = msgLower.match(p1);
  if (m1) {
    const matchOriginal = message.match(p1);
    const day = parseInt(m1[1], 10);
    const monthName = normalizeMonthName(m1[2]);
    const month = monthMap[monthName];
    const year = m1[3] ? parseInt(m1[3], 10) : new Date().getFullYear();

    const startISO = new Date(year, month, day, 0, 0, 0).toISOString();
    const endISO = new Date(year, month, day, 23, 59, 59).toISOString();

    return {
      matchedText: matchOriginal ? matchOriginal[0] : m1[0],
      displayText: `${day} ${m1[2]} ${year}`,
      startISO,
      endISO,
      confidence: 0.95,
    };
  }

  const p2 =
    /(ocak|şubat|subat|mart|nisan|mayıs|mayis|haziran|temmuz|ağustos|agustos|eylül|eylul|ekim|kasım|kasim|aralık|aralik)\s*(\d{4})/i;
  const m2 = msgLower.match(p2);
  if (m2) {
    const matchOriginal = message.match(p2);
    const monthName = normalizeMonthName(m2[1]);
    const month = monthMap[monthName];
    const year = parseInt(m2[2], 10);

    const startISO = new Date(year, month, 1, 0, 0, 0).toISOString();
    const lastDay = new Date(year, month + 1, 0).getDate();
    const endISO = new Date(year, month, lastDay, 23, 59, 59).toISOString();

    return {
      matchedText: matchOriginal ? matchOriginal[0] : m2[0],
      displayText: `${m2[1]} ${year}`,
      startISO,
      endISO,
      confidence: 0.9,
    };
  }

  const p3 = /(\d{1,2})[\.\/](\d{1,2})[\.\/](\d{2,4})/;
  const m3 = message.match(p3);
  if (m3) {
    let [, day, month, year] = m3;
    day = parseInt(day, 10);
    month = parseInt(month, 10) - 1;
    year = parseInt(year, 10);
    if (year < 100) year += 2000;

    const startISO = new Date(year, month, day, 0, 0, 0).toISOString();
    const endISO = new Date(year, month, day, 23, 59, 59).toISOString();

    return {
      matchedText: m3[0],
      displayText: `${day}.${month + 1}.${year}`,
      startISO,
      endISO,
      confidence: 0.95,
    };
  }

  const p4 = /(\d{4})-(\d{1,2})-(\d{1,2})/;
  const m4 = message.match(p4);
  if (m4) {
    const [, year, month, day] = m4;
    const startISO = new Date(
      parseInt(year, 10),
      parseInt(month, 10) - 1,
      parseInt(day, 10),
      0,
      0,
      0
    ).toISOString();
    const endISO = new Date(
      parseInt(year, 10),
      parseInt(month, 10) - 1,
      parseInt(day, 10),
      23,
      59,
      59
    ).toISOString();

    return {
      matchedText: m4[0],
      displayText: `${day}.${month}.${year}`,
      startISO,
      endISO,
      confidence: 0.95,
    };
  }

  if (/geçen\s*(hafta|ay)/i.test(msgLower)) {
    const matchOriginal = message.match(/geçen\s*(hafta|ay)/i);
    const now = new Date();
    const isWeek = /hafta/.test(msgLower);
    const daysAgo = isWeek ? 7 : 30;

    const endISO = now.toISOString();
    const start = new Date(now);
    start.setDate(start.getDate() - daysAgo);
    const startISO = start.toISOString();

    return {
      matchedText: matchOriginal ? matchOriginal[0] : (isWeek ? "geçen hafta" : "geçen ay"),
      displayText: isWeek ? "geçen hafta" : "geçen ay",
      startISO,
      endISO,
      confidence: 0.7,
    };
  }

  if (/(\d+)\s*(ay|hafta|gün)\s*önce/i.test(msgLower)) {
    const matchOriginal = message.match(/(\d+)\s*(ay|hafta|gün)\s*önce/i);
    const match = msgLower.match(/(\d+)\s*(ay|hafta|gün)\s*önce/i);
    const num = parseInt(match[1], 10);
    const unit = match[2];
    const now = new Date();

    let daysAgo = num;
    if (unit.includes("hafta")) daysAgo *= 7;
    if (unit.includes("ay")) daysAgo *= 30;

    const start = new Date(now);
    start.setDate(start.getDate() - daysAgo);

    return {
      matchedText: matchOriginal ? matchOriginal[0] : match[0],
      displayText: `${num} ${unit} önce`,
      startISO: start.toISOString(),
      endISO: now.toISOString(),
      confidence: 0.6,
    };
  }

  if (/o\s*(gün|gece|akşam|zaman)/i.test(msgLower)) {
    const matchOriginal = message.match(/o\s*(gün|gece|akşam|zaman)/i);
    return {
      matchedText: matchOriginal ? matchOriginal[0] : "o gün",
      displayText: "o gün (belirsiz)",
      startISO: null,
      endISO: null,
      confidence: 0.3,
    };
  }

  return null;
}

// ── Smart Read (Sessiz Okuma) ────────────────────────────────────────────────

async function findSmartReadChunks(uid, relationshipId, query, options = {}) {
  const {
    recentFocus = true,
    dateHint = null,
    maxChunks = 5,
    semanticReady = false,
  } = options;

  let searchDateHint = dateHint;
  let recentFocusUsed = false;

  if (recentFocus && !dateHint) {
    const now = new Date();
    const cutoff = new Date(now);
    cutoff.setDate(cutoff.getDate() - 7);
    searchDateHint = { start: cutoff.toISOString(), end: now.toISOString() };
    recentFocusUsed = true;
  }

  // For "güncelledim" with no query, search for "son mesaj" as proxy
  const effectiveQuery = query || (recentFocus ? "son mesaj" : "");
  if (!effectiveQuery) return { chunkIds: [], finderChunkCount: 0, recentFocusUsed };

  let chunkIds = [];

  if (semanticReady) {
    try {
      chunkIds = await semanticSearchChunkIds(
        uid, relationshipId, effectiveQuery, searchDateHint, maxChunks
      );
      // If recent-focus date filter yielded nothing, retry without date constraint
      if (chunkIds.length === 0 && recentFocusUsed) {
        chunkIds = await semanticSearchChunkIds(
          uid, relationshipId, effectiveQuery, null, maxChunks
        );
        recentFocusUsed = false;
      }
    } catch (e) {
      console.error(`[findSmartReadChunks] semantic failed, keyword fallback:`, e);
      chunkIds = await keywordFallbackChunkIds(uid, relationshipId, effectiveQuery, 200, maxChunks);
      recentFocusUsed = false;
    }
  } else {
    chunkIds = await keywordFallbackChunkIds(uid, relationshipId, effectiveQuery, 200, maxChunks);
  }

  return { chunkIds, finderChunkCount: chunkIds.length, recentFocusUsed };
}

function formatExcerptLine(message) {
  const ts = String(message.timestamp || "");
  const timeMatch = ts.match(/T(\d{2}:\d{2})/);
  const shortTime = timeMatch ? timeMatch[1] : (ts.split("T")[1] || ts).slice(0, 5);
  const content = (message.content || "").split("\n")[0];
  return `[${shortTime}] ${message.sender}: ${content}`;
}

async function buildExcerptWindow(
  uid,
  relationshipId,
  chunkIds,
  query,
  speakerFilter = null,
  targetExcerpts = 12
) {
  const excerptBlocks = [];

  for (const chunkId of chunkIds) {
    if (excerptBlocks.length >= targetExcerpts) break;

    const chunkIndex = await fetchChunkIndex(uid, relationshipId, chunkId);
    if (!chunkIndex?.storagePath) continue;

    const rawChunk = await getChunkFromStorage(chunkIndex.storagePath);
    const messages = parseChunkMessages(rawChunk);
    if (!messages.length) continue;

    const bestIdx = findBestMessageIndex(messages, query);
    const len = messages.length;
    const matchStart = Math.max(0, bestIdx - 8);
    const matchEnd = Math.min(len, bestIdx + 12);

    // Sampling strategy: start + around best match + end, deduped by global index
    const seenIdx = new Set();
    const sampled = [];

    const addSlice = (arr, startGlobal) => {
      arr.forEach((msg, i) => {
        const gi = startGlobal + i;
        if (!seenIdx.has(gi)) {
          seenIdx.add(gi);
          sampled.push({ gi, msg });
        }
      });
    };

    addSlice(messages.slice(0, Math.min(5, len)), 0);
    addSlice(messages.slice(matchStart, matchEnd), matchStart);
    addSlice(messages.slice(Math.max(0, len - 5)), Math.max(0, len - 5));

    sampled.sort((a, b) => a.gi - b.gi);
    const sorted = sampled.map((s) => s.msg);

    // Apply speaker filter: include speaker msgs + ±2 context messages
    let finalMessages = sorted;
    if (speakerFilter) {
      const speakerIdxs = sorted
        .map((m, i) => i)
        .filter((i) => sorted[i].sender === speakerFilter);
      if (speakerIdxs.length === 0) continue; // no speaker msgs in this chunk
      const includeSet = new Set();
      for (const si of speakerIdxs) {
        for (let k = Math.max(0, si - 2); k <= Math.min(sorted.length - 1, si + 2); k++) {
          includeSet.add(k);
        }
      }
      finalMessages = sorted.filter((_, i) => includeSet.has(i));
    }

    if (!finalMessages.length) continue;

    // Group into 3-message blocks
    for (let i = 0; i < finalMessages.length; i += 3) {
      if (excerptBlocks.length >= targetExcerpts) break;
      const group = finalMessages.slice(i, Math.min(i + 3, finalMessages.length));
      excerptBlocks.push(group.map(formatExcerptLine).join("\n"));
    }
  }

  return {
    excerptText: excerptBlocks.join("\n---\n"),
    excerptCount: excerptBlocks.length,
  };
}

export async function buildSmartReadPack(uid, userMessage, options = {}) {
  const { recentFocus = true } = options;

  const snapshot = await getActiveRelationshipSnapshot(uid);
  if (!snapshot) return { error: "no_active_relationship" };

  const { relationshipId, relationshipContext, relationship } = snapshot;
  const { query, dateHint } = buildSearchQuery(userMessage);

  const participantAliases = relationship.participantAliases || {};
  const speakers = relationship.speakers || [];

  // Alias / actor resolution (mirrors buildEvidencePack)
  const actorInfo = extractActorNameFromQuery(userMessage);
  let speakerFilter = null;
  let aliasNeeded = null;
  let aliasOriginalQuery = null;
  let effectiveQuery = query;

  if (actorInfo) {
    const normName = normalizeTurkishText(actorInfo.name).toLowerCase();
    const directMatch = speakers.find(
      (s) => normalizeTurkishText(s).toLowerCase() === normName
    );
    if (directMatch) {
      speakerFilter = directMatch;
    } else if (participantAliases[normName]) {
      speakerFilter = participantAliases[normName];
    } else {
      aliasNeeded = actorInfo.name;
      aliasOriginalQuery = userMessage;
    }
    console.log(
      `[buildSmartReadPack] uid=${uid} speakerFilter=${speakerFilter || "none"} aliasNeeded=${aliasNeeded || "none"}`
    );
    if (speakerFilter && actorInfo.restQuery) {
      effectiveQuery = normalizeQueryText(actorInfo.restQuery) || effectiveQuery;
    }
  }

  if (aliasNeeded) {
    return {
      excerptText: "",
      excerptCount: 0,
      found: 0,
      speakerConstraint: null,
      recentFocus,
      finderChunkCount: 0,
      aliasNeeded,
      aliasOriginalQuery,
    };
  }

  const semanticReady = relationship.semanticIndex?.ready === true;

  const findResult = await findSmartReadChunks(uid, relationshipId, effectiveQuery, {
    recentFocus,
    dateHint,
    semanticReady,
  });

  console.log(
    `[buildSmartReadPack] uid=${uid} finderChunkCount=${findResult.finderChunkCount} recentFocusUsed=${findResult.recentFocusUsed} semanticReady=${semanticReady}`
  );

  if (!findResult.chunkIds.length) {
    return {
      excerptText: "",
      excerptCount: 0,
      found: 0,
      speakerConstraint: speakerFilter,
      recentFocus: findResult.recentFocusUsed,
      finderChunkCount: 0,
      aliasNeeded: null,
      aliasOriginalQuery: null,
    };
  }

  const excerptResult = await buildExcerptWindow(
    uid,
    relationshipId,
    findResult.chunkIds,
    effectiveQuery,
    speakerFilter
  );

  console.log(
    `[buildSmartReadPack] uid=${uid} excerptCount=${excerptResult.excerptCount} speakerFilter=${speakerFilter || "none"}`
  );

  return {
    excerptText: excerptResult.excerptText,
    excerptCount: excerptResult.excerptCount,
    found: excerptResult.excerptCount > 0 ? 1 : 0,
    speakerConstraint: speakerFilter,
    recentFocus: findResult.recentFocusUsed,
    finderChunkCount: findResult.finderChunkCount,
    aliasNeeded: null,
    aliasOriginalQuery: null,
  };
}

