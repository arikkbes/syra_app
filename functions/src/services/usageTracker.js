import { db, FieldValue } from "../config/firebaseAdmin.js";

const DEFAULT_USAGE = {
  creditsUsed: 0,
  totalTokens: 0,
  requestCount: 0,
  byModel: {},
};

const CREDIT_MULTIPLIERS = {
  "gpt-4o-mini": 1,
  "gpt-4o": 16,
};

export function getIstanbulDateKey(date = new Date()) {
  try {
    const formatter = new Intl.DateTimeFormat("en-CA", {
      timeZone: "Europe/Istanbul",
      year: "numeric",
      month: "2-digit",
      day: "2-digit",
    });
    const parts = formatter.formatToParts(date);
    const lookup = parts.reduce((acc, part) => {
      acc[part.type] = part.value;
      return acc;
    }, {});
    const year = lookup.year || "1970";
    const month = lookup.month || "01";
    const day = lookup.day || "01";
    return `${year}-${month}-${day}`;
  } catch (error) {
    console.error("[usageTracker] getIstanbulDateKey failed:", error);
    return new Date(date).toISOString().slice(0, 10);
  }
}

export async function getDailyUsage(uid, dateKey) {
  try {
    if (!uid || !dateKey) return { ...DEFAULT_USAGE };
    const docRef = db
      .collection("users")
      .doc(uid)
      .collection("usage_daily")
      .doc(dateKey);
    const snapshot = await docRef.get();
    if (!snapshot.exists) return { ...DEFAULT_USAGE };
    const data = snapshot.data();
    return {
      ...DEFAULT_USAGE,
      ...(data || {}),
    };
  } catch (error) {
    console.error("[usageTracker] getDailyUsage failed:", error);
    return { ...DEFAULT_USAGE };
  }
}

export async function addDailyUsage(uid, dateKey, usage) {
  try {
    if (!uid || !dateKey) return;
    const model = usage?.model || "unknown";
    const promptTokens = Number(usage?.promptTokens) || 0;
    const completionTokens = Number(usage?.completionTokens) || 0;
    const totalTokens = promptTokens + completionTokens;
    const creditMultiplier = CREDIT_MULTIPLIERS[model] || 1;
    const creditsUsed = totalTokens * creditMultiplier;

    const docRef = db
      .collection("users")
      .doc(uid)
      .collection("usage_daily")
      .doc(dateKey);

    const payload = {
      dateKey,
      totalTokens: FieldValue.increment(totalTokens),
      promptTokens: FieldValue.increment(promptTokens),
      completionTokens: FieldValue.increment(completionTokens),
      creditsUsed: FieldValue.increment(creditsUsed),
      requestCount: FieldValue.increment(1),
      updatedAt: FieldValue.serverTimestamp(),
      [`byModel.${model}.tokens`]: FieldValue.increment(totalTokens),
      [`byModel.${model}.credits`]: FieldValue.increment(creditsUsed),
      [`byModel.${model}.requests`]: FieldValue.increment(1),
    };

    await docRef.set(payload, { merge: true });
  } catch (error) {
    console.error("[usageTracker] addDailyUsage failed:", error);
  }
}
