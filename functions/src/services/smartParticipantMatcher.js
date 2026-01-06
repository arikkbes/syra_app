/**
 * ═══════════════════════════════════════════════════════════════
 * SMART PARTICIPANT MATCHER
 * ═══════════════════════════════════════════════════════════════
 * Intelligently matches new relationship speakers with previous
 * selfParticipant history to improve UX
 * ═══════════════════════════════════════════════════════════════
 */

import { db as firestore } from "../config/firebaseAdmin.js";

/**
 * Find previous selfParticipant values from user's relationship history
 * @param {string} uid - User ID
 * @returns {Promise<Array<string>>} - Array of previous selfParticipant names
 */
async function getPreviousSelfParticipants(uid) {
  try {
    const relationsSnapshot = await firestore
      .collection("relationships")
      .doc(uid)
      .collection("relations")
      .where("selfParticipant", "!=", null)
      .orderBy("selfParticipant")
      .orderBy("updatedAt", "desc")
      .limit(10) // Get last 10 relationships
      .get();

    const selfParticipants = new Set();
    relationsSnapshot.docs.forEach(doc => {
      const sp = doc.data().selfParticipant;
      if (sp) selfParticipants.add(sp.trim().toLowerCase());
    });

    return Array.from(selfParticipants);
  } catch (e) {
    console.error(`getPreviousSelfParticipants error:`, e);
    return [];
  }
}

/**
 * Find previous partnerParticipant values from user's relationship history
 * @param {string} uid - User ID
 * @returns {Promise<Array<string>>} - Array of previous partnerParticipant names
 */
async function getPreviousPartnerParticipants(uid) {
  try {
    const relationsSnapshot = await firestore
      .collection("relationships")
      .doc(uid)
      .collection("relations")
      .where("partnerParticipant", "!=", null)
      .orderBy("partnerParticipant")
      .orderBy("updatedAt", "desc")
      .limit(10)
      .get();

    const partnerParticipants = new Set();
    relationsSnapshot.docs.forEach(doc => {
      const pp = doc.data().partnerParticipant;
      if (pp) partnerParticipants.add(pp.trim().toLowerCase());
    });

    return Array.from(partnerParticipants);
  } catch (e) {
    console.error(`getPreviousPartnerParticipants error:`, e);
    return [];
  }
}

/**
 * Calculate similarity between two strings (0-1 scale)
 * Uses Levenshtein distance normalized
 */
function calculateSimilarity(str1, str2) {
  const s1 = str1.toLowerCase().trim();
  const s2 = str2.toLowerCase().trim();

  // Exact match
  if (s1 === s2) return 1.0;

  // One contains the other
  if (s1.includes(s2) || s2.includes(s1)) {
    const minLen = Math.min(s1.length, s2.length);
    const maxLen = Math.max(s1.length, s2.length);
    return minLen / maxLen; // e.g., "Veysel" vs "Veyso" = 5/6 = 0.83
  }

  // Levenshtein distance
  const distance = levenshteinDistance(s1, s2);
  const maxLen = Math.max(s1.length, s2.length);
  const similarity = 1 - (distance / maxLen);

  return Math.max(0, similarity);
}

/**
 * Levenshtein distance algorithm
 */
function levenshteinDistance(str1, str2) {
  const m = str1.length;
  const n = str2.length;
  const dp = Array(m + 1).fill(null).map(() => Array(n + 1).fill(0));

  for (let i = 0; i <= m; i++) dp[i][0] = i;
  for (let j = 0; j <= n; j++) dp[0][j] = j;

  for (let i = 1; i <= m; i++) {
    for (let j = 1; j <= n; j++) {
      if (str1[i - 1] === str2[j - 1]) {
        dp[i][j] = dp[i - 1][j - 1];
      } else {
        dp[i][j] = Math.min(
          dp[i - 1][j] + 1,     // deletion
          dp[i][j - 1] + 1,     // insertion
          dp[i - 1][j - 1] + 1  // substitution
        );
      }
    }
  }

  return dp[m][n];
}

/**
 * Find best match for new speakers from previous history
 * @param {Array<string>} newSpeakers - Speakers from new upload
 * @param {string} uid - User ID
 * @returns {Promise<Object>} - { matched: string|null, similarity: number, matchType: string }
 */
export async function findBestParticipantMatch(newSpeakers, uid) {
  if (!newSpeakers || newSpeakers.length === 0) {
    return { matched: null, similarity: 0, matchType: "none" };
  }

  // Get previous selfParticipants
  const previousSelfParticipants = await getPreviousSelfParticipants(uid);
  
  if (previousSelfParticipants.length === 0) {
    console.log(`[${uid}] No previous selfParticipants found`);
    return { matched: null, similarity: 0, matchType: "none" };
  }

  console.log(`[${uid}] Previous selfParticipants:`, previousSelfParticipants);
  console.log(`[${uid}] New speakers:`, newSpeakers);

  // Find best match
  let bestMatch = null;
  let bestSimilarity = 0;
  let bestSpeaker = null;

  for (const newSpeaker of newSpeakers) {
    for (const prevSelf of previousSelfParticipants) {
      const similarity = calculateSimilarity(newSpeaker, prevSelf);
      
      if (similarity > bestSimilarity) {
        bestSimilarity = similarity;
        bestMatch = prevSelf;
        bestSpeaker = newSpeaker;
      }
    }
  }

  // Determine match type based on similarity
  let matchType = "none";
  if (bestSimilarity >= 0.95) {
    matchType = "exact"; // %95+ = otomatik ata
  } else if (bestSimilarity >= 0.70) {
    matchType = "similar"; // %70-94 = onay iste
  } else {
    matchType = "none"; // <%70 = sor
  }

  console.log(`[${uid}] Best match: "${bestSpeaker}" ≈ "${bestMatch}" (${(bestSimilarity * 100).toFixed(1)}%, type: ${matchType})`);

  return {
    matched: bestSpeaker, // New speaker name from upload
    previousName: bestMatch, // Previous name from history
    similarity: bestSimilarity,
    matchType: matchType,
  };
}

