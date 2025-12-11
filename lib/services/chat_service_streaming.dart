// lib/services/chat_service_streaming.dart

import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firestore_user.dart';

/// ═══════════════════════════════════════════════════════════════
/// STREAMING CHAT SERVICE - Claude/ChatGPT Style
/// ═══════════════════════════════════════════════════════════════
/// 
/// Streams AI responses word-by-word for premium UX
/// 
/// Usage:
/// ```dart
/// await for (final chunk in ChatServiceStreaming.sendMessageStream(...)) {
///   setState(() {
///     currentMessage += chunk.text;
///   });
/// }
/// ```
/// ═══════════════════════════════════════════════════════════════

/// Chunk of streaming response
class StreamChunk {
  final String text;
  final bool isDone;
  final String? error;

  const StreamChunk({
    required this.text,
    this.isDone = false,
    this.error,
  });

  factory StreamChunk.text(String text) {
    return StreamChunk(text: text, isDone: false);
  }

  factory StreamChunk.done() {
    return StreamChunk(text: '', isDone: true);
  }

  factory StreamChunk.error(String error) {
    return StreamChunk(text: '', error: error);
  }
}

class ChatServiceStreaming {
  static const String _endpoint =
      "https://us-central1-syra-ai-b562f.cloudfunctions.net/flortIQChat";

  // ═══════════════════════════════════════════════════════════════
  // STREAMING MESSAGE SEND
  // ═══════════════════════════════════════════════════════════════

  /// Send message and get streaming response
  /// 
  /// Yields StreamChunk objects as AI generates response
  static Stream<StreamChunk> sendMessageStream({
    required String userMessage,
    required List<Map<String, dynamic>> conversationHistory,
    Map<String, dynamic>? replyingTo,
    required String mode,
    String? imageUrl,
  }) async* {
    // Validate input
    if (userMessage.trim().isEmpty && imageUrl == null) {
      yield StreamChunk.error("Mesaj boş olamaz.");
      return;
    }

    try {
      // Check authentication
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        yield StreamChunk.error(
            "Oturumun düşmüş gibi duruyor kanka. Çıkış yapıp tekrar giriş yapmayı dene.");
        return;
      }

      debugPrint(
          "📤 [StreamingService] Sending message (mode: $mode, hasImage: ${imageUrl != null})");

      // Get auth token
      final idToken = await user.getIdToken();
      if (idToken == null) {
        yield StreamChunk.error(
            "Yetki doğrulaması başarısız. Tekrar giriş yapmayı dene.");
        return;
      }

      // Build request
      final context = _buildConversationContext(conversationHistory, replyingTo);
      final uri = Uri.parse(_endpoint);

      final requestBody = {
        "message": userMessage,
        "context": context,
        "mode": mode,
        "stream": true, // ← Enable streaming
      };

      if (imageUrl != null && imageUrl.isNotEmpty) {
        requestBody["imageUrl"] = imageUrl;
      }

      // Send streaming request
      final request = http.Request('POST', uri);
      request.headers.addAll({
        "Content-Type": "application/json",
        "Authorization": "Bearer $idToken",
      });
      request.body = jsonEncode(requestBody);

      final streamedResponse = await request.send();

      if (streamedResponse.statusCode != 200) {
        final errorBody = await streamedResponse.stream.bytesToString();
        debugPrint("❌ [StreamingService] Error: ${streamedResponse.statusCode} - $errorBody");
        yield StreamChunk.error(_getErrorMessage(streamedResponse.statusCode, errorBody));
        return;
      }

      // Process streaming response
      await for (final chunk in _processStream(streamedResponse.stream)) {
        yield chunk;
      }

      // Mark as done
      yield StreamChunk.done();

    } catch (e, stackTrace) {
      debugPrint("❌ [StreamingService] Error: $e\n$stackTrace");
      yield StreamChunk.error("Beklenmedik bir hata oluştu. Birazdan tekrar dene.");
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // STREAM PROCESSING
  // ═══════════════════════════════════════════════════════════════

  /// Process SSE (Server-Sent Events) stream
  static Stream<StreamChunk> _processStream(Stream<List<int>> byteStream) async* {
    String buffer = '';

    await for (final bytes in byteStream) {
      final chunk = utf8.decode(bytes);
      buffer += chunk;

      // Process complete lines
      while (buffer.contains('\n')) {
        final newlineIndex = buffer.indexOf('\n');
        final line = buffer.substring(0, newlineIndex).trim();
        buffer = buffer.substring(newlineIndex + 1);

        if (line.isEmpty || line.startsWith(':')) {
          continue; // Skip empty lines and comments
        }

        // Parse SSE format: "data: {...}"
        if (line.startsWith('data: ')) {
          final data = line.substring(6);

          if (data == '[DONE]') {
            debugPrint("✅ [StreamingService] Stream completed");
            break;
          }

          try {
            final json = jsonDecode(data) as Map<String, dynamic>;
            
            // Extract text from various formats
            final text = _extractText(json);
            
            if (text.isNotEmpty) {
              yield StreamChunk.text(text);
            }
          } catch (e) {
            debugPrint("⚠️ [StreamingService] Failed to parse chunk: $e");
            // Continue processing other chunks
          }
        }
      }
    }
  }

  /// Extract text from various JSON response formats
  static String _extractText(Map<String, dynamic> json) {
    // OpenAI format
    if (json.containsKey('choices') && json['choices'] is List) {
      final choices = json['choices'] as List;
      if (choices.isNotEmpty) {
        final choice = choices[0] as Map<String, dynamic>;
        final delta = choice['delta'] as Map<String, dynamic>?;
        if (delta != null && delta.containsKey('content')) {
          return delta['content'] as String? ?? '';
        }
      }
    }

    // Simple format
    if (json.containsKey('text')) {
      return json['text'] as String? ?? '';
    }

    if (json.containsKey('content')) {
      return json['content'] as String? ?? '';
    }

    if (json.containsKey('message')) {
      return json['message'] as String? ?? '';
    }

    return '';
  }

  // ═══════════════════════════════════════════════════════════════
  // HELPERS
  // ═══════════════════════════════════════════════════════════════

  static String _buildConversationContext(
    List<Map<String, dynamic>> history,
    Map<String, dynamic>? replyingTo,
  ) {
    final buffer = StringBuffer();

    if (history.isNotEmpty) {
      buffer.writeln("Recent conversation:");
      for (final msg in history.take(10)) {
        final role = msg["isUser"] == true ? "User" : "SYRA";
        final text = msg["text"] ?? "";
        buffer.writeln("$role: $text");
      }
    }

    if (replyingTo != null) {
      buffer.writeln("\nReplying to:");
      buffer.writeln(replyingTo["text"] ?? "");
    }

    return buffer.toString();
  }

  static String _getErrorMessage(int statusCode, String body) {
    switch (statusCode) {
      case 401:
        return "Oturumun düşmüş. Çıkış yapıp tekrar giriş yap.";
      case 403:
        return "Bu özelliği kullanma yetkin yok. Premium'a geç!";
      case 429:
        return "Çok fazla istek attın kanka. Biraz bekle.";
      case 500:
      case 502:
      case 503:
        return "Sunucuda bir sorun var. Birazdan tekrar dene.";
      default:
        return "Bir hata oluştu. Tekrar dene.";
    }
  }
}
