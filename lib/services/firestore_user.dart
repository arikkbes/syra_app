import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/user_plan.dart';

class FirestoreUser {
  static final _firestore = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;

  static DocumentReference<Map<String, dynamic>> _userRef() {
    final uid = _auth.currentUser?.uid;
    return _firestore.collection("users").doc(uid);
  }

  static Future<Map<String, dynamic>?> getUserData() async {
    final snap = await _userRef().get();
    return snap.data();
  }

  // ─────────────────────────────────────────────────────────────
  // Plan-based API (Sprint 4)
  // ─────────────────────────────────────────────────────────────

  /// Resolve the user's plan applying precedence policy:
  /// 1. plan field valid → use it
  /// 2. isPremium true → core (legacy fallback)
  /// 3. else → free
  static Future<UserPlan> getPlan() async {
    final data = await getUserData();
    return UserPlan.parsePlan(
      data?["plan"],
      legacyIsPremium: data?["isPremium"] == true,
    );
  }

  /// Set the user's plan in Firestore.
  static Future<void> setPlan(UserPlan plan) async {
    await _userRef().update({
      "plan": plan.firestoreValue,
    });
  }

  // ─────────────────────────────────────────────────────────────
  // Legacy API (deprecated — use getPlan() instead)
  // ─────────────────────────────────────────────────────────────

  @Deprecated('Use getPlan() instead')
  static Future<bool> isPremium() async {
    final plan = await getPlan();
    return plan.isPaid;
  }

  /// ⚠️ DEPRECATED: Direct client writes to plan/isPremium will fail due to Firestore rules.
  /// 
  /// This method is kept temporarily for backward compatibility with PurchaseService,
  /// but writes will be blocked by server. The backend should handle plan updates
  /// via webhook (RevenueCat → Cloud Functions → Firestore).
  /// 
  /// TODO: Remove this method and update PurchaseService to rely solely on
  /// RevenueCat entitlements, with server-side sync handling Firestore updates.
  @Deprecated('Client should NOT write plan/isPremium - server sync only')
  static Future<void> upgradeToPremium() async {
    // ⚠️ WARNING: This write will FAIL if Firestore rules are tightened.
    // Keep for now to avoid breaking existing flow, but replace with server sync.
    try {
      await _userRef().update({
        "isPremium": true,
        "plan": "core",
        "dailyMessageLimit": 99999,
      });
    } catch (e) {
      debugPrint("⚠️ [FirestoreUser] upgradeToPremium failed (expected if rules block): $e");
      // Don't rethrow - allow purchase flow to succeed based on RevenueCat entitlement
    }
  }

  static Future<void> createProfile(User user) async {
    await _firestore.collection("users").doc(user.uid).set({
      "uid": user.uid,
      "email": user.email ?? '',
      "createdAt": FieldValue.serverTimestamp(),

      "plan": "free",
      "isPremium": false,
      "dailyMessageLimit": 10,
      "dailyMessageCount": 0,
      "lastMessageDate": DateTime.now().toIso8601String(),
      "cooldownEnd": null,

      "botCharacter": "default",
      "replyLength": "default",
      "notifDaily": true,
      "notifOffers": true,
    });
  }

  static Future<void> incrementMessageCount() async {
    final doc = await _userRef().get();
    if (!doc.exists) return;

    final data = doc.data()!;
    final now = DateTime.now();
    final last = DateTime.tryParse(data["lastMessageDate"] ?? "") ?? now;

    final sameDay =
        last.year == now.year && last.month == now.month && last.day == now.day;

    final newCount = sameDay ? (data["dailyMessageCount"] ?? 0) + 1 : 1;

    await _userRef().update({
      "dailyMessageCount": newCount,
      "lastMessageDate": now.toIso8601String(),
    });
  }

