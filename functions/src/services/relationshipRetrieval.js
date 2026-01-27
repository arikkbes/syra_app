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
import { getChunkFromStorage, searchChunks } from "./relationshipPipeline.js";
import {
  getActiveRelationshipContext,
  buildParticipantContextPrompt,
  mapSpeakerToRole,
} from "./relationshipContext.js";

const MAX_EVIDENCE_ITEMS = 4;

export async function getActiveRelationshipSnapshot(uid) {
  const relationshipContext = await getActiveRelationshipContext(uid);
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
  if (relationship.isActive === false) {
    return null;
  }

  return {
    relationshipId,
    relationship,
    relationshipContext,
    participantPrompt: buildParticipantContextPrompt(relationshipContext),
  };
}

export async function getRelationshipBrief(uid) {
  const snapshot = await getActiveRelationshipSnapshot(uid);
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

export async function buildEvidencePack(uid, userMessage) {
  const snapshot = await getActiveRelationshipSnapshot(uid);
  if (!snapshot) {
    return { error: "no_active_relationship" };
  }

  const { relationshipId, relationshipContext } = snapshot;
  const { query, dateHint } = buildSearchQuery(userMessage);
  const searchQuery = query || userMessage.slice(0, 100);

  const relevantChunks = await searchChunks(
    uid,
    relationshipId,
    searchQuery,
    dateHint
  );

  if (!relevantChunks.length) {
    return { items: [], query: searchQuery, dateHint };
  }

  const items = [];
  const seen = new Set();

  for (const chunk of relevantChunks) {
    if (items.length >= MAX_EVIDENCE_ITEMS) break;

    const rawContent = await getChunkFromStorage(chunk.storagePath);
    if (!rawContent) continue;

    const messages = parseChunkMessages(rawContent);
    const matches = findMatchingMessageIndexes(messages, searchQuery);

    for (const index of matches) {
      if (items.length >= MAX_EVIDENCE_ITEMS) break;

      const message = messages[index];
      const matchedLine = extractMatchedLine(message.content, searchQuery);
      const key = `${message.timestamp}|${message.sender}|${matchedLine}`;
      if (seen.has(key)) continue;
      seen.add(key);

      const contextBefore = [];
      const contextAfter = [];

      for (let i = Math.max(0, index - 2); i < index; i++) {
        contextBefore.push(formatMessageLine(messages[i]));
      }
      for (let i = index + 1; i <= Math.min(messages.length - 1, index + 2); i++) {
        contextAfter.push(formatMessageLine(messages[i]));
      }

      items.push({
        timestamp: message.timestamp,
        sender: message.sender,
        matchedLine,
        contextBefore,
        contextAfter,
        role: mapSpeakerToRole(message.sender, relationshipContext),
      });
    }
  }

  return { items, query: searchQuery, dateHint };
}

export async function buildContextWindow(uid, userMessage) {
  const snapshot = await getActiveRelationshipSnapshot(uid);
  if (!snapshot) {
    return { error: "no_active_relationship" };
  }

  const { relationshipId } = snapshot;
  const { query, dateHint } = buildSearchQuery(userMessage);
  const searchQuery = query || userMessage.slice(0, 100);

  const relevantChunks = await searchChunks(
    uid,
    relationshipId,
    searchQuery,
    dateHint
  );

  if (!relevantChunks.length) {
    return { items: [], query: searchQuery, dateHint };
  }

  for (const chunk of relevantChunks) {
    const rawContent = await getChunkFromStorage(chunk.storagePath);
    if (!rawContent) continue;

    const messages = parseChunkMessages(rawContent);
    const matches = findMatchingMessageIndexes(messages, searchQuery);
    if (!matches.length) continue;

    const index = matches[0];
    const window = sliceWindow(messages, index, 20, 20, 60);
    const lines = window.map(formatMessageLine);

    return {
      items: lines,
      query: searchQuery,
      dateHint,
      dateRange: chunk.dateRange,
    };
  }

  return { items: [], query: searchQuery, dateHint };
}

function sliceWindow(messages, index, beforeCount, afterCount, maxCount) {
  const total = messages.length;
  let start = Math.max(0, index - beforeCount);
  let end = Math.min(total - 1, index + afterCount);

  let windowSize = end - start + 1;
  if (windowSize < 20) {
    const missing = 20 - windowSize;
    const expandBefore = Math.min(start, Math.ceil(missing / 2));
    const expandAfter = Math.min(total - 1 - end, missing - expandBefore);
    start -= expandBefore;
    end += expandAfter;
    windowSize = end - start + 1;
  }

  if (windowSize > maxCount) {
    end = Math.min(total - 1, start + maxCount - 1);
  }

  return messages.slice(start, end + 1);
}

function buildSearchQuery(message) {
  const parsedDate = parseMessageDate(message);
  if (parsedDate) {
    return {
      query: parsedDate.displayText,
      dateHint: {
        startISO: parsedDate.startISO,
        endISO: parsedDate.endISO,
      },
    };
  }

  return {
    query: extractSearchTerms(message),
    dateHint: null,
  };
}

function parseChunkMessages(rawContent) {
  const lines = rawContent.split("\n");
  const messages = [];
  const pattern = /^\[(.+?)\]\s+([^:]+):\s*(.*)$/;
  let current = null;

  for (const line of lines) {
    const match = line.match(pattern);
    if (match) {
      if (current) messages.push(current);
      const [, timestamp, sender, content] = match;
      current = {
        timestamp: timestamp.trim(),
        sender: sender.trim(),
        content: content.trim(),
      };
    } else if (current && line.trim()) {
      current.content += `\n${line.trim()}`;
    }
  }

  if (current) messages.push(current);
  return messages;
}

function findMatchingMessageIndexes(messages, query) {
  const normalizedQuery = normalizeTurkish(query || "");
  const tokens = normalizedQuery.split(/\s+/).filter((t) => t.length > 2);
  const matches = [];

  messages.forEach((message, index) => {
    const normalizedText = normalizeTurkish(message.content || "");
    const hit =
      (normalizedQuery && normalizedText.includes(normalizedQuery)) ||
      tokens.some((t) => normalizedText.includes(t));

    if (hit) {
      matches.push(index);
    }
  });

  return matches;
}

function extractMatchedLine(content, query) {
  const normalizedQuery = normalizeTurkish(query || "");
  const tokens = normalizedQuery.split(/\s+/).filter((t) => t.length > 2);
  const lines = content.split("\n");

  for (const line of lines) {
    const normalizedLine = normalizeTurkish(line);
    if (
      (normalizedQuery && normalizedLine.includes(normalizedQuery)) ||
      tokens.some((t) => normalizedLine.includes(t))
    ) {
      return line.trim();
    }
  }

  return lines[0]?.trim() || content.trim();
}

function formatMessageLine(message) {
  const content = message.content?.split("\n")[0] || "";
  return `[${message.timestamp}] ${message.sender}: ${content}`;
}

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

function parseMessageDate(message) {
  const msgLower = message.toLowerCase();

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
    const day = parseInt(m1[1], 10);
    const monthName = normalizeTurkish(m1[2]);
    const month = monthMap[monthName];
    const year = m1[3] ? parseInt(m1[3], 10) : new Date().getFullYear();

    const startISO = new Date(year, month, day, 0, 0, 0).toISOString();
    const endISO = new Date(year, month, day, 23, 59, 59).toISOString();

    return {
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
    const monthName = normalizeTurkish(m2[1]);
    const month = monthMap[monthName];
    const year = parseInt(m2[2], 10);

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
      displayText: `${day}.${month}.${year}`,
      startISO,
      endISO,
      confidence: 0.95,
    };
  }

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
    const num = parseInt(match[1], 10);
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

function extractSearchTerms(message) {
  const stopWords = [
    "ne",
    "neden",
    "nasıl",
    "kim",
    "ne zaman",
    "nerede",
    "bir",
    "bu",
    "şu",
    "o",
    "ve",
    "veya",
    "ile",
    "için",
    "mı",
    "mi",
    "mu",
    "mü",
    "mısın",
    "misin",
    "musun",
    "müsün",
    "miyim",
    "mıyım",
    "müyüm",
    "miyim",
    "var",
    "yok",
    "değil",
    "evet",
    "hayır",
    "ben",
    "sen",
    "biz",
    "siz",
    "onlar",
    "bana",
    "sana",
    "bize",
    "size",
    "dedi",
    "demişti",
    "söyledi",
    "yazdı",
    "ya",
    "kanka",
    "abi",
    "abla",
  ];

  const allTokens = message
    .toLowerCase()
    .replace(/[^\wğüşıöçĞÜŞİÖÇ\s\-_0-9]/g, " ")
    .split(/\s+/)
    .filter((w) => w.length > 2);

  const specialTokens = allTokens.filter((token) => {
    if (/^[a-z]{4,}$/i.test(token)) return true;
    if (/\d/.test(token)) return true;
    if (/[-_]/.test(token)) return true;
    return false;
  });

  const meaningfulTerms = allTokens.filter((w) => !stopWords.includes(w));
  const combined = [...new Set([...specialTokens, ...meaningfulTerms.slice(0, 8)])];
  const finalQuery = combined.join(" ").trim();

  if (!finalQuery) {
    return message.toLowerCase().replace(/[^\wğüşıöçĞÜŞİÖÇ\s]/g, " ").trim();
  }

  return finalQuery;
}
