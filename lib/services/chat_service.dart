import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_plan.dart';
import '../services/firestore_user.dart';
import '../services/api_endpoints.dart';
import 'package:syra/core/syra_log.dart';

/// ═══════════════════════════════════════════════════════════════
/// CHAT SERVICE — Handles chat logic, message limits, premium checks
/// ═══════════════════════════════════════════════════════════════
///
/// Responsibilities:
/// - Send messages to chat backend (syraChatV2)
/// - Parse responses
/// - Handle errors gracefully
/// - Manage message limits and premium status
///
/// Module 3 improvements:
/// - Added ChatSendResult for structured error handling
/// - Enhanced logging and error messages
/// - Better timeout and network error handling
/// ═══════════════════════════════════════════════════════════════

/// Result type for sendMessage operation
class ChatSendResult {
  /// Whether the message was sent successfully
  final bool success;

  /// The response message from the AI (if success)
  final String? responseText;

  /// User-friendly error message (if !success)
  final String? userMessage;

  /// Technical error details for logging (if !success)
  final String? debugMessage;

  const ChatSendResult({
    required this.success,
    this.responseText,
    this.userMessage,
    this.debugMessage,
  });

  /// Create a successful result
  factory ChatSendResult.success(String responseText) {
    return ChatSendResult(
      success: true,
      responseText: responseText,
    );
  }

  /// Create an error result
  factory ChatSendResult.error({
    required String userMessage,
    String? debugMessage,
  }) {
    return ChatSendResult(
      success: false,
      userMessage: userMessage,
      debugMessage: debugMessage,
    );
  }
}

class ChatService {
  static const String _endpoint = ApiEndpoints.syraChatV2;

  static const Duration _requestTimeout = Duration(seconds: 30);

  // ═══════════════════════════════════════════════════════════════
  // USER STATUS & LIMITS
  // ═══════════════════════════════════════════════════════════════

  /// Get current user's plan, premium status and message limits
  ///
  /// Returns a map with:
  /// - plan: UserPlan
  /// - isPremium: bool (derived from plan, for backward compat)
  /// - limit: int (daily message limit)
  /// - count: int (current message count)
  static Future<Map<String, dynamic>> getUserStatus() async {
    try {
      final status = await FirestoreUser.getMessageStatus();

      final UserPlan plan = status["plan"] is UserPlan
          ? status["plan"] as UserPlan
          : UserPlan.free;
      final bool isPremium = plan.isPaid;
      int limit =
          status["limit"] is num ? (status["limit"] as num).toInt() : 10;
      int count = status["count"] is num ? (status["count"] as num).toInt() : 0;

      // Normalize values
      if (limit <= 0) limit = 10;
      count = count.clamp(0, limit);

      return {
        'plan': plan,
        'isPremium': isPremium,
        'limit': limit,
        'count': count,
      };
    } catch (e) {
      syraLog("❌ [ChatService] getUserStatus error: $e");
      // Return safe defaults on error
      return {
        'plan': UserPlan.free,
        'isPremium': false,
        'limit': 10,
        'count': 0,
      };
    }
  }

  /// Check if user can send a message based on premium status and limits
  static Future<bool> canSendMessage({
    required bool isPremium,
    required int messageCount,
    required int dailyLimit,
  }) async {
    // Premium users have unlimited messages
    if (isPremium) return true;

    // Free users are limited
    return messageCount < dailyLimit;
  }

