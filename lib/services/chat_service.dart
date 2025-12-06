import 'dart:convert';
import 'dart:io'; // SocketException için
import 'dart:async'; // TimeoutException için
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firestore_user.dart';

/// CHAT SERVICE — Handles chat logic, message limits, premium checks.
class ChatService {
  static const String _endpoint =
      "https://us-central1-syra-ai-b562f.cloudfunctions.net/flortIQChat";

  // ═══════════════════════════════════════════════════════════════
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
  // ═══════════════════════════════════════════════════════════════

  static Future<String> sendMessage({
    required String userMessage,
    required List<Map<String, dynamic>> conversationHistory,
    Map<String, dynamic>? replyingTo,
    required String mode,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        return "Oturumun düşmüş gibi duruyor kanka. Çıkış yapıp tekrar giriş yapmayı dene.";
      }

      final idToken = await user.getIdToken();

      final context = _buildConversationContext(
        conversationHistory,
        replyingTo,
      );

      final uri = Uri.parse(_endpoint);

      final response = await http.post(
        uri,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $idToken",
        },
        body: jsonEncode({
          "message": userMessage,
          "context": context,
          "mode": mode,
        }),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception("Timeout");
        },
      );

      final rawBody = response.body;
      Map<String, dynamic>? jsonBody;

      if (rawBody.isNotEmpty) {
        try {
          jsonBody = jsonDecode(rawBody) as Map<String, dynamic>;
        } catch (e) {
          debugPrint("JSON parse error: $e\nBody: $rawBody");
        }
      }

      // ✅ 200 OK - Başarılı yanıt
      if (response.statusCode == 200) {
        final text = jsonBody?["message"] ??
            jsonBody?["response"] ??
            jsonBody?["reply"] ??
            jsonBody?["text"] ??
            "Bir hata oluştu.";
        return text.toString();
      }

      // ❌ 401 Unauthorized - API key veya token hatası
      if (response.statusCode == 401) {
        debugPrint("401 Unauthorized: Invalid API key or token");
        return "Yetki hatası. Çıkış yapıp tekrar giriş yapmayı dene.";
      }

      // ⏱️ 408 Request Timeout
      if (response.statusCode == 408) {
        debugPrint("408 Request Timeout");
        return "İstek zaman aşımına uğradı. Tekrar dene kanka.";
      }

      // 🚫 429 Rate Limit
      if (response.statusCode == 429) {
        return (jsonBody?["message"] as String?) ??
            "Günlük mesaj limitine ulaştın. Premium'a geç veya yarın tekrar dene.";
      }

      // 🔥 500 Server Error
      if (response.statusCode == 500) {
        debugPrint("500 Server Error");
        return "Sunucu hatası oluştu. Birkaç dakika sonra tekrar dene.";
      }

      // 🔧 503 Service Unavailable
      if (response.statusCode == 503) {
        debugPrint("503 Service Unavailable");
        return "Servis şu an bakımda. Birazdan tekrar dene kanka.";
      }

      // Diğer backend hatalarında message varsa onu göster
      final backendMessage = jsonBody?["message"] as String?;
      if (backendMessage != null && backendMessage.isNotEmpty) {
        return backendMessage;
      }

      debugPrint(
        "API error: ${response.statusCode} | body: ${response.body}",
      );
      return "Sunucu hatası: ${response.statusCode}. Birazdan tekrar dene kanka.";
    } on SocketException catch (e) {
      debugPrint("SocketException in sendMessage: $e");
      return "Bağlantı hatası. İnterneti kontrol et ve tekrar dene.";
    } on TimeoutException catch (e) {
      debugPrint("TimeoutException in sendMessage: $e");
      return "İstek zaman aşımına uğradı. Tekrar dene kanka.";
    } on FirebaseAuthException catch (e) {
      debugPrint("FirebaseAuthException in sendMessage: $e");
      return "Oturumunla ilgili bir sorun var gibi. Çıkış yapıp tekrar giriş yapmayı dene.";
    } on Exception catch (e) {
      if (e.toString().contains("Timeout")) {
        return "Bağlantı zaman aşımına uğradı. Tekrar dene kanka.";
      }
      debugPrint("sendMessage Exception: $e");
      return "Beklenmedik bir hata oluştu. Birazdan tekrar dene.";
    } catch (e, st) {
      debugPrint("sendMessage UNEXPECTED error: $e\n$st");
      return "Kanka beklenmedik bir hata oldu. Birazdan tekrar dene.";
    }
  }

  // ═══════════════════════════════════════════════════════════════
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
