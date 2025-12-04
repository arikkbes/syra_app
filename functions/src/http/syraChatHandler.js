/**
 * ═══════════════════════════════════════════════════════════════
 * SYRA CHAT HTTP HANDLER
 * ═══════════════════════════════════════════════════════════════
 * Pure HTTP handler for SYRA chat endpoint
 */

import { auth } from "../config/firebaseAdmin.js";
import { processChat } from "../services/chatOrchestrator.js";
import {
  getUserProfile,
  incrementMessageCount,
} from "../firestore/userProfileRepository.js";
import { hasHitBackendLimit } from "../domain/limitEngine.js";

/**
 * Main SYRA chat handler
 * Compatible with Flutter lib/services/chat_service.dart
 */
export async function syraChatHandler(req, res) {
  res.set("Access-Control-Allow-Origin", "*");
  res.set("Access-Control-Allow-Headers", "Content-Type, Authorization");
  res.set("Access-Control-Allow-Methods", "POST, OPTIONS");

  if (req.method === "OPTIONS") {
    return res.status(204).send("");
  }

  if (req.method !== "POST") {
    return res.status(405).json({
      message: "Sadece POST metodu kabul edilir.",
      code: "METHOD_NOT_ALLOWED",
    });
  }

  const startTime = Date.now();

  try {
    const authHeader = req.headers.authorization;

    if (!authHeader || !authHeader.startsWith("Bearer ")) {
      return res.status(401).json({
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
        message: "Geçersiz oturum. Lütfen tekrar giriş yap.",
        code: "INVALID_TOKEN",
      });
    }

    const { message, context } = req.body || {};

    if (!message || typeof message !== "string" || message.trim().length === 0) {
      return res.status(400).json({
        message: "Mesaj boş olamaz.",
        code: "EMPTY_MESSAGE",
      });
    }

    const userProfile = await getUserProfile(uid);
    const isPremium = userProfile.isPremium === true;

    if (hasHitBackendLimit(userProfile, isPremium)) {
      console.log(`[${uid}] Backend limit hit - ${userProfile.backendMessageCount}`);
      return res.status(429).json({
        message: "Günlük mesaj limitine ulaştın. Premium'a geç veya yarın tekrar dene.",
        code: "DAILY_LIMIT_REACHED",
      });
    }

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

    const result = await processChat(uid, message, replyTo, isPremium);

    incrementMessageCount(uid, userProfile).catch((e) => {
      console.error(`[${uid}] Error incrementing count:`, e);
    });

    // Flutter client expects 'message' field (not 'reply' or 'response')
    const responsePayload = {
      message: result.reply,
      meta: {
        ...result.meta,
        extractedTraits: result.extractedTraits,
        outcomePrediction: result.outcomePrediction,
        patterns: result.patterns,
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
      message: "Kanka bir sorun oluştu. Tekrar dener misin?",
      code: "INTERNAL_ERROR",
      details:
        process.env.NODE_ENV === "development"
          ? String(e).slice(0, 300)
          : undefined,
    });
  }
}