  static Future<Map<String, dynamic>> getMessageStatus() async {
    final data = await getUserData();
    final plan = UserPlan.parsePlan(
      data?["plan"],
      legacyIsPremium: data?["isPremium"] == true,
    );

    return {
      "plan": plan,
      "isPremium": plan.isPaid, // derived from plan for backward compat
      "limit": data?["dailyMessageLimit"] ?? 10,
      "count": data?["dailyMessageCount"] ?? 0,
      "lastMessageDate":
          DateTime.tryParse(data?["lastMessageDate"] ?? "") ?? DateTime.now(),
      "cooldownEnd": data?["cooldownEnd"],
    };
  }

  static Future<void> saveMessage({
    required String sender,
    required String text,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final now = DateTime.now();
    final dateId = "${now.year}-${now.month}-${now.day}";

    await _firestore
        .collection("users")
        .doc(uid)
        .collection("conversations")
        .doc(dateId)
        .collection("messages")
        .add({
      "sender": sender,
      "text": text,
      "timestamp": FieldValue.serverTimestamp(),
    });
  }

  static Future<List<Map<String, dynamic>>> getChatHistory(int limit) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return [];

    final now = DateTime.now();
    final dateId = "${now.year}-${now.month}-${now.day}";

    final query = await _firestore
        .collection("users")
        .doc(uid)
        .collection("conversations")
        .doc(dateId)
        .collection("messages")
        .orderBy("timestamp", descending: true)
        .limit(limit)
        .get();

    return query.docs.reversed.map((doc) {
      return {
        "sender": doc["sender"],
        "text": doc["text"],
      };
    }).toList();
  }

  static Future<void> saveTrait({
    required String traitName,
    required String value,
    String? notes,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    await _firestore
        .collection("users")
        .doc(uid)
        .collection("profile_memory")
        .doc(traitName)
        .set({
      "value": value,
      "notes": notes ?? "",
      "updatedAt": FieldValue.serverTimestamp(),
    });
  }

  static Future<Map<String, dynamic>> getAllTraits() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return {};

    final query = await _firestore
        .collection("users")
        .doc(uid)
        .collection("profile_memory")
        .get();

    final Map<String, dynamic> traits = {};
    for (final doc in query.docs) {
      traits[doc.id] = doc.data();
    }
    return traits;
  }

  static Future<Map<String, dynamic>> getSettings() async {
    final data = await getUserData() ?? {};

    return {
      "botCharacter": data["botCharacter"] ?? "default",
      "replyLength": data["replyLength"] ?? "default",
      "notifDaily": data["notifDaily"] ?? true,
      "notifOffers": data["notifOffers"] ?? true,
    };
  }

  static Future<void> saveSettings({
    String? botCharacter,
    String? replyLength,
    bool? notifDaily,
    bool? notifOffers,
  }) async {
    final Map<String, dynamic> payload = {};

    if (botCharacter != null) payload["botCharacter"] = botCharacter;
    if (replyLength != null) payload["replyLength"] = replyLength;
    if (notifDaily != null) payload["notifDaily"] = notifDaily;
    if (notifOffers != null) payload["notifOffers"] = notifOffers;

    if (payload.isNotEmpty) {
      await _userRef().update(payload);
    }
  }

  static Future<void> clearAllConversations() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final convSnap = await _firestore
        .collection("users")
        .doc(uid)
        .collection("conversations")
        .get();

    for (final convDoc in convSnap.docs) {
      final msgsSnap = await convDoc.reference.collection("messages").get();
      for (final msg in msgsSnap.docs) {
        await msg.reference.delete();
      }
      await convDoc.reference.delete();
    }

    final todayId = DateTime.now().toIso8601String().split("T").first;

    await _firestore
        .collection("users")
        .doc(uid)
        .collection("conversations")
        .doc(todayId)
        .set({
      "createdAt": FieldValue.serverTimestamp(),
    });
  }

  static Future<void> deleteAccountCompletely() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final uid = user.uid;

    final traitsSnap = await _firestore
        .collection("users")
        .doc(uid)
        .collection("profile_memory")
        .get();
    for (final d in traitsSnap.docs) {
      await d.reference.delete();
    }

    await clearAllConversations();

    await _firestore.collection("users").doc(uid).delete();

    await user.delete();
  }
}
