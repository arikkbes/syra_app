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

// OpenAI model constants - Using GPT-4 models
export const MODEL_GPT4O = "gpt-4o";
export const MODEL_GPT4O_MINI = "gpt-4o-mini";

// Active model routing constants
export const MODEL_FREE_DEFAULT = MODEL_GPT4O_MINI; // Free users
export const MODEL_PREMIUM_DEFAULT = MODEL_GPT4O; // Premium users
export const MODEL_FALLBACK = MODEL_GPT4O_MINI; // Fallback if primary fails

// MODULE 2.5: Retry configuration
export const MAX_RETRY_ATTEMPTS = 3;
export const RETRY_BASE_DELAY_MS = 1000; // 1 second base delay
export const RETRY_MAX_JITTER_MS = 500; // Up to 500ms random jitter

// Response quality guardrails (shared)
export const GENERIC_FILLER_PHRASES = [
  "buradayım",
  "seni dinliyorum",
  "yardımcı olabilirim",
  "başka bir şey var mı",
  "ne düşünüyorsun",
  "umarım beğenirsin",
  "ihtiyacın olan her şey",
  "ne hakkında konuşmak istersin",
  "neyle ilgilenmek istersin",
  "ne yapmak istersin",
];
