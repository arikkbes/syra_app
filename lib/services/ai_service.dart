import 'dart:convert';
import 'package:http/http.dart' as http;

class FlortIQAI {
  static const String endpoint =
      "https://flortiqchat-bfbh342m3a-uc.a.run.app/flortIQChat";

  static Future<String> getResponse(String message, String uid) async {
    final response = await http.post(
      Uri.parse(endpoint),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"message": message, "uid": uid}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data["reply"];
    } else {
      return "⚠ Sunucu hatası: ${response.statusCode}";
    }
  }
}
