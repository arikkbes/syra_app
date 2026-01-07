/**
 * ═══════════════════════════════════════════════════════════════
 * BACKEND CONSTANTS
 * ═══════════════════════════════════════════════════════════════
 * All constant values used across the backend
 */

export const DAILY_BACKEND_LIMIT = 150;
export const MAX_HISTORY_MESSAGES = 30;

export const GENDER_DETECTION_ATTEMPTS = 3;

export const SUMMARY_THRESHOLD = 20;

export const PATTERN_DETECTION_MIN_MESSAGES = 10;

// TASK A: Model routing with gpt-5.2 and gpt-5-mini
export const MODEL_GPT5_2 = "gpt-5.2";
export const MODEL_GPT5_MINI = "gpt-5-mini";

// Legacy models (kept for backward compatibility, not used in routing)
export const MODEL_GPT4O = "gpt-4o";
export const MODEL_GPT4O_MINI = "gpt-4o-mini";

// Active model routing constants
export const MODEL_FREE_DEFAULT = MODEL_GPT5_MINI; // Free users
export const MODEL_PREMIUM_DEFAULT = MODEL_GPT5_2; // Premium users
export const MODEL_FALLBACK = MODEL_GPT5_MINI; // Fallback if primary fails
