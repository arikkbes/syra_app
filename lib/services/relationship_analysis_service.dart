import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/relationship_analysis_result.dart';
import '../services/api_endpoints.dart';

/// ═══════════════════════════════════════════════════════════════
/// RELATIONSHIP ANALYSIS SERVICE V2
/// ═══════════════════════════════════════════════════════════════
/// Handles uploading WhatsApp chats and receiving analysis results
/// Updated for new chunked pipeline architecture
/// ═══════════════════════════════════════════════════════════════

class RelationshipAnalysisService {
  // Cloud Function URL
  static const String _functionUrl = ApiEndpoints.relationshipAnalysis;

  /// Upload a WhatsApp chat file and get analysis result
  /// Returns RelationshipAnalysisResult with relationshipId for future reference
  ///
  /// MODULE 3: Added forceUpdate parameter for mismatch handling
  /// MODULE 4: Added updateMode parameter for smart incremental updates
  ///
  /// [updateMode] options:
  /// - "smart" (default): Attempt delta update by detecting overlap
  /// - "force_rebuild": Clear all existing data and rebuild from scratch
  static Future<RelationshipAnalysisResult> analyzeChat(
    File file, {
    String? existingRelationshipId,
    bool forceUpdate = false, // MODULE 3: Force update even if mismatch
    String updateMode = "smart", // MODULE 4: "smart" or "force_rebuild"
    String? jobId, // Job tracking ID for real-time progress
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('Kullanıcı oturumu bulunamadı');
      }

      // Get Firebase ID token for authentication
      final idToken = await user.getIdToken();

      // Create multipart request
      final request = http.MultipartRequest('POST', Uri.parse(_functionUrl));

      // Add authentication header
      request.headers['Authorization'] = 'Bearer $idToken';

      // Add file
      final fileBytes = await file.readAsBytes();
      final multipartFile = http.MultipartFile.fromBytes(
        'file',
        fileBytes,
        filename: file.path.split('/').last,
      );
      request.files.add(multipartFile);

      // Add fields
      request.fields['userId'] = user.uid;

      // If updating existing relationship
      if (existingRelationshipId != null) {
        request.fields['relationshipId'] = existingRelationshipId;
      }

      // MODULE 3: Add forceUpdate flag
      if (forceUpdate) {
        request.fields['forceUpdate'] = 'true';
      }

      // MODULE 4: Add updateMode field
      request.fields['updateMode'] = updateMode;

      // Job tracking ID for real-time progress
      if (jobId != null) {
        request.fields['jobId'] = jobId;
      }

      // Send request with timeout
      final streamedResponse = await request.send().timeout(
        const Duration(minutes: 12),
        onTimeout: () {
          throw Exception('İstek zaman aşımına uğradı. Lütfen tekrar deneyin.');
        },
      );
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode != 200) {
        Map<String, dynamic>? errorBody;
        try {
          errorBody = json.decode(response.body);
        } catch (_) {}
        throw Exception(
          errorBody?['message'] ??
              'Analiz sırasında bir hata oluştu (${response.statusCode})',
        );
      }

      // Parse response
      final responseData = json.decode(response.body);

      // ═══════════════════════════════════════════════════════════════
      // MODULE 3: Handle mismatch detection
      // ═══════════════════════════════════════════════════════════════
      if (responseData['mismatchDetected'] == true) {
        final reason = responseData['reason'] as String? ??
            'Farklı bir ilişki tespit edildi';

        // Return a special result indicating mismatch
        return RelationshipAnalysisResult.mismatch(
          reason: reason,
          suggestedAction:
              responseData['suggestedAction'] as String? ?? 'create_new',
        );
      }

      if (responseData['success'] != true) {
        throw Exception(
          responseData['message'] ?? 'Analiz başarısız oldu',
        );
      }

      // New V2 response format:
      // {
      //   success: true,
      //   relationshipId: "xxx",
      //   summary: { masterSummary object },
      //   stats: { totalMessages, totalChunks, speakers }
      // }

      final relationshipId = responseData['relationshipId'] as String?;

      // Handle summary - can be either String or Map depending on backend version
      Map<String, dynamic> summary = {};
      String shortSummary = '';

      if (responseData['summary'] is String) {
        // New backend: summary is a plain string
        shortSummary = responseData['summary'] as String;
      } else if (responseData['summary'] is Map) {
        // Old backend: summary is a map with structured data
        summary = responseData['summary'] as Map<String, dynamic>;
        shortSummary = summary['shortSummary'] as String? ?? '';
      }

      final stats = responseData['stats'] as Map<String, dynamic>? ?? {};

      return RelationshipAnalysisResult.fromV2Response(
        relationshipId: relationshipId,
        summary: summary.isEmpty ? {'shortSummary': shortSummary} : summary,
        stats: stats,
      );
    } catch (e) {
      throw Exception(
          'Analiz hatası: ${e.toString().replaceAll('Exception: ', '')}');
    }
  }
}
