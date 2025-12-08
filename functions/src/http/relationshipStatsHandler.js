/**
 * ═══════════════════════════════════════════════════════════════
 * RELATIONSHIP STATS HANDLER
 * ═══════════════════════════════════════════════════════════════
 * Returns "Who More?" stats from the latest relationship memory
 */

import { auth, db as firestore } from "../config/firebaseAdmin.js";

export async function relationshipStatsHandler(req, res) {
  // CORS
  res.set("Access-Control-Allow-Origin", "*");
  res.set("Access-Control-Allow-Headers", "Content-Type, Authorization");
  res.set("Access-Control-Allow-Methods", "GET, OPTIONS");

  if (req.method === "OPTIONS") {
    return res.status(204).send("");
  }

  if (req.method !== "GET") {
    return res.status(405).json({
      success: false,
      message: "Sadece GET metodu kabul edilir.",
    });
  }

  let uid = "unknown";

  try {
    // Verify authentication
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith("Bearer ")) {
      console.error("Missing or invalid authorization header");
      return res.status(401).json({
        success: false,
        message: "Yetkilendirme hatası.",
      });
    }

    const idToken = authHeader.split("Bearer ")[1];

    try {
      const decoded = await auth.verifyIdToken(idToken);
      uid = decoded.uid;
      console.log(`[${uid}] Relationship stats request received`);
    } catch (err) {
      console.error("Token verification failed:", err);
      return res.status(401).json({
        success: false,
        message: "Geçersiz oturum.",
      });
    }

    // CRITICAL: Ensure firestore is available
    if (!firestore) {
      console.error(`[${uid}] Firestore instance is null!`);
      return res.status(500).json({
        success: false,
        message: "Database connection error",
      });
    }

    // Fetch relationship memory with defensive checks
    console.log(`[${uid}] Attempting to fetch relationship_memory/${uid}`);
    
    let memorySnap;
    try {
      const memoryRef = firestore.collection("relationship_memory").doc(uid);
      memorySnap = await memoryRef.get();
      console.log(`[${uid}] Firestore fetch completed, exists: ${memorySnap.exists}`);
    } catch (firestoreError) {
      console.error(`[${uid}] Firestore fetch error:`, firestoreError);
      return res.status(500).json({
        success: false,
        message: "Database read error",
        details: firestoreError.message,
      });
    }

    if (!memorySnap.exists) {
      console.log(`[${uid}] No relationship memory found (this is normal for first-time users)`);
      return res.status(200).json({
        success: false,
        reason: "no_relationship_memory",
      });
    }

    const mem = memorySnap.data();
    console.log(`[${uid}] Memory data retrieved, fields:`, Object.keys(mem || {}));
    console.log(`[${uid}] Has stats field: ${!!mem?.stats}`);

    // Defensive stats object
    const statsData = mem?.stats || {
      whoSentMoreMessages: "balanced",
      whoSaidILoveYouMore: "none",
      whoApologizedMore: "none",
      whoUsedMoreEmojis: "none",
    };

    // Determine isActive status
    // If explicitly false, return false; otherwise default to true
    const isActive = mem?.isActive === false ? false : true;

    // Build response with extended metadata
    const response = {
      success: true,
      stats: statsData,
      summary: mem?.shortSummary || null,
      dateRange: {
        startDate: mem?.startDate || null,
        endDate: mem?.endDate || null,
      },
      isActive,
      lastUploadAt: mem?.lastUploadAt || null,
    };

    console.log(`[${uid}] Returning successful response (isActive: ${isActive})`);
    return res.status(200).json(response);

  } catch (error) {
    console.error(`[${uid}] FATAL ERROR in relationshipStatsHandler:`, error);
    console.error(`[${uid}] Error type:`, error.constructor.name);
    console.error(`[${uid}] Error message:`, error.message);
    console.error(`[${uid}] Error stack:`, error.stack);
    
    // Return error response
    return res.status(500).json({
      success: false,
      message: "Internal server error",
      error: error.message,
      errorType: error.constructor.name,
    });
  }
}
