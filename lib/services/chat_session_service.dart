import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/chat_session.dart';
import 'package:syra/core/syra_log.dart';

/// ═══════════════════════════════════════════════════════════════
/// CHAT SESSION SERVICE — Manages chat session CRUD operations
/// ═══════════════════════════════════════════════════════════════
///
/// Responsibilities:
/// - Create, read, update, delete chat sessions
/// - Load messages for a session
/// - Save messages to a session
///
/// Module 3 improvements:
/// - Added SessionResult for structured error handling
/// - Wrapped all Firestore operations in try-catch
/// - Enhanced logging
/// - Better error messages
///
/// FIRESTORE STRUCTURE (DO NOT CHANGE):
/// users/{uid}/chat_sessions/{sessionId}
///   - title: string
///   - createdAt: timestamp
///   - lastUpdatedAt: timestamp
///   - messageCount: int
///   - lastMessage: string?
///
///   messages/{messageId}
///     - sender: string ("user" | "bot")
///     - text: string
///     - timestamp: timestamp
///     - ...other fields
/// ═══════════════════════════════════════════════════════════════

/// Result type for session operations
class SessionResult {
  /// Whether the operation was successful
  final bool success;

  /// Session ID (if applicable and success)
  final String? sessionId;

  /// List of sessions (if applicable and success)
  final List<ChatSession>? sessions;

  /// List of messages (if applicable and success)
  final List<Map<String, dynamic>>? messages;

  /// User-friendly error message (if !success)
  final String? errorMessage;

  /// Technical error details for logging (if !success)
  final String? debugMessage;

  const SessionResult({
    required this.success,
    this.sessionId,
    this.sessions,
    this.messages,
    this.errorMessage,
    this.debugMessage,
  });

  /// Create a successful result
  factory SessionResult.success({
    String? sessionId,
    List<ChatSession>? sessions,
    List<Map<String, dynamic>>? messages,
  }) {
    return SessionResult(
      success: true,
      sessionId: sessionId,
      sessions: sessions,
      messages: messages,
    );
  }

  /// Create an error result
  factory SessionResult.error({
    required String errorMessage,
    String? debugMessage,
  }) {
    return SessionResult(
      success: false,
      errorMessage: errorMessage,
      debugMessage: debugMessage,
    );
  }
}

