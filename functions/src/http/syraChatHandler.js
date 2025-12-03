/**
 * ═══════════════════════════════════════════════════════════════
 * SYRA CHAT HTTP HANDLER - FIXED
 * ═══════════════════════════════════════════════════════════════
 * ✅ Now accepts mode, tone, messageLength from frontend
 */

import { auth } from "../config/firebaseAdmin.js";
import { processChat } from "../services/chatOrchestrator.js";
import {
  getUserProfile,
  incrementMessageCount,
} from "../firestore/userProfileRepository.js";
import { hasHitBackendLimit } from "../domain/limitEngine.js";

export async function syraChatHandler(req, res) {
  // -------------------------------------------------------------------------
  // CORS HANDLING
  // -------------------------------------------------------------------------
  res.set("Access-Control-Allow-Origin", "*");
  res.set("Access-Control-Allow-Headers", "Content-Type, Authorization");
  res.set("Access-Control-Allow-Methods", "POST, OPTIONS");

  if (req.method === "OPTIONS") {
    return res.status(204).send("");
  }

  // -------------------------------------------------------------------------
  // METHOD CHECK
  // -------------------------------------------------------------------------
  if (req.method !== "POST") {
    return res.status(405).json({
      error: true,
      message: "Sadece POST metodu kabul edilir.",
      code: "METHOD_NOT_ALLOWED",
    });
  }

  const startTime = Date.now();

  try {
    // -----------------------------------------------------------------------
    // AUTHENTICATION - Firebase ID Token
    // -----------------------------------------------------------------------
    const authHeader = req.headers.authorization;

    if (!authHeader || !authHeader.startsWith("Bearer ")) {
      return res.status(401).json({
        error: true,
        message: "Yetkilendirme hatası. Lütfen tekrar giriş yap.",
        code: "UNAUTHORIZED",
      });
    }

    const idToken = authHeader.split("Bearer ")[1];
    let uid;

    try {
      const decodedToken = await auth.verifyIdToken(idToken);
      uid = decodedToken.uid;
      console.log(`[${uid}] Authenticated request`);
    } catch (e) {
      console.error("Token verification failed:", e);
      return res.status(401).json({
        error: true,
        message: "Geçersiz oturum. Lütfen tekrar giriş yap.",
        code: "INVALID_TOKEN",
      });
    }

    // -----------------------------------------------------------------------
    // REQUEST VALIDATION
    // -----------------------------------------------------------------------
    const { 
      message, 
      context,
      mode = 'default',
      tone = 'default',
      messageLength = 'default',
    } = req.body || {};

    if (!message || typeof message !== "string" || message.trim().length === 0) {
      return res.status(400).json({
        error: true,
        message: "Mesaj boş olamaz.",
        code: "EMPTY_MESSAGE",
      });
    }

    console.log(`[${uid}] Request params - Mode: ${mode}, Tone: ${tone}, Length: ${messageLength}`);

    // -----------------------------------------------------------------------
    // LOAD USER PROFILE & CHECK LIMITS
    // -----------------------------------------------------------------------
    const userProfile = await getUserProfile(uid);
    const isPremium = userProfile.isPremium === true;

    // Check backend daily limit (only for free users)
    if (hasHitBackendLimit(userProfile, isPremium)) {
      console.log(`[${uid}] Backend limit hit - ${userProfile.backendMessageCount}`);
      return res.status(429).json({
        error: true,
        message: "Günlük mesaj limitine ulaştın. Premium'a geç veya yarın tekrar dene.",
        code: "RATE_LIMIT_EXCEEDED",
      });
    }

    // -----------------------------------------------------------------------
    // EXTRACT REPLY CONTEXT (if replying to a message)
    // -----------------------------------------------------------------------
    let replyTo = null;
    if (context && Array.isArray(context) && context.length > 0) {
      const replyContext = context.find(
        (msg) => msg.content && msg.content.startsWith("[Replying to:")
      );
      if (replyContext) {
        const match = replyContext.content.match(/\[Replying to: (.+)\]/);
        if (match) {
          replyTo = match[1];
        }
      }
    }

    // -----------------------------------------------------------------------
    // PROCESS CHAT WITH ORCHESTRATOR
    // -----------------------------------------------------------------------
    // Pass mode, tone, messageLength to chatOrchestrator
    const result = await processChat(
      uid, 
      message, 
      replyTo, 
      isPremium,
      mode,
      tone,
      messageLength
    );

    // -----------------------------------------------------------------------
    // INCREMENT MESSAGE COUNT
    // -----------------------------------------------------------------------
    incrementMessageCount(uid, userProfile).catch((e) => {
      console.error(`[${uid}] Error incrementing count:`, e);
    });

    // -----------------------------------------------------------------------
    // SEND RESPONSE
    // -----------------------------------------------------------------------
    const responsePayload = {
      response: result.reply,
      extractedTraits: result.extractedTraits,
      outcomePrediction: result.outcomePrediction,
      patterns: result.patterns,
      meta: {
        ...result.meta,
        mode,
        tone,
        messageLength,
        totalProcessingTime: Date.now() - startTime,
      },
    };

    console.log(
      `[${uid}] Success - Response sent in ${Date.now() - startTime}ms`
    );

    return res.status(200).json(responsePayload);
  } catch (e) {
    console.error("🔥 CRITICAL ERROR:", e);

    return res.status(500).json({
      error: true,
      message: "Kanka bir sorun oluştu. Tekrar dener misin?",
      code: "INTERNAL_ERROR",
      details:
        process.env.NODE_ENV === "development"
          ? String(e).slice(0, 300)
          : undefined,
    });
  }
}
