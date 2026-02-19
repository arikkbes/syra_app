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
import 'package:syra/core/syra_log.dart';

class RelationshipStatsService {
  // Firebase Cloud Functions URL (from deployment)
  static const String _baseUrl = ApiEndpoints.relationshipStats;
  static const Set<String> _validPlans = {'free', 'core', 'plus'};
  static const Set<String> _validAccess = {'teaser', 'full'};

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

      syraLog('🔍 Fetching stats from: $_baseUrl');

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

      syraLog('📡 Response status: ${response.statusCode}');
      syraLog('📦 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        return _normalizeResponse(data);
      } else if (response.statusCode == 404) {
        throw Exception(
            'Endpoint bulunamadı. Lütfen Firebase Functions deploy edildiğinden emin olun.');
      } else {
        throw Exception(
            'Sunucu hatası: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      syraLog('❌ RelationshipStatsService.getStats error: $e');
      rethrow;
    }
  }

  static Map<String, dynamic> _normalizeResponse(Map<String, dynamic> data) {
    if (data['success'] != true) return data;

    final stats = data['stats'] is Map<String, dynamic>
        ? Map<String, dynamic>.from(data['stats'] as Map<String, dynamic>)
        : <String, dynamic>{};

    final responseLockedKeys = (data['lockedKeys'] is List)
        ? (data['lockedKeys'] as List)
            .whereType<String>()
            .where((key) => key.isNotEmpty)
            .toList()
        : <String>[];

    final lockedBySentinel = <String>[
      if (stats['whoSaidILoveYouMore'] == 'locked') 'whoSaidILoveYouMore',
      if (stats['whoApologizedMore'] == 'locked') 'whoApologizedMore',
      if (stats['whoUsedMoreEmojis'] == 'locked') 'whoUsedMoreEmojis',
    ];

    final lockedKeys = <String>{...responseLockedKeys, ...lockedBySentinel}.toList();

    final rawAccess = data['access'];
    final inferredAccess = lockedKeys.isNotEmpty ? 'teaser' : 'full';
    final access = rawAccess is String && _validAccess.contains(rawAccess)
        ? rawAccess
        : inferredAccess;

    final rawPlan = data['plan'];
    final normalizedPlan =
        rawPlan is String && _validPlans.contains(rawPlan) ? rawPlan : null;
    final plan = normalizedPlan ?? (access == 'teaser' ? 'free' : 'core');

    return {
      ...data,
      'stats': stats,
      'plan': plan,
      'access': access,
      'lockedKeys': lockedKeys,
      'message': data['message'] is String ? data['message'] as String : null,
    };
  }
}