  /// Increment the user's daily message count
  ///
  /// This should be called after successfully sending a message
  static Future<void> incrementMessageCount() async {
    try {
      await FirestoreUser.incrementMessageCount();
      syraLog("✅ [ChatService] Message count incremented");
    } catch (e) {
      syraLog("❌ [ChatService] incrementMessageCount error: $e");
      // Non-critical error - don't throw, just log
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // MESSAGE SENDING
  // ═══════════════════════════════════════════════════════════════

  /// Send a message to the AI chat backend
  ///
  /// Parameters:
  /// - userMessage: The user's text message
  /// - conversationHistory: Previous messages for context
  /// - replyingTo: Optional message being replied to
  /// - mode: Chat mode (standard, dost_aci, tarot)
  /// - imageUrl: Optional image URL for vision analysis
  ///
  /// Returns ChatSendResult with success/error information
  static Future<ChatSendResult> sendMessage({
    required String userMessage,
    required String sessionId, // MODULE 1: Session ID
    required List<Map<String, dynamic>> conversationHistory,
    Map<String, dynamic>? replyingTo,
    required String mode,
    String? imageUrl,
  }) async {
    // Validate input
    if (userMessage.trim().isEmpty && imageUrl == null) {
      return ChatSendResult.error(
        userMessage: "Mesaj boş olamaz.",
        debugMessage: "Empty message and no image",
      );
    }

    try {
      // Check authentication
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        return ChatSendResult.error(
          userMessage:
              "Oturumun düşmüş gibi duruyor kanka. Çıkış yapıp tekrar giriş yapmayı dene.",
          debugMessage: "User not authenticated",
        );
      }

      syraLog(
          "📤 [ChatService] Sending message (mode: $mode, hasImage: ${imageUrl != null})");

      // Get auth token
      final idToken = await user.getIdToken();
      if (idToken == null) {
        return ChatSendResult.error(
          userMessage:
              "Yetki doğrulaması başarısız. Tekrar giriş yapmayı dene.",
          debugMessage: "Failed to get ID token",
        );
      }

      // Build request
      final context =
          _buildConversationContext(conversationHistory, replyingTo);
      final uri = Uri.parse(_endpoint);
      syraLog("CHAT_ENDPOINT: $uri");

      final requestBody = {
        "message": userMessage,
        "context": context,
        "mode": mode,
        "sessionId": sessionId, // MODULE 1: Include session ID
      };

      if (replyingTo != null && replyingTo["text"] != null) {
        requestBody["replyTo"] = {
          "role": replyingTo["sender"] == "user" ? "user" : "assistant",
          "content": replyingTo["text"],
        };
      }

      if (imageUrl != null && imageUrl.isNotEmpty) {
        requestBody["imageUrl"] = imageUrl;
      }

      // Send request
      final response = await http
          .post(
            uri,
            headers: {
              "Content-Type": "application/json",
              "Authorization": "Bearer $idToken",
            },
            body: jsonEncode(requestBody),
          )
          .timeout(
            _requestTimeout,
            onTimeout: () => throw TimeoutException("Request timeout"),
          );

      // Parse response
      return _parseResponse(response);
    } on SocketException catch (e) {
      syraLog("❌ [ChatService] SocketException: $e");
      return ChatSendResult.error(
        userMessage: "Bağlantı hatası. İnterneti kontrol et ve tekrar dene.",
        debugMessage: "SocketException: $e",
      );
    } on TimeoutException catch (e) {
      syraLog("❌ [ChatService] TimeoutException: $e");
      return ChatSendResult.error(
        userMessage: "İstek zaman aşımına uğradı. Tekrar dene kanka.",
        debugMessage: "TimeoutException: $e",
      );
    } on FirebaseAuthException catch (e) {
      syraLog(
          "❌ [ChatService] FirebaseAuthException: ${e.code} - ${e.message}");
      return ChatSendResult.error(
        userMessage:
            "Oturumunla ilgili bir sorun var gibi. Çıkış yapıp tekrar giriş yapmayı dene.",
        debugMessage: "FirebaseAuthException: ${e.code} - ${e.message}",
      );
    } on FormatException catch (e) {
      syraLog("❌ [ChatService] FormatException (JSON parse): $e");
      return ChatSendResult.error(
        userMessage: "Sunucudan geçersiz yanıt alındı. Tekrar dene.",
        debugMessage: "FormatException: $e",
      );
    } on Exception catch (e) {
      syraLog("❌ [ChatService] Exception: $e");
      return ChatSendResult.error(
        userMessage: "Beklenmedik bir hata oluştu. Birazdan tekrar dene.",
        debugMessage: "Exception: $e",
      );
    } catch (e, stackTrace) {
      syraLog("❌ [ChatService] Unexpected error: $e\n$stackTrace");
      return ChatSendResult.error(
        userMessage: "Kanka beklenmedik bir hata oldu. Birazdan tekrar dene.",
        debugMessage: "Unexpected error: $e",
      );
    }
  }

  /// Parse HTTP response and extract AI message
  static ChatSendResult _parseResponse(http.Response response) {
    final statusCode = response.statusCode;
    final rawBody = response.body;

    syraLog("📥 [ChatService] Response: $statusCode");

    // Try to parse JSON body
    Map<String, dynamic>? jsonBody;
    if (rawBody.isNotEmpty) {
      try {
        jsonBody = jsonDecode(rawBody) as Map<String, dynamic>;
      } catch (e) {
        syraLog("⚠️ [ChatService] JSON parse failed: $e\nBody: $rawBody");
      }
    }

    // Handle different status codes
    switch (statusCode) {
      case 200:
        // Success - extract message
        final text = jsonBody?["message"] ??
            jsonBody?["response"] ??
            jsonBody?["reply"] ??
            jsonBody?["text"];

        if (text != null && text.toString().isNotEmpty) {
          syraLog("✅ [ChatService] Message received successfully");
          return ChatSendResult.success(text.toString());
        } else {
          syraLog("⚠️ [ChatService] Empty response from backend");
          return ChatSendResult.error(
            userMessage: "Sunucudan boş yanıt alındı. Tekrar dene.",
            debugMessage: "200 OK but no message in response",
          );
        }

      case 401:
        syraLog("❌ [ChatService] 401 Unauthorized");
        return ChatSendResult.error(
          userMessage: "Yetki hatası. Çıkış yapıp tekrar giriş yapmayı dene.",
          debugMessage: "401 Unauthorized",
        );

      case 408:
        syraLog("❌ [ChatService] 408 Request Timeout");
        return ChatSendResult.error(
          userMessage: "İstek zaman aşımına uğradı. Tekrar dene kanka.",
          debugMessage: "408 Request Timeout",
        );

      case 429:
        final message = jsonBody?["message"] as String?;
        syraLog("❌ [ChatService] 429 Rate Limit: $message");
        return ChatSendResult.error(
          userMessage: message ??
              "Günlük mesaj limitine ulaştın. Premium'a geç veya yarın tekrar dene.",
          debugMessage: "429 Rate Limit",
        );

      case 500:
        syraLog("❌ [ChatService] 500 Server Error");
        return ChatSendResult.error(
          userMessage: "Sunucu hatası oluştu. Birkaç dakika sonra tekrar dene.",
          debugMessage: "500 Internal Server Error",
        );

      case 503:
        syraLog("❌ [ChatService] 503 Service Unavailable");
        return ChatSendResult.error(
          userMessage: "Servis şu an bakımda. Birazdan tekrar dene kanka.",
          debugMessage: "503 Service Unavailable",
        );

      default:
        // Try to get backend error message
        final backendMessage = jsonBody?["message"] as String?;
        if (backendMessage != null && backendMessage.isNotEmpty) {
          syraLog("❌ [ChatService] $statusCode Error: $backendMessage");
          return ChatSendResult.error(
            userMessage: backendMessage,
            debugMessage: "$statusCode: $backendMessage",
          );
        }

        syraLog("❌ [ChatService] $statusCode Error: $rawBody");
        return ChatSendResult.error(
          userMessage:
              "Sunucu hatası: $statusCode. Birazdan tekrar dene kanka.",
          debugMessage: "$statusCode: $rawBody",
        );
    }
  }

  /// Build conversation context for the API request
  ///
  /// Includes:
  /// - Reply-to message (if any)
  /// - Last 10 messages from history
  static List<Map<String, String>> _buildConversationContext(
    List<Map<String, dynamic>> history,
    Map<String, dynamic>? replyingTo,
  ) {
    final context = <Map<String, String>>[];

    // Add reply context if present
    if (replyingTo != null) {
      context.add({
        "role": replyingTo['sender'] == "user" ? "user" : "assistant",
        "content": "[Replying to: ${replyingTo['text']}]",
      });
    }

    // Add last 10 messages for context
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
  // MANIPULATION DETECTION
  // ═══════════════════════════════════════════════════════════════

  /// Detect manipulation patterns in AI responses
  ///
  /// Returns a map with:
  /// - hasRed: true if red flags detected
  /// - hasGreen: true if green flags detected
  static Map<String, bool> detectManipulation(String text) {
    final lower = text.toLowerCase();

    // Red flag keywords (manipulation patterns)
    const redFlags = [
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

    // Green flag keywords (healthy patterns)
    const greenFlags = [
      "healthy boundary",
      "mutual respect",
      "clear communication",
      "emotional support",
      "yeşil bayrak",
      "healthy",
      "green flag",
    ];

    return {
      "hasRed": redFlags.any((flag) => lower.contains(flag)),
      "hasGreen": greenFlags.any((flag) => lower.contains(flag)),
    };
  }
}
