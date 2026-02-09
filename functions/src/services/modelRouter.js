const POLICY_VERSION = "router_v1";
const FREE_DAILY_CREDITS = 75000;

export function selectModel({ plan, meta, dailyUsage }) {
  try {
    const safePlan = plan || "free";
    const creditsUsed = Number(dailyUsage?.creditsUsed) || 0;
    const deepRequested = meta?.deepAnalysis?.requested === true;

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
        model: "gpt-4o",
        reason: "deep_allowed",
        policyVersion: POLICY_VERSION,
      };
    }

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

    return {
      blocked: false,
      model: "gpt-4o-mini",
      reason: "default",
      policyVersion: POLICY_VERSION,
    };
  } catch (error) {
    console.error("[modelRouter] selectModel failed:", error);
    return {
      blocked: false,
      model: "gpt-4o-mini",
      reason: "fallback_error",
      policyVersion: POLICY_VERSION,
    };
  }
}
