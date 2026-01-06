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
    const { message, context, imageUrl, mode, tarotContext, sessionId: rawSessionId } = req.body || {};
    
    // ═══════════════════════════════════════════════════════════════
    // MODULE 1: Session ID validation and sanitization
    // ═══════════════════════════════════════════════════════════════
    let sessionId = "legacy"; // Default fallback
    
    if (rawSessionId && typeof rawSessionId === "string" && rawSessionId.trim()) {
      // Trim to max 128 chars
      let cleanSessionId = rawSessionId.trim().slice(0, 128);
      
      // Sanitize: only allow [a-zA-Z0-9_-]
      cleanSessionId = cleanSessionId.replace(/[^a-zA-Z0-9_-]/g, "_");
      
      sessionId = cleanSessionId;
      console.log(`[${uid}] Session ID: ${sessionId}`);
    } else {
      console.log(`[${uid}] No session ID provided, using 'legacy'`);
    }
    
    if (!message || typeof message !== "string" || !message.trim()) {
      // Eğer sadece resim gönderilmişse ve text yoksa, default mesaj
      if (imageUrl) {
        // İzin ver, default mesajla devam
      } else {
        return res.status(400).json({
          success: false,
          message: "Mesaj boş olamaz.",
          code: "EMPTY_MESSAGE",
        });
      }
    }

    // Validate mode
    const validMode = ['standard', 'deep', 'mentor'].includes(mode) ? mode : 'standard';
    
    // Tarot context (if this is a follow-up question about a tarot reading)
    const hasTarotContext = tarotContext && typeof tarotContext === 'string' && tarotContext.trim();
    if (hasTarotContext) {
      console.log(`[${uid}] Tarot follow-up question detected`);
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
    const result = await processChat(
      uid,
      sessionId, // MODULE 1: Pass sessionId
      message, 
      replyTo, 
      isPremium, 
      imageUrl, 
      validMode,
      hasTarotContext ? tarotContext : null
    );

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