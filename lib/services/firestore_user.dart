import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreUser {
  static final _firestore = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;

  // -------------------------------------------------------------------------
  // 🔗 USER REF
  // -------------------------------------------------------------------------
  static DocumentReference<Map<String, dynamic>> _userRef() {
    final uid = _auth.currentUser?.uid;
    return _firestore.collection("users").doc(uid);
  }

  // -------------------------------------------------------------------------
  // 🔥 GET USER DATA
  // -------------------------------------------------------------------------
  static Future<Map<String, dynamic>?> getUserData() async {
    final snap = await _userRef().get();
    return snap.data();
  }

  // -------------------------------------------------------------------------
  // ⭐ PREMIUM FLAG
  // -------------------------------------------------------------------------
  static Future<bool> isPremium() async {
    final data = await getUserData();
    return data?["isPremium"] == true;
  }

  static Future<void> upgradeToPremium() async {
    await _userRef().update({
      "isPremium": true,
      "dailyMessageLimit": 99999,
    });
  }

  // -------------------------------------------------------------------------
  // 👤 CREATE PROFILE
  // -------------------------------------------------------------------------
  static Future<void> createProfile(User user) async {
    await _firestore.collection("users").doc(user.uid).set({
      "uid": user.uid,
      "email": user.email ?? '',
      "createdAt": FieldValue.serverTimestamp(),

      // LIMIT SİSTEMİ
      "isPremium": false,
      "dailyMessageLimit": 10,
      "dailyMessageCount": 0,
      "lastMessageDate": DateTime.now().toIso8601String(),
      "cooldownEnd": null,

      // BOT AYARLARI
      "botCharacter": "default",
      "replyLength": "default",
      "notifDaily": true,
      "notifOffers": true,
    });
  }

  // -------------------------------------------------------------------------
  // 💬 LIMIT SYSTEM
  // -------------------------------------------------------------------------
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

    return {
      "isPremium": data?["isPremium"] ?? false,
      "limit": data?["dailyMessageLimit"] ?? 10,
      "count": data?["dailyMessageCount"] ?? 0,
      "lastMessageDate":
          DateTime.tryParse(data?["lastMessageDate"] ?? "") ?? DateTime.now(),
      "cooldownEnd": data?["cooldownEnd"],
    };
  }

  // -------------------------------------------------------------------------
  // 💬 CHAT HISTORY — (save/get)
  // -------------------------------------------------------------------------
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

  // -------------------------------------------------------------------------
  // 🧠 PREMIUM TRAIT MEMORY
  // -------------------------------------------------------------------------
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

  // -------------------------------------------------------------------------
  // ⚙️ SETTINGS (bot tarzı, uzunluk, bildirimler)
  // -------------------------------------------------------------------------
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

  // -------------------------------------------------------------------------
  // 🧹 CLEAR MESSAGE HISTORY — SYRA FINAL PATCH
  // -------------------------------------------------------------------------
  static Future<void> clearAllConversations() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final convSnap = await _firestore
        .collection("users")
        .doc(uid)
        .collection("conversations")
        .get();

    // 1) Tüm konuşmaları ve mesajları sil
    for (final convDoc in convSnap.docs) {
      final msgsSnap = await convDoc.reference.collection("messages").get();
      for (final msg in msgsSnap.docs) {
        await msg.reference.delete();
      }
      await convDoc.reference.delete();
    }

    // 2) SYRA FIX → Bugünün konuşmasını boş şekilde yeniden oluştur
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

  // -------------------------------------------------------------------------
  // 💣 DELETE ACCOUNT COMPLETELY — **FULL WORKING**
  // -------------------------------------------------------------------------
  static Future<void> deleteAccountCompletely() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final uid = user.uid;

    // traits
    final traitsSnap = await _firestore
        .collection("users")
        .doc(uid)
        .collection("profile_memory")
        .get();
    for (final d in traitsSnap.docs) {
      await d.reference.delete();
    }

    // chat history
    await clearAllConversations();

    // delete root user document
    await _firestore.collection("users").doc(uid).delete();

    // delete authentication account
    await user.delete();
  }
}
