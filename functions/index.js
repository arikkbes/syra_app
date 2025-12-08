/**
 * ═══════════════════════════════════════════════════════════════
 * SYRA AI - CLOUD FUNCTIONS INDEX
 * ═══════════════════════════════════════════════════════════════
 * Modular, clean architecture
 */

import { onRequest } from "firebase-functions/v2/https";
import { syraChatHandler } from "./src/http/syraChatHandler.js";
import { analyzeRelationshipChatHandler } from "./src/http/relationshipAnalysisHandler.js";
import { tarotReadingHandler } from "./src/http/tarotReadingHandler.js";
import { relationshipStatsHandler } from "./src/http/relationshipStatsHandler.js";

/**
 * Main SYRA chat endpoint
 * 
 * IMPORTANT: Function name kept as 'flortIQChat' to maintain
 * compatibility with existing mobile app builds and deployments.
 */
export const flortIQChat = onRequest(
  {
    cors: true,
    timeoutSeconds: 120,
    memory: "256MiB",
  },
  syraChatHandler
);

/**
 * Relationship analysis endpoint
 * Analyzes uploaded WhatsApp chat files
 */
export const analyzeRelationshipChat = onRequest(
  {
    cors: true,
    timeoutSeconds: 300, // 5 minutes for processing
    memory: "512MiB",
  },
  analyzeRelationshipChatHandler
);

/**
 * Tarot reading endpoint
 * Generates AI-powered tarot card readings
 */
export const tarotReading = onRequest(
  {
    cors: true,
    timeoutSeconds: 60,
    memory: "256MiB",
  },
  tarotReadingHandler
);

/**
 * Relationship stats endpoint
 * Returns "Who More?" statistics from uploaded relationship data
 */
export const getRelationshipStats = onRequest(
  {
    region: "us-central1",
    cors: true,
    timeoutSeconds: 60,
    memory: "256MiB",
  },
  relationshipStatsHandler
);