/**
 * Apply smart participant matching to new relationship
 * @param {string} uid - User ID
 * @param {string} relationshipId - New relationship ID
 * @param {Array<string>} speakers - Speakers from new upload
 * @returns {Promise<Object>} - Match result with action taken
 */
export async function applySmartParticipantMatching(uid, relationshipId, speakers) {
  const matchResult = await findBestParticipantMatch(speakers, uid);

  if (matchResult.matchType === "exact") {
    // Auto-assign (95%+ match)
    console.log(`[${uid}] Auto-assigning selfParticipant: ${matchResult.matched}`);
    
    // Find partner (the other speaker)
    const otherSpeaker = speakers.find(s => s !== matchResult.matched) || null;
    
    // Try to match partner from history
    let finalPartnerParticipant = otherSpeaker;
    let partnerNameChanged = false;
    let previousPartnerName = null;
    
    if (otherSpeaker) {
      const previousPartners = await getPreviousPartnerParticipants(uid);
      let bestPartnerMatch = null;
      let bestPartnerSimilarity = 0;
      
      for (const prevPartner of previousPartners) {
        const similarity = calculateSimilarity(otherSpeaker, prevPartner);
        if (similarity > bestPartnerSimilarity) {
          bestPartnerSimilarity = similarity;
          bestPartnerMatch = prevPartner;
        }
      }
      
      // If partner name is different but refers to same person (e.g., "Aşkım" → "Sevgilim")
      if (bestPartnerMatch && bestPartnerSimilarity >= 0.60 && bestPartnerSimilarity < 0.95) {
        // Partner name changed (different name, same person)
        partnerNameChanged = true;
        previousPartnerName = bestPartnerMatch;
        console.log(`[${uid}] Partner name changed: "${bestPartnerMatch}" → "${otherSpeaker}" (${(bestPartnerSimilarity * 100).toFixed(0)}%)`);
      } else if (bestPartnerMatch && bestPartnerSimilarity < 0.60) {
        // Completely different partner (e.g., switching from one relationship to another)
        console.log(`[${uid}] Different partner: "${bestPartnerMatch}" vs "${otherSpeaker}" (${(bestPartnerSimilarity * 100).toFixed(0)}%)`);
      }
    }
    
    const updateData = {
      selfParticipant: matchResult.matched,
      partnerParticipant: finalPartnerParticipant,
      autoMatchedFrom: matchResult.previousName,
      autoMatchSimilarity: matchResult.similarity,
      updatedAt: firestore.FieldValue.serverTimestamp(),
    };
    
    // Add partner change metadata if detected
    if (partnerNameChanged && previousPartnerName) {
      updateData.partnerNameChanged = true;
      updateData.previousPartnerName = previousPartnerName;
    }
    
    await firestore
      .collection("relationships")
      .doc(uid)
      .collection("relations")
      .doc(relationshipId)
      .update(updateData);

    return {
      action: "auto_assigned",
      selfParticipant: matchResult.matched,
      partnerParticipant: finalPartnerParticipant,
      partnerNameChanged,
      previousPartnerName,
      message: `Önceki "${matchResult.previousName}" ismine benzer "${matchResult.matched}" otomatik seçildi.`,
    };
  } else if (matchResult.matchType === "similar") {
    // Suggest for confirmation (70-94% match)
    console.log(`[${uid}] Suggesting selfParticipant: ${matchResult.matched} (confirm needed)`);
    
    // Save suggestion to Firestore
    await firestore
      .collection("relationships")
      .doc(uid)
      .collection("relations")
      .doc(relationshipId)
      .update({
        suggestedSpeaker: matchResult.matched,
        suggestedFromPrevious: matchResult.previousName,
        suggestSimilarity: matchResult.similarity,
        updatedAt: firestore.FieldValue.serverTimestamp(),
      });
    
    return {
      action: "suggest",
      suggestedSpeaker: matchResult.matched,
      previousName: matchResult.previousName,
      similarity: matchResult.similarity,
      message: `Önceki "${matchResult.previousName}" ismine benziyor. Sen "${matchResult.matched}" misin?`,
    };
  } else {
    // No match, ask normally (0-69% match)
    console.log(`[${uid}] No good match, will ask normally`);
    
    return {
      action: "ask_normally",
      message: null,
    };
  }
}