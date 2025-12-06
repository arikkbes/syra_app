import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/relationship_analysis_result.dart';

/// ═══════════════════════════════════════════════════════════════
/// RELATIONSHIP ANALYSIS SERVICE
/// ═══════════════════════════════════════════════════════════════
/// Handles uploading WhatsApp chats and receiving analysis results
/// ═══════════════════════════════════════════════════════════════

class RelationshipAnalysisService {
  // Cloud Function URL
  static const String _functionUrl =
      'https://us-central1-syra-ai-b562f.cloudfunctions.net/analyzeRelationshipChat';

  /// Upload a WhatsApp chat file and get analysis result
  static Future<RelationshipAnalysisResult> analyzeChat(File file) async {
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

      // Add userId
      request.fields['userId'] = user.uid;

      // Send request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode != 200) {
        final errorBody = json.decode(response.body);
        throw Exception(
          errorBody['message'] ?? 'Analiz sırasında bir hata oluştu',
        );
      }

      // Parse response
      final responseData = json.decode(response.body);
      
      if (responseData['success'] != true) {
        throw Exception(
          responseData['message'] ?? 'Analiz başarısız oldu',
        );
      }

      final analysisData = responseData['analysis'];
      return RelationshipAnalysisResult.fromJson(analysisData);
    } catch (e) {
      throw Exception('Analiz hatası: ${e.toString()}');
    }
  }
}
