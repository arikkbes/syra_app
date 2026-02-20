import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import '../services/api_endpoints.dart';
import 'package:syra/core/syra_log.dart';

/// TAROT SERVICE — Handles tarot reading requests and follow-up conversations
class TarotService {
  static const String _tarotEndpoint = ApiEndpoints.tarotReading;
  static const String _chatEndpoint = ApiEndpoints.syraChatV2;

  /// Request a tarot reading for selected cards
  /// Returns JSON string with reading and card metadata
  static Future<String> getTarotReading({
    required List<int> selectedCards,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        return jsonEncode({
          "reading": "Oturumun düşmüş gibi duruyor kanka. Çıkış yapıp tekrar giriş yapmayı dene."
        });
      }

      final idToken = await user.getIdToken();
      final uri = Uri.parse(_tarotEndpoint);

      final requestBody = {
        "selectedCards": selectedCards,
      };

      final response = await http.post(
        uri,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $idToken",
        },
        body: jsonEncode(requestBody),
      ).timeout(
        const Duration(seconds: 60),
        onTimeout: () {
          throw Exception("Timeout");
        },
      );

      if (response.statusCode == 200) {
        // Return full JSON response (includes reading + cards)
        return response.body;
      }

      // Handle errors
      final jsonBody = jsonDecode(response.body);
      return jsonEncode({
        "reading": jsonBody?["message"] ?? "Bir hata oluştu. Tekrar dene."
      });
    } catch (e) {
      syraLog("getTarotReading error: $e");
      return jsonEncode({
        "reading": "Bağlantı hatası. Tekrar dene."
      });
    }
  }

  /// Ask a follow-up question about a tarot reading
  /// Uses the main chat endpoint but with tarot context
  static Future<String> followUpQuestion({
    required String question,
    required String readingContext,
    List<Map<String, dynamic>>? cardMeta,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        return "Oturumun düşmüş gibi duruyor. Çıkış yapıp tekrar giriş yapmayı dene.";
      }

      final idToken = await user.getIdToken();
      final uri = Uri.parse(_chatEndpoint);
      syraLog("CHAT_ENDPOINT: $uri");

      // Build context message about the tarot reading
      String contextMessage = "Kullanıcı az önce bir tarot açılımı yaptı. ";
      
      if (cardMeta != null && cardMeta.isNotEmpty) {
        final cardNames = cardMeta.map((c) => c['name']).join(", ");
        contextMessage += "Açılan kartlar: $cardNames. ";
      }
      
      contextMessage += "\n\nTarot yorumu:\n$readingContext\n\n";
      contextMessage += "Şimdi kullanıcı bu okuma hakkında soru soruyor. ";
      contextMessage += "Tarot yorumunu referans alarak, sanki o açılımı yapan bir tarot yorumcusu gibi cevap ver. ";
      contextMessage += "Spesifik ol, pattern'lere işaret et, direkt ve dürüst ol.";

      final requestBody = {
        "message": question,
        "mode": "dost_aci", // Direct, insightful responses
        "tarotContext": contextMessage, // Special context for tarot follow-up
      };

      final response = await http.post(
        uri,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $idToken",
        },
        body: jsonEncode(requestBody),
      ).timeout(
        const Duration(seconds: 60),
        onTimeout: () {
          throw Exception("Timeout");
        },
      );

      if (response.statusCode == 200) {
        final jsonBody = jsonDecode(response.body);
        return jsonBody["message"] ?? "Yanıt alınamadı.";
      }

      // Handle errors
      if (response.statusCode == 429) {
        return "Günlük mesaj limitine ulaştın. Premium'a geç veya yarın tekrar dene.";
      }

      return "Bir hata oluştu. Tekrar dene.";
    } catch (e) {
      syraLog("followUpQuestion error: $e");
      return "Bağlantı hatası. Tekrar dene.";
    }
  }
}
