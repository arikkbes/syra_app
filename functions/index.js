/**
 * ═══════════════════════════════════════════════════════════════
 * SYRA AI - CLOUD FUNCTIONS INDEX
 * ═══════════════════════════════════════════════════════════════
 * Modular, clean architecture
 */

import { onRequest } from "firebase-functions/v2/https";
import { syraChatHandler } from "./src/http/syraChatHandler.js";

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
