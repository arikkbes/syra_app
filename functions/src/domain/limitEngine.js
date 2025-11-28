/**
 * ═══════════════════════════════════════════════════════════════
 * LIMIT ENGINE
 * ═══════════════════════════════════════════════════════════════
 * Manages daily limits and premium advantages
 */

import { DAILY_BACKEND_LIMIT } from "../utils/constants.js";

/**
 * Check if user has hit backend daily limit
 * Premium users have no limits
 */
export function hasHitBackendLimit(userProfile, isPremium) {
  if (isPremium) return false;

  const backendCount = userProfile.backendMessageCount || 0;
  const today = new Date().toISOString().split("T")[0];
  const lastDate = (userProfile.lastMessageDate || "").split("T")[0];

  // Reset if new day
  if (lastDate !== today) return false;

  return backendCount >= DAILY_BACKEND_LIMIT;
}

/**
 * Get remaining messages for user
 */
export function getRemainingMessages(userProfile, isPremium) {
  if (isPremium) return Infinity;

  const backendCount = userProfile.backendMessageCount || 0;
  const today = new Date().toISOString().split("T")[0];
  const lastDate = (userProfile.lastMessageDate || "").split("T")[0];

  // Reset if new day
  if (lastDate !== today) return DAILY_BACKEND_LIMIT;

  return Math.max(0, DAILY_BACKEND_LIMIT - backendCount);
}

/**
 * Check if user can send message
 */
export function canSendMessage(userProfile, isPremium) {
  return !hasHitBackendLimit(userProfile, isPremium);
}
