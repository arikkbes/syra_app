/**
 * ═══════════════════════════════════════════════════════════════
 * RELATIONSHIP CONTEXT HELPER
 * ═══════════════════════════════════════════════════════════════
 * Provides relationship participant mapping for chat context
 * Ensures SYRA never confuses who the user is in relationship memory
 * ═══════════════════════════════════════════════════════════════
 */

import { db as firestore } from "../config/firebaseAdmin.js";

/**
 * Get active relationship context with participant mapping
 * @param {string} uid - User ID
 * @returns {Promise<Object|null>} - { relationshipId, selfParticipant, partnerParticipant, speakers }
 */
export async function getActiveRelationshipContext(uid) {
  try {
    console.log(`[${uid}] Getting active relationship context...`);
    
    // Step 1: Read user's activeRelationshipId
    const userDoc = await firestore.collection("users").doc(uid).get();
    const activeRelationshipId = userDoc.data()?.activeRelationshipId;
    
    // ═══════════════════════════════════════════════════════════════
    // BUG FIX #2: No fallback - if activeRelationshipId is null/missing,
    // there is NO active relationship
    // ═══════════════════════════════════════════════════════════════
    if (!activeRelationshipId) {
      console.log(`[${uid}] No activeRelationshipId - no active relationship`);
      return null;
    }
    
    console.log(`[${uid}] Active relationship ID: ${activeRelationshipId}`);
    
    // Fetch the relationship document
    const relationshipRef = firestore
      .collection("relationships")
      .doc(uid)
      .collection("relations")
      .doc(activeRelationshipId);
    
    const docSnap = await relationshipRef.get();
    
    if (!docSnap.exists) {
      console.log(`[${uid}] activeRelationshipId exists but doc not found`);
      return null;
    }
    
    const relationshipDoc = docSnap.data();
    
    // ═══════════════════════════════════════════════════════════════
    // BUG FIX #2: Check isActive flag - if false, treat as no relationship
    // ═══════════════════════════════════════════════════════════════
    if (relationshipDoc.isActive === false) {
      console.log(`[${uid}] Relationship exists but isActive=false`);
      return null;
    }
    
    // Extract participant mapping
    const selfParticipant = relationshipDoc.selfParticipant || null;
    const partnerParticipant = relationshipDoc.partnerParticipant || null;
    const speakers = relationshipDoc.speakers || [];
    
    console.log(`[${uid}] Relationship context:`, {
      relationshipId: activeRelationshipId,
      selfParticipant,
      partnerParticipant,
      speakers,
    });
    
    return {
      relationshipId: activeRelationshipId,
      selfParticipant,
      partnerParticipant,
      speakers,
    };
    
  } catch (e) {
    console.error(`[${uid}] getActiveRelationshipContext error:`, e);
    return null;
  }
}

/**
 * Build relationship participant context for system prompt
 * @param {Object} relationshipContext - From getActiveRelationshipContext()
 * @returns {string} - System message content explaining participant mapping
 */
export function buildParticipantContextPrompt(relationshipContext) {
  if (!relationshipContext) return null;
  
  const { selfParticipant, partnerParticipant, speakers } = relationshipContext;
  
  // If selfParticipant is not set, ask user to clarify
  if (!selfParticipant) {
    return `⚠️ RELATIONSHIP CONTEXT - PARTICIPANT MAPPING REQUIRED:
The uploaded WhatsApp export contains messages from: ${speakers.join(", ")}
However, USER identity is not yet mapped.

CRITICAL INSTRUCTION:
Before using any relationship memory context, politely ask the user:
"Bu konuşmada sen hangisisin? (${speakers.join(" mi, ")} mi?)"

Do NOT make assumptions about who the user is. Wait for explicit confirmation.`;
  }
  
  // If selfParticipant is set, provide clear mapping
  let prompt = `🎯 RELATIONSHIP CONTEXT - PARTICIPANT MAPPING:
In the uploaded WhatsApp export:
• USER (the app user) is: "${selfParticipant}"`;
  
  if (partnerParticipant) {
    prompt += `
• PARTNER is: "${partnerParticipant}"`;
  } else if (speakers.length > 2) {
    const others = speakers.filter(s => s !== selfParticipant);
    prompt += `
• OTHER participants: ${others.join(", ")}`;
  }
  
  prompt += `

CRITICAL RULES:
1. When referencing messages from the export, treat "${selfParticipant}" as the USER (app user)
2. Never flip roles - if a message is from "${selfParticipant}", it's the USER's message
3. If uncertain about participant identity, ask for confirmation rather than guessing
4. When summarizing conversations, always clarify who said what using these role labels`;
  
  return prompt;
}

