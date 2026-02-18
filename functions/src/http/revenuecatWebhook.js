import admin from "firebase-admin";

if (!admin.apps.length) admin.initializeApp();
const db = admin.firestore();
const FieldValue = admin.firestore.FieldValue;

const EVENTS_COLLECTION = "_webhooks_revenuecat_events";
const CORE_ENTITLEMENT_KEY = "core";
const PLUS_ENTITLEMENT_KEY = "plus";

const ACTIVE_ACCESS_EVENT_TYPES = new Set([
  "INITIAL_PURCHASE",
  "RENEWAL",
  "PRODUCT_CHANGE",
  "UNCANCELLATION",
  "NON_RENEWING_PURCHASE",
  "SUBSCRIPTION_EXTENDED",
  "TEMPORARY_ENTITLEMENT_GRANT",
]);

const ACCESS_LOSS_EVENT_TYPES = new Set([
  "EXPIRATION",
  "CANCELLATION",
  "BILLING_ISSUE",
]);

function getUidFromPayload(event, body) {
  return (
    event?.app_user_id ||
    body?.app_user_id ||
    body?.subscriber?.app_user_id ||
    body?.subscriber?.original_app_user_id ||
    null
  );
}

function getEventType(event, body) {
  return event?.type || event?.event_type || body?.type || "unknown";
}

function getEventId(event, body) {
  return (
    event?.id ||
    event?.event_id ||
    event?.uuid ||
    body?.event_id ||
    null
  );
}

function getProductId(event, body) {
  return event?.product_id || body?.product_id || null;
}

function getEnvironment(event, body) {
  return event?.environment || body?.environment || null;
}