class ChatSessionService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection names (DO NOT CHANGE)
  static const String _usersCollection = 'users';
  static const String _sessionsSubcollection = 'chat_sessions';
  static const String _messagesSubcollection = 'messages';

  // ═══════════════════════════════════════════════════════════════
  // SESSION CRUD OPERATIONS
  // ═══════════════════════════════════════════════════════════════

  /// Get all chat sessions for the current user
  ///
  /// Returns SessionResult with sessions list or error
  static Future<SessionResult> getUserSessions() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        syraLog("⚠️ [ChatSessionService] No authenticated user");
        return SessionResult.success(sessions: []);
      }

      syraLog(
          "📥 [ChatSessionService] Loading sessions for user: ${user.uid}");

      final snapshot = await _firestore
          .collection(_usersCollection)
          .doc(user.uid)
          .collection(_sessionsSubcollection)
          .orderBy('lastUpdatedAt', descending: true)
          .get();

      final sessions = snapshot.docs
          .map((doc) => ChatSession.fromMap(doc.data(), doc.id))
          .toList();

      syraLog("✅ [ChatSessionService] Loaded ${sessions.length} sessions");
      return SessionResult.success(sessions: sessions);
    } on FirebaseException catch (e) {
      syraLog(
          "❌ [ChatSessionService] FirebaseException in getUserSessions: ${e.code} - ${e.message}");
      return SessionResult.error(
        errorMessage: "Sohbetler yüklenemedi. Tekrar dene.",
        debugMessage: "FirebaseException: ${e.code} - ${e.message}",
      );
    } catch (e, stackTrace) {
      syraLog(
          "❌ [ChatSessionService] Error in getUserSessions: $e\n$stackTrace");
      return SessionResult.error(
        errorMessage: "Sohbetler yüklenirken hata oluştu.",
        debugMessage: "Error: $e",
      );
    }
  }

  /// Create a new chat session
  ///
  /// Returns SessionResult with new session ID or error
  static Future<SessionResult> createSession({String? title}) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        syraLog("⚠️ [ChatSessionService] No authenticated user");
        return SessionResult.error(
          errorMessage: "Oturum oluşturulamadı. Giriş yapmalısın.",
          debugMessage: "User not authenticated",
        );
      }

      final now = DateTime.now();
      final sessionData = {
        'title': title ?? 'Yeni Sohbet',
        'createdAt': now,
        'lastUpdatedAt': now,
        'messageCount': 0,
        'lastMessage': null,
      };

      syraLog(
          "📤 [ChatSessionService] Creating session: ${sessionData['title']}");

      final docRef = await _firestore
          .collection(_usersCollection)
          .doc(user.uid)
          .collection(_sessionsSubcollection)
          .add(sessionData);

      syraLog("✅ [ChatSessionService] Session created: ${docRef.id}");
      return SessionResult.success(sessionId: docRef.id);
    } on FirebaseException catch (e) {
      syraLog(
          "❌ [ChatSessionService] FirebaseException in createSession: ${e.code} - ${e.message}");
      return SessionResult.error(
        errorMessage: "Yeni sohbet oluşturulamadı. Tekrar dene.",
        debugMessage: "FirebaseException: ${e.code} - ${e.message}",
      );
    } catch (e, stackTrace) {
      syraLog(
          "❌ [ChatSessionService] Error in createSession: $e\n$stackTrace");
      return SessionResult.error(
        errorMessage: "Sohbet oluşturulurken hata oluştu.",
        debugMessage: "Error: $e",
      );
    }
  }

  /// Update an existing chat session
  ///
  /// Updates lastMessage, title, or messageCount
  /// Returns SessionResult (success/error)
  static Future<SessionResult> updateSession({
    required String sessionId,
    String? lastMessage,
    String? title,
    int? messageCount,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        syraLog("⚠️ [ChatSessionService] No authenticated user");
        return SessionResult.error(
          errorMessage: "Oturum güncellenemedi.",
          debugMessage: "User not authenticated",
        );
      }

      // Build update data
      final updateData = <String, dynamic>{
        'lastUpdatedAt': DateTime.now(),
      };

      if (lastMessage != null) updateData['lastMessage'] = lastMessage;
      if (title != null) updateData['title'] = title;
      if (messageCount != null) updateData['messageCount'] = messageCount;

      syraLog("📤 [ChatSessionService] Updating session: $sessionId");

      await _firestore
          .collection(_usersCollection)
          .doc(user.uid)
          .collection(_sessionsSubcollection)
          .doc(sessionId)
          .update(updateData);

      syraLog("✅ [ChatSessionService] Session updated: $sessionId");
      return SessionResult.success();
    } on FirebaseException catch (e) {
      syraLog(
          "❌ [ChatSessionService] FirebaseException in updateSession: ${e.code} - ${e.message}");
      return SessionResult.error(
        errorMessage: "Sohbet güncellenemedi.",
        debugMessage: "FirebaseException: ${e.code} - ${e.message}",
      );
    } catch (e, stackTrace) {
      syraLog(
          "❌ [ChatSessionService] Error in updateSession: $e\n$stackTrace");
      return SessionResult.error(
        errorMessage: "Sohbet güncellenirken hata oluştu.",
        debugMessage: "Error: $e",
      );
    }
  }

  /// Rename a chat session
  ///
  /// Returns SessionResult (success/error)
  static Future<SessionResult> renameSession({
    required String sessionId,
    required String newTitle,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        syraLog("⚠️ [ChatSessionService] No authenticated user");
        return SessionResult.error(
          errorMessage: "Sohbet adı değiştirilemedi.",
          debugMessage: "User not authenticated",
        );
      }

      syraLog(
          "📤 [ChatSessionService] Renaming session: $sessionId → $newTitle");

      await _firestore
          .collection(_usersCollection)
          .doc(user.uid)
          .collection(_sessionsSubcollection)
          .doc(sessionId)
          .update({
        'title': newTitle,
        'lastUpdatedAt': DateTime.now(),
      });

      syraLog("✅ [ChatSessionService] Session renamed: $sessionId");
      return SessionResult.success();
    } on FirebaseException catch (e) {
      syraLog(
          "❌ [ChatSessionService] FirebaseException in renameSession: ${e.code} - ${e.message}");
      return SessionResult.error(
        errorMessage: "Sohbet adı değiştirilemedi.",
        debugMessage: "FirebaseException: ${e.code} - ${e.message}",
      );
    } catch (e, stackTrace) {
      syraLog(
          "❌ [ChatSessionService] Error in renameSession: $e\n$stackTrace");
      return SessionResult.error(
        errorMessage: "Sohbet adı değiştirilirken hata oluştu.",
        debugMessage: "Error: $e",
      );
    }
  }

  /// Delete a chat session AND ALL ITS MESSAGES
  ///
  /// Returns SessionResult (success/error)
  static Future<SessionResult> deleteSession(String sessionId) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        syraLog("⚠️ [ChatSessionService] No authenticated user");
        return SessionResult.error(
          errorMessage: "Sohbet silinemedi.",
          debugMessage: "User not authenticated",
        );
      }

      syraLog("📤 [ChatSessionService] Deleting session: $sessionId");

      // ═══════════════════════════════════════════════════════════
      // CRITICAL FIX: Delete ALL messages first, then delete session
      // ═══════════════════════════════════════════════════════════

      final messagesRef = _firestore
          .collection(_usersCollection)
          .doc(user.uid)
          .collection(_sessionsSubcollection)
          .doc(sessionId)
          .collection(_messagesSubcollection);

      // Get all messages
      final messagesSnapshot = await messagesRef.get();

      syraLog(
          "🗑️ [ChatSessionService] Deleting ${messagesSnapshot.docs.length} messages from session $sessionId");

      // Delete messages in batches (Firestore batch limit = 500)
      var batch = _firestore.batch(); // Use 'var' instead of 'final'
      int batchCount = 0;

      for (final doc in messagesSnapshot.docs) {
        batch.delete(doc.reference);
        batchCount++;

        // Commit batch every 500 operations
        if (batchCount >= 500) {
          await batch.commit();
          batch = _firestore.batch(); // Create new batch after commit
          batchCount = 0;
          syraLog(
              "🗑️ [ChatSessionService] Committed batch of 500 message deletes");
        }
      }

      // Commit remaining deletions
      if (batchCount > 0) {
        await batch.commit();
      }

      syraLog("✅ [ChatSessionService] All messages deleted");

      // Now delete the session document itself
      await _firestore
          .collection(_usersCollection)
          .doc(user.uid)
          .collection(_sessionsSubcollection)
          .doc(sessionId)
          .delete();

      syraLog("✅ [ChatSessionService] Session deleted: $sessionId");

      // ═══════════════════════════════════════════════════════════════
      // MODULE 2: Delete backend conversation history for this session
      // ═══════════════════════════════════════════════════════════════
      try {
        final conversationHistoryRef = _firestore
            .collection("conversation_history")
            .doc(user.uid)
            .collection("sessions")
            .doc(sessionId);

        await conversationHistoryRef.delete();
        syraLog(
            "✅ [ChatSessionService] Backend conversation history deleted for session: $sessionId");
      } catch (e) {
        // Non-critical error - session is already deleted from UI
        syraLog(
            "⚠️ [ChatSessionService] Failed to delete backend history (non-critical): $e");
      }

      return SessionResult.success();
    } on FirebaseException catch (e) {
      syraLog(
          "❌ [ChatSessionService] FirebaseException in deleteSession: ${e.code} - ${e.message}");
      return SessionResult.error(
        errorMessage: "Sohbet silinemedi.",
        debugMessage: "FirebaseException: ${e.code} - ${e.message}",
      );
    } catch (e, stackTrace) {
      syraLog(
          "❌ [ChatSessionService] Error in deleteSession: $e\n$stackTrace");
      return SessionResult.error(
        errorMessage: "Sohbet silinirken hata oluştu.",
        debugMessage: "Error: $e",
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // MESSAGE OPERATIONS
  // ═══════════════════════════════════════════════════════════════

  /// Get all messages for a session
  ///
  /// Returns SessionResult with messages list or error
  static Future<SessionResult> getSessionMessages(String sessionId) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        syraLog("⚠️ [ChatSessionService] No authenticated user");
        return SessionResult.success(messages: []);
      }

      syraLog(
          "📥 [ChatSessionService] Loading messages for session: $sessionId");

      final snapshot = await _firestore
          .collection(_usersCollection)
          .doc(user.uid)
          .collection(_sessionsSubcollection)
          .doc(sessionId)
          .collection(_messagesSubcollection)
          .orderBy('timestamp', descending: false)
          .get();

      final messages = snapshot.docs.map((doc) => doc.data()).toList();

      syraLog("✅ [ChatSessionService] Loaded ${messages.length} messages");
      return SessionResult.success(messages: messages);
    } on FirebaseException catch (e) {
      syraLog(
          "❌ [ChatSessionService] FirebaseException in getSessionMessages: ${e.code} - ${e.message}");
      return SessionResult.error(
        errorMessage: "Mesajlar yüklenemedi.",
        debugMessage: "FirebaseException: ${e.code} - ${e.message}",
      );
    } catch (e, stackTrace) {
      syraLog(
          "❌ [ChatSessionService] Error in getSessionMessages: $e\n$stackTrace");
      return SessionResult.error(
        errorMessage: "Mesajlar yüklenirken hata oluştu.",
        debugMessage: "Error: $e",
      );
    }
  }

  /// Add a message to a session
  ///
  /// Returns SessionResult (success/error)
  static Future<SessionResult> addMessageToSession({
    required String sessionId,
    required Map<String, dynamic> message,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        syraLog("⚠️ [ChatSessionService] No authenticated user");
        return SessionResult.error(
          errorMessage: "Mesaj kaydedilemedi.",
          debugMessage: "User not authenticated",
        );
      }

      syraLog(
          "📤 [ChatSessionService] Adding message to session: $sessionId");

      await _firestore
          .collection(_usersCollection)
          .doc(user.uid)
          .collection(_sessionsSubcollection)
          .doc(sessionId)
          .collection(_messagesSubcollection)
          .add(message);

      syraLog("✅ [ChatSessionService] Message added to session: $sessionId");
      return SessionResult.success();
    } on FirebaseException catch (e) {
      syraLog(
          "❌ [ChatSessionService] FirebaseException in addMessageToSession: ${e.code} - ${e.message}");
      return SessionResult.error(
        errorMessage: "Mesaj kaydedilemedi.",
        debugMessage: "FirebaseException: ${e.code} - ${e.message}",
      );
    } catch (e, stackTrace) {
      syraLog(
          "❌ [ChatSessionService] Error in addMessageToSession: $e\n$stackTrace");
      return SessionResult.error(
        errorMessage: "Mesaj kaydedilirken hata oluştu.",
        debugMessage: "Error: $e",
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // MESSAGE FEEDBACK (Like/Dislike)
  // ═══════════════════════════════════════════════════════════════

  /// Set feedback for a specific message
  ///
  /// @param sessionId - The session containing the message
  /// @param messageId - The message ID (stored as 'id' field in message doc)
  /// @param feedback - 'like', 'dislike', or null to clear
  ///
  /// Persists to Firestore (primary) and SharedPreferences (fallback)
  static Future<SessionResult> setMessageFeedback({
    required String sessionId,
    required String messageId,
    required String? feedback, // 'like' | 'dislike' | null
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        return SessionResult.error(
          errorMessage: "Kullanıcı girişi gerekli",
          debugMessage: "User not authenticated",
        );
      }

      syraLog(
          "📝 [ChatSessionService] Setting feedback for message $messageId: $feedback");

      // 1. Save to SharedPreferences (local fallback)
      await _saveFeedbackToPrefs(messageId, feedback);

      // 2. Update Firestore
      try {
        final messagesRef = _firestore
            .collection(_usersCollection)
            .doc(user.uid)
            .collection(_sessionsSubcollection)
            .doc(sessionId)
            .collection(_messagesSubcollection);

        // Find message by 'id' field
        final querySnapshot =
            await messagesRef.where('id', isEqualTo: messageId).limit(1).get();

        if (querySnapshot.docs.isEmpty) {
          syraLog(
              "⚠️ [ChatSessionService] Message not found in Firestore: $messageId");
          // Still return success since we saved to SharedPreferences
          return SessionResult.success();
        }

        final messageDoc = querySnapshot.docs.first;
        await messageDoc.reference.update({
          'feedback': feedback,
          'feedbackAt': FieldValue.serverTimestamp(),
        });

        syraLog("✅ [ChatSessionService] Feedback saved to Firestore");
      } catch (firestoreError) {
        syraLog(
            "⚠️ [ChatSessionService] Firestore save failed, using local fallback: $firestoreError");
        // Continue - we already saved to SharedPreferences
      }

      return SessionResult.success();
    } catch (e, stackTrace) {
      syraLog(
          "❌ [ChatSessionService] Error in setMessageFeedback: $e\n$stackTrace");
      return SessionResult.error(
        errorMessage: "Geri bildirim kaydedilemedi.",
        debugMessage: "Error: $e",
      );
    }
  }

  /// Save feedback to SharedPreferences (local fallback)
  static Future<void> _saveFeedbackToPrefs(
      String messageId, String? feedback) async {
    final prefs = await SharedPreferences.getInstance();
    final key = "msg_feedback_$messageId";

    if (feedback == null || feedback.isEmpty) {
      await prefs.remove(key);
    } else {
      await prefs.setString(key, feedback);
    }
  }

  /// Load feedback from SharedPreferences
  static Future<String?> _loadFeedbackFromPrefs(String messageId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = "msg_feedback_$messageId";
    return prefs.getString(key);
  }

  /// Inject feedback from SharedPreferences into messages
  /// Call this when loading messages to merge local feedback
  static Future<void> injectLocalFeedback(
      List<Map<String, dynamic>> messages) async {
    for (final msg in messages) {
      final messageId = msg['id'] as String?;
      if (messageId != null && msg['feedback'] == null) {
        final localFeedback = await _loadFeedbackFromPrefs(messageId);
        if (localFeedback != null) {
          msg['feedback'] = localFeedback;
        }
      }
    }
  }
}
