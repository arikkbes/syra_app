/// ═══════════════════════════════════════════════════════════════
/// USER PLAN — Single Source of Truth (Flutter)
/// ═══════════════════════════════════════════════════════════════
/// Mirrors backend planConstants.js precedence policy.
///
/// PLAN PRECEDENCE POLICY:
/// 1. If plan field is valid ("free"|"core"|"plus") → use it
/// 2. Else if isPremium == true → core (legacy fallback)
/// 3. Else → free
/// ═══════════════════════════════════════════════════════════════

enum UserPlan {
  free,
  core,
  plus;

  // ───────────────────────────────────────────────────────────
  // Parsing
  // ───────────────────────────────────────────────────────────

  /// Parse a Firestore plan value with legacy isPremium fallback.
  ///
  /// Implements the same precedence as backend planResolver:
  /// - { plan:"free", isPremium:true } → free (plan wins)
  /// - { plan:"core", isPremium:false } → core (plan wins)
  /// - { plan:"premium" } → invalid → fallback to isPremium
  /// - { } → free
  static UserPlan parsePlan(dynamic planValue, {bool legacyIsPremium = false}) {
    if (planValue is String) {
      final cleaned = planValue.trim().toLowerCase();
      for (final p in UserPlan.values) {
        if (p.firestoreValue == cleaned) return p;
      }
    }
    // Invalid or missing plan → legacy fallback
    if (legacyIsPremium) return UserPlan.core;
    return UserPlan.free;
  }

  // ───────────────────────────────────────────────────────────
  // Helpers
  // ───────────────────────────────────────────────────────────

  /// Whether this plan is a paid tier (core or plus).
  bool get isPaid => this != UserPlan.free;

  /// User-facing label.
  String get label {
    switch (this) {
      case UserPlan.free:
        return 'Free';
      case UserPlan.core:
        return 'CORE';
      case UserPlan.plus:
        return 'PLUS';
    }
  }

  /// Value stored in Firestore.
  String get firestoreValue {
    switch (this) {
      case UserPlan.free:
        return 'free';
      case UserPlan.core:
        return 'core';
      case UserPlan.plus:
        return 'plus';
    }
  }
}