function getEntitlementIds(event, body) {
  const eventEntitlementIds = event?.entitlement_ids;
  if (Array.isArray(eventEntitlementIds)) {
    return eventEntitlementIds.map((item) => String(item));
  }

  const subscriberEntitlements = body?.subscriber?.entitlements;
  if (subscriberEntitlements && typeof subscriberEntitlements === "object") {
    return Object.keys(subscriberEntitlements);
  }

  return [];
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

function getEventTimestampMs(event, body) {
  return toMs(event?.event_timestamp_ms ?? body?.event_timestamp_ms);
}

function getExpirationAtMs(event, body) {
  return toMs(event?.expiration_at_ms ?? body?.expiration_at_ms);
}

function getBearerToken(req) {
  const authHeader = req.get("Authorization");
  if (authHeader && authHeader.startsWith("Bearer ")) {
    return authHeader.slice("Bearer ".length).trim();
  }
  return null;
}

function hasCoreEntitlement(entitlementIds) {
  return entitlementIds.some((value) => String(value).toLowerCase() === CORE_ENTITLEMENT_KEY);
}

function hasPlusEntitlement(entitlementIds) {
  return entitlementIds.some((value) => String(value).toLowerCase() === PLUS_ENTITLEMENT_KEY);
}

// plus > core > free sırasıyla plan belirle
function determinePlan(entitlementIds) {
  if (hasPlusEntitlement(entitlementIds)) return "plus";
  if (hasCoreEntitlement(entitlementIds)) return "core";
  return "free";
}

function shouldActivatePremium(eventType, entitlementIds) {
  if (!ACTIVE_ACCESS_EVENT_TYPES.has(eventType)) return false;
  return hasCoreEntitlement(entitlementIds) || hasPlusEntitlement(entitlementIds);
}

function shouldDeactivatePremium(eventType) {
  return ACCESS_LOSS_EVENT_TYPES.has(eventType);
}

async function markEventAsProcessedOrDuplicate(eventRef, eventPayload) {
  let duplicate = false;
  await db.runTransaction(async (tx) => {
    const existingDoc = await tx.get(eventRef);
    if (existingDoc.exists) {
      duplicate = true;
      return;
    }
    tx.set(eventRef, eventPayload);
  });
  return duplicate;
}

async function ensureUserDocExists(userRef, uid) {
  const userDoc = await userRef.get();
  if (userDoc.exists) return false;

  await userRef.set(
    {
      uid,
      createdAt: FieldValue.serverTimestamp(),
      isPremium: false,
      plan: "free",
      dailyMessageLimit: 10,
      dailyMessageCount: 0,
      usedToday: 0,
    },
    { merge: true }
  );
  return true;
}

export function createRevenuecatWebhookHandler() {
  return async function revenuecatWebhookHandler(req, res) {
    try {
      if (req.method !== "POST") {
        return res.status(405).json({ success: false, code: "METHOD_NOT_ALLOWED" });
      }

      const secret = process.env.REVENUECAT_WEBHOOK_SECRET;
      if (!secret) {
        return res.status(500).json({
          success: false,
          code: "MISSING_ENV",
          message: "Missing required env var REVENUECAT_WEBHOOK_SECRET",
        });
      }

      const providedSecret = getBearerToken(req);

      if (!secret || !providedSecret || providedSecret !== secret) {
        return res.status(401).json({ success: false, code: "UNAUTHORIZED" });
      }

      const body = req.body || {};
      const event = body?.event && typeof body.event === "object" ? body.event : body;
      const eventId = getEventId(event, body);
      const eventType = getEventType(event, body);
      const appUserId = getUidFromPayload(event, body);
      const productId = getProductId(event, body);
      const entitlementIds = getEntitlementIds(event, body);
      const environment = getEnvironment(event, body);
      const eventTimestampMs = getEventTimestampMs(event, body);
      const expirationAtMs = getExpirationAtMs(event, body);

      if (!eventId) {
        return res.status(400).json({ success: false, code: "MISSING_EVENT_ID" });
      }

      if (!appUserId) {
        return res.status(400).json({ success: false, code: "MISSING_UID" });
      }

      const eventRef = db.collection(EVENTS_COLLECTION).doc(String(eventId));
      const duplicate = await markEventAsProcessedOrDuplicate(eventRef, {
        eventId,
        eventType,
        appUserId,
        productId,
        entitlementIds,
        environment,
        eventTimestampMs,
        expirationAtMs,
        processedAt: FieldValue.serverTimestamp(),
      });

      if (duplicate) {
        console.log(
          `[rc_webhook] eventId=${eventId} eventType=${eventType} appUserId=${appUserId} action=duplicate`
        );
        return res.status(200).json({ success: true, duplicate: true });
      }

      const userRef = db.collection("users").doc(appUserId);
      const createdUserDoc = await ensureUserDocExists(userRef, appUserId);

      if (eventType === "TEST") {
        const action = createdUserDoc ? "createdUserDoc+testOnly" : "testOnly";
        console.log(
          `[rc_webhook] eventId=${eventId} eventType=${eventType} appUserId=${appUserId} action=${action}`
        );
        return res.status(200).json({ success: true, appUserId, handled: true });
      }

      let updatedPremium = false;
      if (shouldActivatePremium(eventType, entitlementIds)) {
        await userRef.set(
          {
            isPremium: true,
            plan: determinePlan(entitlementIds),
            premiumUpdatedAt: FieldValue.serverTimestamp(),
            rc: {
              lastEventId: eventId,
              productId,
              expirationAtMs,
              environment,
            },
          },
          { merge: true }
        );
        updatedPremium = true;
      } else if (shouldDeactivatePremium(eventType)) {
        await userRef.set(
          {
            isPremium: false,
            plan: "free",
            premiumUpdatedAt: FieldValue.serverTimestamp(),
            rc: {
              lastEventId: eventId,
              productId,
              expirationAtMs,
              environment,
            },
          },
          { merge: true }
        );
        updatedPremium = true;
      }

      const action = updatedPremium
        ? createdUserDoc
          ? "createdUserDoc+updatedPremium"
          : "updatedPremium"
        : createdUserDoc
          ? "createdUserDoc"
          : "handled";

      console.log(
        `[rc_webhook] eventId=${eventId} eventType=${eventType} appUserId=${appUserId} action=${action}`
      );
      return res.status(200).json({ success: true, appUserId, handled: true });
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
