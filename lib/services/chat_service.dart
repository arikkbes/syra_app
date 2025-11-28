import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';

import '../services/firestore_user.dart';

/// CHAT SERVICE — Handles chat logic, message limits, premium checks.
class ChatService {
  // ═══════════════════════════════════════════════════════════════
  // USER STATUS
  // ═══════════════════════════════════════════════════════════════

  static Future<Map<String, dynamic>> getUserStatus() async {
    try {
      final status = await FirestoreUser.getMessageStatus();

      final bool isPremium = status["isPremium"] == true;

      int limit =
          status["limit"] is num ? (status["limit"] as num).toInt() : 10;
      int count = status["count"] is num ? (status["count"] as num).toInt() : 0;

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
  // SEND MESSAGE TO AI
  // ═══════════════════════════════════════════════════════════════

  static Future<String> sendMessage({
    required String userMessage,
    required List<Map<String, dynamic>> conversationHistory,
    Map<String, dynamic>? replyingTo,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception("User not authenticated");
      }

      final idToken = await user.getIdToken();

      final context = _buildConversationContext(
        conversationHistory,
        replyingTo,
      );

      // 🔥 DOĞRU BACKEND URL — Cloud Function v2 (run.app)
      final uri = Uri.parse(
        "https://us-central1-syra-ai-b562f.cloudfunctions.net/flortIQChat",
      );

      final response = await http.post(
        uri,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $idToken",
        },
        body: jsonEncode({
          "message": userMessage,
          "context": context,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data["response"] ?? "Bir hata oluştu.";
      } else if (response.statusCode == 429) {
        return "Günlük mesaj limitine ulaştın. Premium'a geç veya yarın tekrar dene.";
      } else {
        debugPrint("API error: ${response.statusCode}");
        debugPrint("Body: ${response.body}");
        return "Sunucu hatası: ${response.statusCode}";
      }
    } catch (e) {
      debugPrint("sendMessage error: $e");
      return "Bağlantı hatası. İnterneti kontrol et ve tekrar dene.";
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // CONTEXT BUILDER
  // ═══════════════════════════════════════════════════════════════

  static List<Map<String, String>> _buildConversationContext(
    List<Map<String, dynamic>> history,
    Map<String, dynamic>? replyingTo,
  ) {
    final context = <Map<String, String>>[];

    if (replyingTo != null) {
      context.add({
        "role": replyingTo['sender'] == "user" ? "user" : "assistant",
        "content": "[Replying to: ${replyingTo['text']}]",
      });
    }

    final last10 =
        history.length > 10 ? history.sublist(history.length - 10) : history;

    for (final msg in last10) {
      context.add({
        "role": msg['sender'] == "user" ? "user" : "assistant",
        "content": msg["text"] ?? "",
      });
    }

    return context;
  }

  // ═══════════════════════════════════════════════════════════════
  // MESSAGE LIMITS
  // ═══════════════════════════════════════════════════════════════

  static Future<bool> canSendMessage({
    required bool isPremium,
    required int messageCount,
    required int dailyLimit,
  }) async {
    if (isPremium) return true;
    return messageCount < dailyLimit;
  }

  static Future<void> incrementMessageCount() async {
    try {
      await FirestoreUser.incrementMessageCount();
    } catch (e) {
      debugPrint("incrementMessageCount error: $e");
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // MANIPULATION DETECTOR
  // ═══════════════════════════════════════════════════════════════

  static Map<String, bool> detectManipulation(String text) {
    final lower = text.toLowerCase();

    final red = [
      "gaslighting",
      "love bombing",
      "guilt trip",
      "silent treatment",
      "projection",
      "triangulation",
      "hoovering",
      "kırmızı bayrak",
      "manipulation",
      "manipülasyon",
      "red flag",
    ];

    final green = [
      "healthy boundary",
      "mutual respect",
      "clear communication",
      "emotional support",
      "yeşil bayrak",
      "healthy",
      "green flag",
    ];

    return {
      "hasRed": red.any(lower.contains),
      "hasGreen": green.any(lower.contains),
    };
  }
}
