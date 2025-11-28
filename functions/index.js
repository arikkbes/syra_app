/**
 * ═══════════════════════════════════════════════════════════════
 * SYRA AI - CLOUD FUNCTIONS INDEX
 * ═══════════════════════════════════════════════════════════════
 * Modular, clean architecture
 * 
 * This file only exports Cloud Functions and wires HTTP handlers.
 * All business logic is in src/ modules.
 */

import { onRequest } from "firebase-functions/v2/https";
import { syraChatHandler } from "./src/http/syraChatHandler.js";

/**
 * Main SYRA chat endpoint
 * 
 * IMPORTANT: Function name kept as 'flortIQChat' to maintain
 * compatibility with existing mobile app builds and deployments.
 * 
 * Endpoint: POST /flortIQChat
 * Auth: Bearer token (Firebase ID token)
 * Request: { message: string, context?: array }
 * Response: { response: string, ...metadata }
 */
export const flortIQChat = onRequest(
  {
    cors: true,
    timeoutSeconds: 120, // Extended timeout for AI processing
    memory: "256MiB",
  },
  syraChatHandler
);
