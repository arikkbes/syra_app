/**
 * ═══════════════════════════════════════════════════════════════
 * SYRA AI - CLOUD FUNCTIONS INDEX
 * ═══════════════════════════════════════════════════════════════
 * Modular, clean architecture
 */

import { onRequest } from "firebase-functions/v2/https";
import { defineSecret } from "firebase-functions/params";

import { syraChatHandler } from "./src/http/syraChatHandler.js";
import { syraChatV2Handler } from "./src/http/syraChatV2.js";
import { analyzeRelationshipChatHandler } from "./src/http/relationshipAnalysisHandlerV2.js";
import { tarotReadingHandler } from "./src/http/tarotReadingHandler.js";
import { relationshipStatsHandler } from "./src/http/relationshipStatsHandler.js";
import { createRevenuecatWebhookHandler } from "./src/http/revenuecatWebhook.js";

// ✅ Secrets (Firebase Functions v2) — ÇAKIŞMAMASI İÇİN *_SECRET
const SUPABASE_URL_SECRET = defineSecret("SUPABASE_URL_SECRET");
const SUPABASE_SERVICE_ROLE_KEY_SECRET = defineSecret("SUPABASE_SERVICE_ROLE_KEY_SECRET");
const OPENAI_API_KEY_SECRET = defineSecret("OPENAI_API_KEY_SECRET");
// Required by revenuecatWebhook handler (read via process.env.REVENUECAT_WEBHOOK_SECRET)
const REVENUECAT_WEBHOOK_SECRET = defineSecret("REVENUECAT_WEBHOOK_SECRET");
const revenuecatWebhookHandler = createRevenuecatWebhookHandler();

/**
 * Main SYRA chat endpoint
 * Function name kept as 'flortIQChat' for backwards compatibility
 */
export const flortIQChat = onRequest(
  {
    cors: true,
    timeoutSeconds: 120,
    memory: "256MiB",
    secrets: [SUPABASE_URL_SECRET, SUPABASE_SERVICE_ROLE_KEY_SECRET, OPENAI_API_KEY_SECRET],
  },
  syraChatHandler
);

/**
 * New SYRA chat endpoint (V2)
 */
export const syraChatV2 = onRequest(
  {
    cors: true,
    timeoutSeconds: 120,
    memory: "256MiB",
    secrets: [SUPABASE_URL_SECRET, SUPABASE_SERVICE_ROLE_KEY_SECRET, OPENAI_API_KEY_SECRET],
  },
  syraChatV2Handler
);

/**
 * Relationship analysis endpoint
 */
export const analyzeRelationshipChat = onRequest(
  {
    cors: true,
    timeoutSeconds: 900,
    memory: "1GiB",
    secrets: [SUPABASE_URL_SECRET, SUPABASE_SERVICE_ROLE_KEY_SECRET, OPENAI_API_KEY_SECRET],
  },
  analyzeRelationshipChatHandler
);

/**
 * Tarot reading endpoint
 */
export const tarotReading = onRequest(
  {
    cors: true,
    timeoutSeconds: 60,
    memory: "256MiB",
    secrets: [SUPABASE_URL_SECRET, SUPABASE_SERVICE_ROLE_KEY_SECRET, OPENAI_API_KEY_SECRET],
  },
  tarotReadingHandler
);

/**
 * Relationship stats endpoint
 */
export const getRelationshipStats = onRequest(
  {
    region: "us-central1",
    cors: true,
    timeoutSeconds: 60,
    memory: "256MiB",
    secrets: [SUPABASE_URL_SECRET, SUPABASE_SERVICE_ROLE_KEY_SECRET, OPENAI_API_KEY_SECRET],
  },
  relationshipStatsHandler
);

export const revenuecatWebhook = onRequest(
  {
    region: "us-central1",
    cors: false,
    timeoutSeconds: 60,
    memory: "256MiB",
    secrets: [
      SUPABASE_URL_SECRET,
      SUPABASE_SERVICE_ROLE_KEY_SECRET,
      OPENAI_API_KEY_SECRET,
      REVENUECAT_WEBHOOK_SECRET,
    ],
  },
  revenuecatWebhookHandler
);
