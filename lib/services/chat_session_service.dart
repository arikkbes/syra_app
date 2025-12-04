// ═══════════════════════════════════════════════════════════════
// ═══════════════════════════════════════════════════════════════
// ═══════════════════════════════════════════════════════════════
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/chat_session.dart';

class ChatSessionService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ─────────────────────────────────────────────────────────────
  // ─────────────────────────────────────────────────────────────
  static Future<List<ChatSession>> getUserSessions() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return [];

      final snapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('chat_sessions')
          .orderBy('lastUpdatedAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => ChatSession.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('getUserSessions error: $e');
      return [];
    }
  }

  // ─────────────────────────────────────────────────────────────
  // ─────────────────────────────────────────────────────────────
  static Future<String?> createSession({String? title}) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return null;

      final now = DateTime.now();
      final sessionData = {
        'title': title ?? 'Yeni Sohbet',
        'createdAt': now,
        'lastUpdatedAt': now,
        'messageCount': 0,
        'lastMessage': null,
      };

      final docRef = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('chat_sessions')
          .add(sessionData);

      return docRef.id;
    } catch (e) {
      print('createSession error: $e');
      return null;
    }
  }

  // ─────────────────────────────────────────────────────────────
  // ─────────────────────────────────────────────────────────────
  static Future<void> updateSession({
    required String sessionId,
    String? lastMessage,
    String? title,
    int? messageCount,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final updateData = <String, dynamic>{
        'lastUpdatedAt': DateTime.now(),
      };

      if (lastMessage != null) updateData['lastMessage'] = lastMessage;
      if (title != null) updateData['title'] = title;
      if (messageCount != null) updateData['messageCount'] = messageCount;

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('chat_sessions')
          .doc(sessionId)
          .update(updateData);
    } catch (e) {
      print('updateSession error: $e');
    }
  }

  // ─────────────────────────────────────────────────────────────
  // ─────────────────────────────────────────────────────────────
  static Future<void> deleteSession(String sessionId) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('chat_sessions')
          .doc(sessionId)
          .delete();
    } catch (e) {
      print('deleteSession error: $e');
    }
  }

  // ─────────────────────────────────────────────────────────────
  // ─────────────────────────────────────────────────────────────
  static Future<List<Map<String, dynamic>>> getSessionMessages(
    String sessionId,
  ) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return [];

      final snapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('chat_sessions')
          .doc(sessionId)
          .collection('messages')
          .orderBy('timestamp', descending: false)
          .get();

      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      print('getSessionMessages error: $e');
      return [];
    }
  }

  // ─────────────────────────────────────────────────────────────
  // ─────────────────────────────────────────────────────────────
  static Future<void> addMessageToSession({
    required String sessionId,
    required Map<String, dynamic> message,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('chat_sessions')
          .doc(sessionId)
          .collection('messages')
          .add(message);
    } catch (e) {
      print('addMessageToSession error: $e');
    }
  }
}