/**
 * Map speaker name to role label for structured context
 * @param {string} speaker - Speaker name from message
 * @param {Object} relationshipContext - From getActiveRelationshipContext()
 * @returns {string} - "USER" | "PARTNER" | "OTHER" | speaker name
 */
export function mapSpeakerToRole(speaker, relationshipContext) {
  if (!relationshipContext || !speaker) return speaker;
  
  const { selfParticipant, partnerParticipant } = relationshipContext;
  
  if (!selfParticipant) {
    // No mapping available, return raw speaker name
    return speaker;
  }
  
  if (speaker === selfParticipant) {
    return "USER";
  }
  
  if (partnerParticipant && speaker === partnerParticipant) {
    return "PARTNER";
  }
  
  // Not user or partner
  return "OTHER";
}

/**
 * Detect if user's message contains self-identification as one of the speakers
 * @param {string} userMessage - User's message text
 * @param {Array<string>} speakers - List of speaker names from relationship
 * @returns {string|null} - Matched speaker name or null if no clear match
 */
export function detectSelfParticipantFromMessage(userMessage, speakers) {
  if (!userMessage || !speakers || speakers.length === 0) {
    return null;
  }
  
  // Normalize message
  const normalized = userMessage.trim().toLowerCase();
  
  // Check each speaker
  for (const speaker of speakers) {
    const speakerLower = speaker.toLowerCase().trim();
    
    // Pattern 1: Exact match (just the speaker name)
    if (normalized === speakerLower) {
      return speaker;
    }
    
    // Pattern 2: Turkish patterns
    // "ben X", "ben X'yim", "ben X'im"
    const turkishPatterns = [
      new RegExp(`^ben\\s+${escapeRegex(speakerLower)}$`, 'i'),
      new RegExp(`^ben\\s+${escapeRegex(speakerLower)}['']?[yı]?[ım]$`, 'i'),
      new RegExp(`^${escapeRegex(speakerLower)}\\s*$`, 'i'),
      new RegExp(`^benim\\s+ad[ıi]m\\s+${escapeRegex(speakerLower)}$`, 'i'),
    ];
    
    for (const pattern of turkishPatterns) {
      if (pattern.test(normalized)) {
        return speaker;
      }
    }
    
    // Pattern 3: English patterns
    // "I'm X", "i am X", "my name is X"
    const englishPatterns = [
      new RegExp(`^i'?m\\s+${escapeRegex(speakerLower)}$`, 'i'),
      new RegExp(`^i\\s+am\\s+${escapeRegex(speakerLower)}$`, 'i'),
      new RegExp(`^my\\s+name\\s+is\\s+${escapeRegex(speakerLower)}$`, 'i'),
    ];
    
    for (const pattern of englishPatterns) {
      if (pattern.test(normalized)) {
        return speaker;
      }
    }
  }
  
  return null;
}

/**
 * Helper: Escape special regex characters
 */
function escapeRegex(str) {
  return str.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
}

/**
 * Auto-persist selfParticipant when user answers clarification question
 * @param {string} uid - User ID
 * @param {string} relationshipId - Relationship ID
 * @param {string} selfParticipant - Detected self participant
 * @param {Array<string>} speakers - All speakers in conversation
 * @returns {Promise<boolean>} - Success status
 */
export async function persistSelfParticipant(uid, relationshipId, selfParticipant, speakers) {
  try {
    console.log(`[${uid}] 🔄 Auto-persisting selfParticipant: ${selfParticipant}`);
    
    // Determine partner participant (if exactly 2 speakers)
    let partnerParticipant = null;
    if (speakers.length === 2) {
      partnerParticipant = speakers.find(s => s !== selfParticipant);
      console.log(`[${uid}] 🔄 Auto-detected partnerParticipant: ${partnerParticipant}`);
    }
    
    const updateData = {
      selfParticipant,
      updatedAt: firestore.FieldValue.serverTimestamp(),
    };
    
    if (partnerParticipant) {
      updateData.partnerParticipant = partnerParticipant;
    }
    
    // Update relationship document
    await firestore
      .collection("relationships")
      .doc(uid)
      .collection("relations")
      .doc(relationshipId)
      .update(updateData);
    
    console.log(`[${uid}] ✅ Auto-set selfParticipant to: ${selfParticipant}`);
    
    // Ensure activeRelationshipId is set
    const userDoc = await firestore.collection("users").doc(uid).get();
    if (!userDoc.data()?.activeRelationshipId) {
      await firestore.collection("users").doc(uid).set({
        activeRelationshipId: relationshipId,
      }, { merge: true });
      console.log(`[${uid}] ✅ Set activeRelationshipId to: ${relationshipId}`);
    }
    
    return true;
  } catch (e) {
    console.error(`[${uid}] ❌ persistSelfParticipant error:`, e);
    return false;
  }
}
