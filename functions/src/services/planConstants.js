/**
 * ═══════════════════════════════════════════════════════════════
 * PLAN CONSTANTS — Single Source of Truth
 * ═══════════════════════════════════════════════════════════════
 */

export const ALLOWED_PLANS = ["free", "core", "plus"];

const ALLOWED_SET = new Set(ALLOWED_PLANS);

/**
 * Normalize a plan value to a valid plan string.
 * @param {*} value - raw plan value from Firestore
 * @returns {"free"|"core"|"plus"|null} - normalized plan or null if invalid
 */
export function normalizePlan(value) {
  if (typeof value !== "string") return null;
  const cleaned = value.trim().toLowerCase();
  return ALLOWED_SET.has(cleaned) ? cleaned : null;
}

/**
 * Check if a plan is a paid plan (not free).
 * @param {string} plan - normalized plan string
 * @returns {boolean}
 */
export function isPaidPlan(plan) {
  return plan !== "free";
}
