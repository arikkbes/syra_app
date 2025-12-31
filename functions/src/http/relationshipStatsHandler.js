/**
 * ═══════════════════════════════════════════════════════════════
 * RELATIONSHIP STATS HANDLER
 * ═══════════════════════════════════════════════════════════════
 * Returns "Who More?" stats from the latest relationship memory
 */

import { auth, db as firestore } from "../config/firebaseAdmin.js";

/**
 * Map speaker name to user/partner/balanced/none
 * @param {string} speakerName - Winner speaker name from stats
 * @param {string} selfParticipant - User's selected participant name
 * @param {string} partnerParticipant - Partner's participant name
 * @returns {string} - "user", "partner", "balanced", "none", or speaker name
 */
function mapSpeakerToRole(speakerName, selfParticipant, partnerParticipant) {
  if (!speakerName || speakerName === "none") {
    return "none";
  }
  
  if (speakerName === "balanced") {
    return "balanced";
  }
  
  // If selfParticipant is set, map to user/partner
  if (selfParticipant) {
    if (speakerName === selfParticipant) {
      return "user";
    }
    if (partnerParticipant && speakerName === partnerParticipant) {
      return "partner";
    }
  }
  
  // Return raw speaker name if no mapping available
  return speakerName;
}

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

    // ═══════════════════════════════════════════════════════════════
    // NEW V2 STRUCTURE: Fetch active relationship from new Firestore path
    // ═══════════════════════════════════════════════════════════════
    
    console.log(`[${uid}] Fetching active relationship from V2 structure...`);
    
    let relationshipDoc = null;
    let relationshipId = null;
    
    try {
      // Step 1: Check user's activeRelationshipId
      const userDocRef = firestore.collection("users").doc(uid);
      const userDoc = await userDocRef.get();
      
      if (userDoc.exists) {
        const userData = userDoc.data();
        relationshipId = userData?.activeRelationshipId;
        
        if (relationshipId) {
          console.log(`[${uid}] Found activeRelationshipId: ${relationshipId}`);
          
          // Fetch the relationship document
          const relationshipRef = firestore
            .collection("relationships")
            .doc(uid)
            .collection("relations")
            .doc(relationshipId);
          
          const relSnap = await relationshipRef.get();
          
          if (relSnap.exists) {
            relationshipDoc = relSnap.data();
            console.log(`[${uid}] Successfully fetched relationship doc`);
          } else {
            console.log(`[${uid}] activeRelationshipId exists but doc not found`);
          }
        }
      }
      
      // Step 2: Fallback - query for active relationship
      if (!relationshipDoc) {
        console.log(`[${uid}] No activeRelationshipId, querying for active relationship...`);
        
        const relationsRef = firestore
          .collection("relationships")
          .doc(uid)
          .collection("relations")
          .where("isActive", "==", true)
          .orderBy("updatedAt", "desc")
          .limit(1);
        
        const querySnap = await relationsRef.get();
        
        if (!querySnap.empty) {
          relationshipDoc = querySnap.docs[0].data();
          relationshipId = querySnap.docs[0].id;
          console.log(`[${uid}] Found active relationship via query: ${relationshipId}`);
        }
      }
      
      // Step 3: Final fallback - check legacy relationship_memory
      if (!relationshipDoc) {
        console.log(`[${uid}] No V2 relationship found, checking legacy...`);
        
        const legacyRef = firestore.collection("relationship_memory").doc(uid);
        const legacySnap = await legacyRef.get();
        
        if (legacySnap.exists) {
          console.log(`[${uid}] Found legacy relationship_memory, migrating response...`);
          const legacyMem = legacySnap.data();
          
          // Map legacy format to new response format
          const statsData = legacyMem?.stats || {
            whoSentMoreMessages: "balanced",
            whoSaidILoveYouMore: "none",
            whoApologizedMore: "none",
            whoUsedMoreEmojis: "none",
          };
          
          return res.status(200).json({
            success: true,
            stats: statsData,
            summary: legacyMem?.shortSummary || null,
            dateRange: {
              startDate: legacyMem?.startDate || null,
              endDate: legacyMem?.endDate || null,
            },
            isActive: legacyMem?.isActive !== false,
            lastUploadAt: legacyMem?.lastUploadAt || null,
          });
        }
        
        // No relationship found at all
        console.log(`[${uid}] No relationship memory found (V2 or legacy)`);
        return res.status(200).json({
          success: false,
          reason: "no_relationship_memory",
        });
      }
      
      // ═══════════════════════════════════════════════════════════════
      // Process V2 relationship document
      // ═══════════════════════════════════════════════════════════════
      
      console.log(`[${uid}] Processing V2 relationship document...`);
      
      // Extract stats (if available)
      const statsBySpeaker = relationshipDoc.statsBySpeaker || {};
      const selfParticipant = relationshipDoc.selfParticipant;
      const partnerParticipant = relationshipDoc.partnerParticipant;
      
      // Map speaker-based stats to user/partner format
      const statsData = {
        whoSentMoreMessages: mapSpeakerToRole(
          statsBySpeaker.whoSentMoreMessages,
          selfParticipant,
          partnerParticipant
        ),
        whoSaidILoveYouMore: mapSpeakerToRole(
          statsBySpeaker.whoSaidILoveYouMore,
          selfParticipant,
          partnerParticipant
        ),
        whoApologizedMore: mapSpeakerToRole(
          statsBySpeaker.whoApologizedMore,
          selfParticipant,
          partnerParticipant
        ),
        whoUsedMoreEmojis: mapSpeakerToRole(
          statsBySpeaker.whoUsedMoreEmojis,
          selfParticipant,
          partnerParticipant
        ),
      };
      
      // Extract other fields
      const summary = relationshipDoc.masterSummary?.shortSummary || null;
      const dateRange = {
        startDate: relationshipDoc.dateRange?.start || null,
        endDate: relationshipDoc.dateRange?.end || null,
      };
      const isActive = relationshipDoc.isActive !== false;
      const lastUploadAt = relationshipDoc.updatedAt || relationshipDoc.createdAt || null;
      
      console.log(`[${uid}] Returning V2 response (isActive: ${isActive})`);
      
      return res.status(200).json({
        success: true,
        stats: statsData,
        summary,
        dateRange,
        isActive,
        lastUploadAt,
      });
      
    } catch (firestoreError) {
      console.error(`[${uid}] Firestore fetch error:`, firestoreError);
      return res.status(500).json({
        success: false,
        message: "Database read error",
        details: firestoreError.message,
      });
    }

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
