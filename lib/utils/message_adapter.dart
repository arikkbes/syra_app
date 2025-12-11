import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:firebase_auth/firebase_auth.dart';

/// ═══════════════════════════════════════════════════════════════
/// MESSAGE ADAPTER
/// Maps SYRA's message format to flutter_chat_ui format
/// ═══════════════════════════════════════════════════════════════

class MessageAdapter {
  /// Convert SYRA message map to flutter_chat_ui Message
  static types.Message toFlutterChatMessage(Map<String, dynamic> syraMessage) {
    final String role = syraMessage['role'] ?? syraMessage['sender'] ?? 'user';
    final bool isUser = role == 'user';
    final String text = syraMessage['text'] ?? '';
    final String? imageUrl = syraMessage['imageUrl'];
    final DateTime? timestamp = syraMessage['timestamp'] ?? syraMessage['time'];
    final String messageId = syraMessage['id'] ?? DateTime.now().millisecondsSinceEpoch.toString();

    // Get current user ID for user messages
    final String userId = FirebaseAuth.instance.currentUser?.uid ?? 'user';
    final String authorId = isUser ? userId : 'syra';

    final author = types.User(
      id: authorId,
      firstName: isUser ? null : 'SYRA',
    );

    if (imageUrl != null && imageUrl.isNotEmpty) {
      // Image message
      return types.ImageMessage(
        id: messageId,
        author: author,
        createdAt: timestamp?.millisecondsSinceEpoch ?? DateTime.now().millisecondsSinceEpoch,
        uri: imageUrl,
        name: text.isEmpty ? 'Resim' : text,
        size: 0,
        metadata: {
          'role': role,
          'hasRedFlag': syraMessage['hasRedFlag'] ?? false,
          'hasGreenFlag': syraMessage['hasGreenFlag'] ?? false,
          'replyToText': syraMessage['replyToText'],
        },
      );
    } else {
      // Text message
      return types.TextMessage(
        id: messageId,
        author: author,
        createdAt: timestamp?.millisecondsSinceEpoch ?? DateTime.now().millisecondsSinceEpoch,
        text: text,
        metadata: {
          'role': role,
          'hasRedFlag': syraMessage['hasRedFlag'] ?? false,
          'hasGreenFlag': syraMessage['hasGreenFlag'] ?? false,
          'replyToText': syraMessage['replyToText'],
        },
      );
    }
  }

  /// Convert list of SYRA messages to flutter_chat_ui messages
  static List<types.Message> toFlutterChatMessages(List<Map<String, dynamic>> syraMessages) {
    return syraMessages.map((msg) => toFlutterChatMessage(msg)).toList();
  }

  /// Get current user for flutter_chat_ui
  static types.User getCurrentUser() {
    final userId = FirebaseAuth.instance.currentUser?.uid ?? 'user';
    return types.User(
      id: userId,
      firstName: 'Sen',
    );
  }
}

