import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';

import '../services/firestore_user.dart';

/// ═══════════════════════════════════════════════════════════════
/// CHAT SERVICE - Handles all chat logic, networking and state
/// ═══════════════════════════════════════════════════════════════
/// This service manages:
/// - AI message sending and receiving
/// - Premium status checks
/// - Message limits and counting
/// - Chat history management
class ChatService {
  // ═══════════════════════════════════════════════════════════════
  // USER STATUS
  // ═══════════════════════════════════════════════════════════════

  /// Get user's premium status and message limits
  static Future<Map<String, dynamic>> getUserStatus() async {
    try {
      final status = await FirestoreUser.getMessageStatus();

      // Safe type casting with defaults
      final bool isPremium = status["isPremium"] == true;

      int limit = 10;
      if (status["limit"] is int) {
        limit = status["limit"];
      } else if (status["limit"] is num) {
        limit = (status["limit"] as num).toInt();
      }

      int count = 0;
      if (status["count"] is int) {
        count = status["count"];
      } else if (status["count"] is num) {
        count = (status["count"] as num).toInt();
      }

      return {
        'isPremium': isPremium,
        'limit': limit <= 0 ? 10 : limit,
        'count': count.clamp(0, limit <= 0 ? 10 : limit),
      };
    } catch (e) {
      debugPrint("getUserStatus error: $e");
      return {
        'isPremium': false,
        'limit': 10,
        'count': 0,
      };
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // MESSAGE SENDING
  // ═══════════════════════════════════════════════════════════════

  /// Send a message to the AI backend
  /// Returns the AI's response text
  static Future<String> sendMessage({
    required String userMessage,
    required List<Map<String, dynamic>> conversationHistory,
    Map<String, dynamic>? replyingTo,
  }) async {
    try {
      // Get current user
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Get ID token for auth
      final idToken = await user.getIdToken();

      // Build conversation history for context
      final context = _buildConversationContext(
        conversationHistory,
        replyingTo,
      );

      // Make API call
      final response = await http.post(
        Uri.parse(
            'https://syra-ai-backend-xmepqihmza-uc.a.run.app/api/syra/chat'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
        body: jsonEncode({
          'message': userMessage,
          'context': context,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['response'] ?? 'Üzgünüm, bir hata oluştu.';
      } else if (response.statusCode == 429) {
        // Rate limit hit
        return 'Günlük mesaj limitine ulaştın. Premium\'a geç veya yarın tekrar dene.';
      } else {
        throw Exception('API error: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('sendMessage error: $e');
      return 'Bağlantı hatası. İnterneti kontrol et ve tekrar dene.';
    }
  }

  /// Build conversation context from history
  static List<Map<String, String>> _buildConversationContext(
    List<Map<String, dynamic>> history,
    Map<String, dynamic>? replyingTo,
  ) {
    final context = <Map<String, String>>[];

    // Add reply context if replying to a specific message
    if (replyingTo != null) {
      context.add({
        'role': replyingTo['sender'] == 'user' ? 'user' : 'assistant',
        'content': '[Replying to: ${replyingTo['text']}]',
      });
    }

    // Add recent conversation history (last 10 messages)
    final recentMessages = history.length > 10
        ? history.sublist(history.length - 10)
        : history;

    for (final msg in recentMessages) {
      context.add({
        'role': msg['sender'] == 'user' ? 'user' : 'assistant',
        'content': msg['text'] ?? '',
      });
    }

    return context;
  }

  // ═══════════════════════════════════════════════════════════════
  // MESSAGE LIMITS
  // ═══════════════════════════════════════════════════════════════

  /// Check if user can send a message
  static Future<bool> canSendMessage({
    required bool isPremium,
    required int messageCount,
    required int dailyLimit,
  }) async {
    // Premium users have no limits
    if (isPremium) return true;

    // Check if under limit
    return messageCount < dailyLimit;
  }

  /// Increment message count
  static Future<void> incrementMessageCount() async {
    try {
      await FirestoreUser.incrementMessageCount();
    } catch (e) {
      debugPrint('incrementMessageCount error: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // MANIPULATION DETECTION
  // ═══════════════════════════════════════════════════════════════

  /// Detect manipulation patterns in a message
  /// Returns map with 'hasRed' and 'hasGreen' flags
  static Map<String, bool> detectManipulation(String text) {
    final lowerText = text.toLowerCase();

    // Red flag patterns (manipulation tactics)
    final redPatterns = [
      'gaslighting',
      'love bombing',
      'guilt trip',
      'silent treatment',
      'projection',
      'triangulation',
      'hoovering',
      'kırmızı bayrak',
      'red flag',
      'manipülasyon',
      'manipulation',
    ];

    // Green flag patterns (healthy behaviors)
    final greenPatterns = [
      'healthy boundary',
      'mutual respect',
      'clear communication',
      'emotional support',
      'yeşil bayrak',
      'green flag',
      'sağlıklı',
      'healthy',
    ];

    final hasRed =
        redPatterns.any((pattern) => lowerText.contains(pattern));
    final hasGreen =
        greenPatterns.any((pattern) => lowerText.contains(pattern));

    return {
      'hasRed': hasRed,
      'hasGreen': hasGreen,
    };
  }
}
