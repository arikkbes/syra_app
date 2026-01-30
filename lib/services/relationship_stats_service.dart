/// ═══════════════════════════════════════════════════════════════
/// RELATIONSHIP STATS SERVICE
/// ═══════════════════════════════════════════════════════════════
/// Fetches "Who More?" statistics from the backend
/// ═══════════════════════════════════════════════════════════════
library;

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import '../services/api_endpoints.dart';

class RelationshipStatsService {
  // Firebase Cloud Functions URL (from deployment)
  static const String _baseUrl = ApiEndpoints.relationshipStats;

  /// Fetch relationship stats for the current user
  static Future<Map<String, dynamic>> getStats() async {
    try {
      // Get current user token
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('Kullanıcı oturumu bulunamadı');
      }

      final token = await user.getIdToken();
      if (token == null) {
        throw Exception('Token alınamadı');
      }

      print('🔍 Fetching stats from: $_baseUrl');

      // Make HTTP request
      final response = await http.get(
        Uri.parse(_baseUrl),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('İstek zaman aşımına uğradı. Sunucu yanıt vermiyor.');
        },
      );

      print('📡 Response status: ${response.statusCode}');
      print('📦 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data as Map<String, dynamic>;
      } else if (response.statusCode == 404) {
        throw Exception(
            'Endpoint bulunamadı. Lütfen Firebase Functions deploy edildiğinden emin olun.');
      } else {
        throw Exception(
            'Sunucu hatası: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('❌ RelationshipStatsService.getStats error: $e');
      rethrow;
    }
  }
}
