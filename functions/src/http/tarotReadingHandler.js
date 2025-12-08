/**
 * ═══════════════════════════════════════════════════════════════
 * TAROT READING HTTP HANDLER
 * ═══════════════════════════════════════════════════════════════
 * Handles tarot card reading requests
 */

import { auth } from "../config/firebaseAdmin.js";
import { generateTarotReading } from "../services/tarotService.js";
import {
  getUserProfile,
  incrementMessageCount,
} from "../firestore/userProfileRepository.js";
import { hasHitBackendLimit } from "../domain/limitEngine.js";

export async function tarotReadingHandler(req, res) {
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
      console.log(`[TAROT][${uid}] Authenticated request`);
    } catch (err) {
      console.error("Token verification failed:", err);
      return res.status(401).json({
        success: false,
        message: "Geçersiz oturum. Lütfen tekrar giriş yap.",
        code: "INVALID_TOKEN",
      });
    }

    // Body validation
    const { selectedCards } = req.body || {};
    
    if (!selectedCards || !Array.isArray(selectedCards) || selectedCards.length === 0) {
      return res.status(400).json({
        success: false,
        message: "Lütfen en az bir kart seç.",
        code: "INVALID_CARDS",
      });
    }

    // Validate card numbers (Major Arcana: 0-21)
    const validCards = selectedCards.filter(card => 
      typeof card === 'number' && card >= 0 && card <= 21
    );

    if (validCards.length === 0) {
      return res.status(400).json({
        success: false,
        message: "Geçersiz kart seçimi.",
        code: "INVALID_CARD_NUMBERS",
      });
    }

    // User profile
    const userProfile = await getUserProfile(uid);
    const isPremium = userProfile.isPremium === true;

    // Daily backend limit (tarot also counts as message)
    if (hasHitBackendLimit(userProfile, isPremium)) {
      console.log(`[TAROT][${uid}] Daily backend limit hit`);
      return res.status(429).json({
        success: false,
        message: "Günlük mesaj limitine ulaştın. Premium'a geç veya yarın tekrar dene.",
        code: "DAILY_LIMIT_REACHED",
      });
    }

    // Generate tarot reading
    console.log(`[TAROT][${uid}] Generating reading for cards: ${validCards.join(', ')}`);
    const result = await generateTarotReading(uid, validCards, userProfile, isPremium);

    // Increment message count (tarot reading counts as usage)
    incrementMessageCount(uid, userProfile).catch((e) => {
      console.error(`[TAROT][${uid}] Message count increment error:`, e);
    });

    const processingTime = Date.now() - startTime;

    console.log(`[TAROT][${uid}] ✅ Reading generated in ${processingTime}ms`);

    return res.status(200).json({
      success: true,
      reading: result.text,
      cards: result.cards, // Now includes card metadata (id, code, name)
      meta: {
        processingTime,
        isPremium,
        cardCount: validCards.length,
      },
    });
  } catch (err) {
    console.error("🔥 TAROT READING ERROR:", err);

    return res.status(500).json({
      success: false,
      message: "Kanka bir sorun oluştu. Tekrar dener misin?",
      code: "INTERNAL_ERROR",
    });
  }
}
