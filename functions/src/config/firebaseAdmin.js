/**
 * ═══════════════════════════════════════════════════════════════
 * FIREBASE ADMIN CONFIGURATION
 * ═══════════════════════════════════════════════════════════════
 * Initializes and exports Firebase Admin SDK instances
 */

import admin from "firebase-admin";

// Initialize Firebase Admin if not already initialized
if (!admin.apps.length) {
  admin.initializeApp();
}

// Export common instances
export const db = admin.firestore();
export const auth = admin.auth();
export const FieldValue = admin.firestore.FieldValue;

export default admin;
