/**
 * ═══════════════════════════════════════════════════════════════
 * USER PROFILE REPOSITORY
 * ═══════════════════════════════════════════════════════════════
 * All reads/writes for user profiles in Firestore
 * Preserves existing field names and structure
 */

import { db, FieldValue } from "../config/firebaseAdmin.js";

/**
 * Get user profile from Firestore
 */
export async function getUserProfile(uid) {
  try {
    const userRef = db.collection("users").doc(uid);
    const userSnap = await userRef.get();

    if (!userSnap.exists) {
      console.warn(`[${uid}] User profile not found`);
      return createDefaultProfile(uid);
    }

    return userSnap.data();
  } catch (e) {
    console.error(`[${uid}] Error loading profile:`, e);
    return createDefaultProfile(uid);
  }
}

/**
 * Create default profile structure
 */
function createDefaultProfile(uid) {
  return {
    uid,
    isPremium: false,
    messageCount: 0,
    backendMessageCount: 0,
    lastMessageDate: new Date().toISOString(),
    gender: "belirsiz",
    genderAttempts: 0,
    lastTone: "neutral",
    relationshipStage: "unknown",
    attachmentStyle: "unknown",
    totalAdviceGiven: 0,
  };
}

/**
 * Update user profile fields
 */
export async function updateUserProfile(uid, updates) {
  try {
    const userRef = db.collection("users").doc(uid);
    await userRef.set(updates, { merge: true });
  } catch (e) {
    console.error(`[${uid}] Error updating profile:`, e);
    throw e;
  }
}

/**
 * Increment message count and update backend limit
 */
export async function incrementMessageCount(uid, userProfile) {
  try {
    const userRef = db.collection("users").doc(uid);

    const today = new Date().toISOString().split("T")[0];
    const lastDate = (userProfile.lastMessageDate || "").split("T")[0];

    let newBackendCount = userProfile.backendMessageCount || 0;
    let newMessageCount = userProfile.messageCount || 0;

    if (lastDate !== today) {
      newBackendCount = 1;
    } else {
      newBackendCount += 1;
    }

    newMessageCount += 1;

    await userRef.update({
      messageCount: newMessageCount,
      backendMessageCount: newBackendCount,
      lastMessageDate: new Date().toISOString(),
    });

    return { newBackendCount, newMessageCount };
  } catch (e) {
    console.error(`[${uid}] Error incrementing count:`, e);
    throw e;
  }
}

/**
 * Increment gender detection attempts
 */
export async function incrementGenderAttempts(uid) {
  try {
    const userRef = db.collection("users").doc(uid);
    await userRef.update({
      genderAttempts: FieldValue.increment(1),
    });
  } catch (e) {
    console.error(`[${uid}] Error incrementing gender attempts:`, e);
  }
}

/**
 * Update user gender
 */
export async function updateUserGender(uid, gender) {
  try {
    const userRef = db.collection("users").doc(uid);
    await userRef.update({ gender });
  } catch (e) {
    console.error(`[${uid}] Error updating gender:`, e);
  }
}
