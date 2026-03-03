const POLICY_VERSION = "router_v2";
const FREE_DAILY_CREDITS = 75000;

export function selectModel({ plan, meta, dailyUsage }) {
  try {
    const safePlan = plan || "free";
    const creditsUsed = Number(dailyUsage?.creditsUsed) || 0;
    const consentApproved = meta?.consentApproved === true;
    const deepRequested = meta?.deepAnalysis?.requested === true;

    // Consent-approved evidence path: premium → deep model, free → default model
    if (consentApproved) {
      if (safePlan === "free") {
        return {
          blocked: false,
          model: "gpt-5-mini",
          reason: "consent_free",
          policyVersion: POLICY_VERSION,
        };
      }
      return {
        blocked: false,
        model: "gpt-5.2",
        reason: "consent_deep",
        policyVersion: POLICY_VERSION,
      };
    }

    // Deep analysis (without consent): blocked for free, deep model for premium
    if (deepRequested) {
      if (safePlan === "free") {
        return {
          blocked: true,
          message:
            "Derin analiz şu an CORE/PLUS'ta açık kanka. İstersen normal sohbetten devam edelim — CORE'a geçince bu konuya kanıtlı, detaylı rapor da açılır.",
          reason: "deep_block",
          policyVersion: POLICY_VERSION,
        };
      }
      return {
        blocked: false,
        model: "gpt-5.2",
        reason: "deep_allowed",
        policyVersion: POLICY_VERSION,
      };
    }

    // Free tier daily credit cap
    if (safePlan === "free" && creditsUsed >= FREE_DAILY_CREDITS) {
      return {
        blocked: true,
        message:
          "Bugünlük kullanım limitin doldu kanka. Yarın otomatik sıfırlanıyor. İstersen CORE/PLUS'a geçip kesintisiz devam edebilirsin.",
        reason: "credit_block",
        policyVersion: POLICY_VERSION,
        cap: FREE_DAILY_CREDITS,
      };
    }

    // Default: all normal chat uses gpt-5-mini
    return {
      blocked: false,
      model: "gpt-5-mini",
      reason: "default",
      policyVersion: POLICY_VERSION,
    };
  } catch (error) {
    console.error("[modelRouter] selectModel failed:", error);
    return {
      blocked: false,
      model: "gpt-5-mini",
      reason: "fallback_error",
      policyVersion: POLICY_VERSION,
    };
  }
}
