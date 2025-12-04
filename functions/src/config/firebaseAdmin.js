/**
 * ═══════════════════════════════════════════════════════════════
 * FIREBASE ADMIN CONFIGURATION
 * ═══════════════════════════════════════════════════════════════
 * Initializes and exports Firebase Admin SDK instances
 */

import admin from "firebase-admin";

if (!admin.apps.length) {
  admin.initializeApp();
}

export const db = admin.firestore();
export const auth = admin.auth();
export const FieldValue = admin.firestore.FieldValue;

export default admin;
