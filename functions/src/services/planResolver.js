import { getUserProfile } from "../firestore/userProfileRepository.js";
import { normalizePlan } from "./planConstants.js";

/**
 * ═══════════════════════════════════════════════════════════════
 * PLAN PRECEDENCE POLICY (NON-NEGOTIABLE):
 * 1. If user.plan is valid ("free"|"core"|"plus") → use it (plan wins)
 * 2. Else if user.isPremium === true → treat as "core" (legacy fallback)
 * 3. Else → "free"
 *
 * Edge cases:
 * - { plan:"free", isPremium:true } → "free" (plan wins)
 * - { plan:"core", isPremium:false } → "core" (plan wins)
 * - { plan:"premium" } → invalid → fallback to isPremium if present, else free
 * - { } → free
 * ═══════════════════════════════════════════════════════════════
 */
export async function resolveUserPlan(uid) {
  try {
    const profile = await getUserProfile(uid);
    const normalized = normalizePlan(profile?.plan);
    if (normalized) {
      return normalized;
    }
    // Legacy fallback: isPremium boolean
    if (profile?.isPremium === true) {
      return "core";
    }
    return "free";
  } catch (error) {
    console.error("[planResolver] resolveUserPlan failed:", error);
    return "free";
  }
}
