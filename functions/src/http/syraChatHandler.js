/**
 * ═══════════════════════════════════════════════════════════════
 * SYRA CHAT HTTP HANDLER (FINAL STABLE VERSION)
 * ═══════════════════════════════════════════════════════════════
 * Compatible with Flutter client. Always returns proper JSON:
 * {
 *   success: true/false,
 *   message: "...",
 *   meta: { ... }
 * }
 */

import { auth } from "../config/firebaseAdmin.js";
import { processChat } from "../services/chatOrchestrator.js";
import {
  getUserProfile,
  incrementMessageCount,
} from "../firestore/userProfileRepository.js";
import { hasHitBackendLimit } from "../domain/limitEngine.js";

export async function syraChatHandler(req, res) {
  // Basic CORS
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

  const startTime = Date.now();

  try {
    // Authorization header
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith("Bearer ")) {
      return res.status(401).json({
        success: false,
        message: "Yetkilendirme hatası. Lütfen tekrar giriş yap.",
        code: "UNAUTHORIZED",
      });
    }

    // Decode Firebase token
    const idToken = authHeader.split("Bearer ")[1];
    let uid;

    try {
      const decoded = await auth.verifyIdToken(idToken);
      uid = decoded.uid;
      console.log(`[${uid}] Authenticated request`);
    } catch (err) {
      console.error("Token verification failed:", err);
      return res.status(401).json({
        success: false,
        message: "Geçersiz oturum. Lütfen tekrar giriş yap.",
        code: "INVALID_TOKEN",
      });
    }

    // Body
    const { message, context } = req.body || {};
    if (!message || typeof message !== "string" || !message.trim()) {
      return res.status(400).json({
        success: false,
        message: "Mesaj boş olamaz.",
        code: "EMPTY_MESSAGE",
      });
    }

    // User profile
    const userProfile = await getUserProfile(uid);
    const isPremium = userProfile.isPremium === true;

    // Daily backend limit
    if (hasHitBackendLimit(userProfile, isPremium)) {
      console.log(`[${uid}] Daily backend limit hit`);
      return res.status(429).json({
        success: false,
        message: "Günlük mesaj limitine ulaştın. Premium'a geç veya yarın tekrar dene.",
        code: "DAILY_LIMIT_REACHED",
      });
    }

    // Reply context (optional)
    let replyTo = null;
    if (context && Array.isArray(context)) {
      const replyContext = context.find(
        (x) => x.content && x.content.startsWith("[Replying to:")
      );
      if (replyContext) {
        const match = replyContext.content.match(/\[Replying to: (.+)\]/);
        if (match) replyTo = match[1];
      }
    }

    // MAIN CHAT PROCESSOR
    const result = await processChat(uid, message, replyTo, isPremium);

    // Increase user's message count
    incrementMessageCount(uid, userProfile).catch((e) => {
      console.error(`[${uid}] Message count increment error:`, e);
    });

    // Final response payload (Flutter reads `message`)
    const responsePayload = {
      success: true,
      message: result.reply, // Flutter reads this field
      meta: {
        ...result.meta,
        extractedTraits: result.extractedTraits || null,
        outcomePrediction: result.outcomePrediction || null,
        patterns: result.patterns || null,
        totalProcessingTime: Date.now() - startTime,
      },
    };

    console.log(
      `[${uid}] Success - Response sent in ${Date.now() - startTime}ms`
    );

    return res.status(200).json(responsePayload);
  } catch (err) {
    console.error("🔥 CRITICAL ERROR:", err);

    return res.status(500).json({
      success: false,
      message: "Kanka bir sorun oluştu. Tekrar dener misin?",
      code: "INTERNAL_ERROR",
    });
  }
}
  