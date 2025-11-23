import 'dart:convert';
import 'package:http/http.dart' as http;

class FlortIQService {
  final String baseUrl =
      "https://flortiqchat-bfbh342m3a-uc.a.run.app/flortIQChat";
  // senin local endpointin

  Future<String> sendMessage(String userMessage) async {
    final response = await http.post(
      Uri.parse(baseUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'message': userMessage}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['reply'] ?? 'Yanıt alınamadı.';
    } else {
      return 'Hata: ${response.statusCode}';
    }
  }
}
