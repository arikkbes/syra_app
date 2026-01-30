/**
 * ═══════════════════════════════════════════════════════════════
 * SYRA CHAT V2 HANDLER
 * ═══════════════════════════════════════════════════════════════
 * New simplified endpoint aligned with MASTER GUIDE v1.1
 */

import crypto from "crypto";
import { auth } from "../config/firebaseAdmin.js";
import { requireOpenAI } from "../config/openaiClient.js";
import { MODEL_GPT4O } from "../utils/constants.js";
import {
  buildSmartSystemPrompt,
  shouldSearchMessages,
} from "../services/promptBuilder.js";
import {
  getConversationHistory,
  saveConversationHistory,
} from "../firestore/conversationRepository.js";

const MAX_HISTORY = 10;

export async function syraChatV2Handler(req, res) {
  res.set("Access-Control-Allow-Origin", "*");
  res.set("Access-Control-Allow-Headers", "Content-Type, Authorization");
  res.set("Access-Control-Allow-Methods", "POST, OPTIONS");

  if (req.method === "OPTIONS") {
    return res.status(204).send("");
  }

  if (req.method !== "POST") {
    return res.status(405).json({
      success: false,
      message: "Sadece POST metodu kabul edilir.",
      code: "METHOD_NOT_ALLOWED",
    });
  }

  const requestId = crypto.randomUUID();
  const startTime = Date.now();

  try {
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith("Bearer ")) {
      return res.status(401).json({
        success: false,
        message: "Yetkilendirme hatası. Lütfen tekrar giriş yap.",
        code: "UNAUTHORIZED",
      });
    }

    const idToken = authHeader.split("Bearer ")[1];
    let uid;

    try {
      const decoded = await auth.verifyIdToken(idToken);
      uid = decoded.uid;
    } catch (err) {
      console.error("Token verification failed:", err);
      return res.status(401).json({
        success: false,
        message: "Geçersiz oturum. Lütfen tekrar giriş yap.",
        code: "INVALID_TOKEN",
      });
    }

    const {
      message,
      sessionId: rawSessionId,
      conversationHistory,
    } = req.body || {};

    if (!message || typeof message !== "string" || !message.trim()) {
      return res.status(400).json({
        success: false,
        message: "Mesaj boş olamaz.",
        code: "EMPTY_MESSAGE",
      });
    }

    const sessionId = sanitizeSessionId(rawSessionId);
    const history = sanitizeConversationHistory(
      Array.isArray(conversationHistory) ? conversationHistory : []
    );

    const { systemPrompt, meta } = await buildSmartSystemPrompt(
      uid,
      message,
      history
    );

    console.log(
      `syraChatV2 requestId=${requestId} sessionId=${sessionId} deepAnalysis=${meta.deepAnalysis.requested ? "yes" : "no"} evidenceCount=${meta.messageSearch.found} model=${MODEL_GPT4O}`
    );

    const shouldSearch =
      shouldSearchMessages(message) && meta.relationship.hasRelationship;
    if (shouldSearch && meta.messageSearch.found === 0) {
      const safeReply =
        "Aradım ama bulamadım. Tek bir anahtar kelime veya tarih aralığı ver.";

      await persistSessionMessages(uid, sessionId, message.trim(), safeReply, {
        requestId,
        guard: "no_evidence",
      });

      return res.status(200).json({
        success: true,
        message: safeReply,
        meta: {
          requestId,
          sessionId,
          deepAnalysis: meta.deepAnalysis,
          messageSearch: meta.messageSearch,
          relationship: meta.relationship,
          guard: "no_evidence",
          totalProcessingTime: Date.now() - startTime,
        },
      });
    }

    const openai = requireOpenAI();
    const response = await openai.chat.completions.create({
      model: MODEL_GPT4O,
      messages: [
        { role: "system", content: systemPrompt },
        ...history.slice(-MAX_HISTORY),
        { role: "user", content: message.trim() },
      ],
      temperature: 0.7,
    });

    const aiReply = response?.choices?.[0]?.message?.content?.trim() || "";

    if (
      meta.messageSearch.requested &&
      meta.messageSearch.found === 0 &&
      containsTimestampLikePattern(aiReply)
    ) {
      const safeReply =
        "Aradım ama bulamadım. Tek bir anahtar kelime veya tarih aralığı ver.";

      await persistSessionMessages(uid, sessionId, message.trim(), safeReply, {
        requestId,
        guard: "timestamp_blocked_no_evidence",
      });

      return res.status(200).json({
        success: true,
        message: safeReply,
        meta: {
          requestId,
          sessionId,
          deepAnalysis: meta.deepAnalysis,
          messageSearch: meta.messageSearch,
          relationship: meta.relationship,
          guard: "timestamp_blocked_no_evidence",
          totalProcessingTime: Date.now() - startTime,
        },
      });
    }

    await persistSessionMessages(uid, sessionId, message.trim(), aiReply, {
      requestId,
      deepAnalysis: meta.deepAnalysis,
      messageSearch: meta.messageSearch,
    });

    return res.status(200).json({
      success: true,
      message: aiReply || "Kanka bir sorun oldu, tekrar dener misin?",
      meta: {
        requestId,
        sessionId,
        deepAnalysis: meta.deepAnalysis,
        messageSearch: meta.messageSearch,
        relationship: meta.relationship,
        totalProcessingTime: Date.now() - startTime,
      },
    });
  } catch (error) {
    console.error("syraChatV2 error:", error);
    return res.status(500).json({
      success: false,
      message: "Something went wrong, please try again.",
      code: "INTERNAL_ERROR",
    });
  }
}

function sanitizeSessionId(rawSessionId) {
  if (rawSessionId && typeof rawSessionId === "string" && rawSessionId.trim()) {
    let cleanSessionId = rawSessionId.trim().slice(0, 128);
    cleanSessionId = cleanSessionId.replace(/[^a-zA-Z0-9_-]/g, "_");
    return cleanSessionId;
  }
  return "legacy";
}

function sanitizeConversationHistory(conversationHistory) {
  if (!Array.isArray(conversationHistory)) return [];

  return conversationHistory
    .map((entry) => {
      if (!entry || typeof entry !== "object") return null;
      const role = normalizeRole(entry.role);
      const content = typeof entry.content === "string" ? entry.content.trim() : "";
      if (!role || !content) return null;
      return { role, content };
    })
    .filter(Boolean);
}

function normalizeRole(role) {
  if (!role) return null;
  const normalized = String(role).toLowerCase();
  if (normalized === "user" || normalized === "assistant") return normalized;
  return null;
}

function containsTimestampLikePattern(text) {
  if (!text) return false;

  const patterns = [
    /\[\d{1,2}[./]\d{1,2}[./]\d{2,4}\s+\d{1,2}:\d{2}(?::\d{2})?\]/,
    /\[\d{4}-\d{2}-\d{2}t\d{2}:\d{2}:\d{2}/i,
    /\b\d{4}-\d{2}-\d{2}t\d{2}:\d{2}:\d{2}\b/i,
  ];

  return patterns.some((pattern) => pattern.test(text));
}

async function persistSessionMessages(
  uid,
  sessionId,
  userMessage,
  assistantReply,
  assistantMeta
) {
  try {
    const historyData = await getConversationHistory(uid, sessionId);
    await saveConversationHistory(
      uid,
      sessionId,
      userMessage,
      assistantReply,
      historyData,
      assistantMeta
    );
  } catch (e) {
    console.error(`[${uid}] Session save error (sessionId=${sessionId}):`, e);
  }
}
