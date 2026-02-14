import admin from "firebase-admin";

if (!admin.apps.length) admin.initializeApp();
const db = admin.firestore();
const FieldValue = admin.firestore.FieldValue;

const EVENTS_COLLECTION = "_webhooks_revenuecat_events";

function getUidFromPayload(body) {
  return (
    body?.event?.app_user_id ||
    body?.app_user_id ||
    body?.subscriber?.app_user_id ||
    body?.subscriber?.original_app_user_id ||
    null
  );
}

function getEventType(body) {
  return body?.event?.type || body?.event?.event_type || body?.type || "unknown";
}

function getEventId(body) {
  return (
    body?.event?.id ||
    body?.event?.event_id ||
    body?.event?.uuid ||
    body?.event_id ||
    null
  );
}

function getEntitlements(body) {
  return body?.subscriber?.entitlements || body?.event?.subscriber?.entitlements || {};
}

function toMs(value) {
  if (value === null || value === undefined) return null;
  if (typeof value === "number") return Number.isFinite(value) ? value : null;
  if (typeof value === "string") {
    const parsed = Number(value);
    return Number.isFinite(parsed) ? parsed : null;
  }
  return null;
}

function isEntitlementActive(entitlement, nowMs) {
  if (!entitlement || typeof entitlement !== "object") return false;

  const expiresMs = toMs(entitlement.expires_date_ms);
  if (expiresMs !== null) {
    return expiresMs > nowMs;
  }

  const hasPurchaseDate = entitlement.purchase_date != null;
  const hasNoExpiresDate = entitlement.expires_date == null;
  if (hasPurchaseDate && hasNoExpiresDate) {
    return true;
  }

  return false;
}

function resolvePlanFromEntitlements(entitlements, nowMs) {
  const plusEntitlement = entitlements?.plus;
  if (isEntitlementActive(plusEntitlement, nowMs)) {
    return "plus";
  }

  const coreEntitlement = entitlements?.core;
  if (isEntitlementActive(coreEntitlement, nowMs)) {
    return "core";
  }

  return "free";
}

function getProvidedSecret(req) {
  const headerSecret = req.get("X-Webhook-Secret");
  if (headerSecret) return headerSecret;

  const authHeader = req.get("Authorization");
  if (authHeader && authHeader.startsWith("Bearer ")) {
    return authHeader.slice("Bearer ".length).trim();
  }

  return null;
}

export function createRevenuecatWebhookHandler(REVENUECAT_WEBHOOK_SECRET) {
  return async function revenuecatWebhookHandler(req, res) {
    try {
      if (req.method !== "POST") {
        return res.status(405).json({ success: false, code: "METHOD_NOT_ALLOWED" });
      }

      const secret = REVENUECAT_WEBHOOK_SECRET.value();
      const providedSecret = getProvidedSecret(req);

      if (!secret || !providedSecret || providedSecret !== secret) {
        return res.status(401).json({ success: false, code: "UNAUTHORIZED" });
      }

      const body = req.body || {};
      const uid = getUidFromPayload(body);
      if (!uid) {
        return res.status(400).json({ success: false, code: "MISSING_UID" });
      }

      const eventType = getEventType(body);
      const eventId = getEventId(body);

      if (eventId) {
        const eventRef = db.collection(EVENTS_COLLECTION).doc(String(eventId));
        const eventDoc = await eventRef.get();
        if (eventDoc.exists) {
          return res.status(200).json({ success: true, duplicate: true });
        }
        await eventRef.set({ processedAt: FieldValue.serverTimestamp() });
      }

      const entitlements = getEntitlements(body);
      const plan = resolvePlanFromEntitlements(entitlements, Date.now());

      const userRef = db.collection("users").doc(uid);
      const userDoc = await userRef.get();
      if (!userDoc.exists) {
        console.warn(`[rc_webhook] uid=${uid} user_doc_missing type=${eventType} plan=${plan}`);
        return res.status(200).json({ success: true, userDocMissing: true });
      }

      await userRef.update({
        plan,
        isPremium: plan !== "free",
        planUpdatedAt: FieldValue.serverTimestamp(),
      });

      console.log(`[rc_webhook] uid=${uid} type=${eventType} plan=${plan}`);
      return res.status(200).json({ success: true });
    } catch (err) {
      console.error("[rc_webhook_error]", err?.stack || err);
      return res.status(500).json({
        success: false,
        code: "INTERNAL",
        message: String(err?.message || err),
      });
    }
  };
}
