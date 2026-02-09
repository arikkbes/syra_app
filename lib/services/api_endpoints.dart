/// Centralized API endpoints for SYRA client
class ApiEndpoints {
  ApiEndpoints._();

  // Legacy chat endpoint (kept for reference/backward compatibility)
  static const String flortIQChat =
      "https://us-central1-syra-ai-b562f.cloudfunctions.net/flortIQChat";

  // New chat endpoint (V2)
  static const String syraChatV2 =
      "https://syrachatv2-qbipkdgczq-uc.a.run.app";

  // Other endpoints
  static const String tarotReading =
      "https://us-central1-syra-ai-b562f.cloudfunctions.net/tarotReading";
  static const String relationshipAnalysis =
      "https://us-central1-syra-ai-b562f.cloudfunctions.net/analyzeRelationshipChat";
  static const String relationshipStats =
      "https://getrelationshipstats-qbipkdgczq-uc.a.run.app";
}
