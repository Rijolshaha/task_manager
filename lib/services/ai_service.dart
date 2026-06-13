import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/chat_message_payload.dart';
import 'api_key_manager.dart';

class AiService {
  final ApiKeyManager _apiKeyManager;

  AiService({ApiKeyManager? apiKeyManager})
    : _apiKeyManager = apiKeyManager ?? ApiKeyManager();

  Future<String> sendMessage(List<ChatMessagePayload> messages) async {
    final apiKey = await _apiKeyManager.getApiKey();
    if (apiKey == null || apiKey.trim().isEmpty) {
      throw Exception(
        'Gemini API kaliti topilmadi. Sozlamalar bo\'limidan API kalitni kiriting.',
      );
    }

    final url =
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=$apiKey';

    final contents = messages.map((m) {
      final role = m.role == 'assistant' ? 'model' : 'user';
      return {
        "role": role,
        "parts": [
          {"text": m.content}
        ]
      };
    }).toList();

    final response = await http
        .post(
          Uri.parse(url),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({"contents": contents}),
        )
        .timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      if (body['candidates'] == null || body['candidates'].isEmpty) {
        throw Exception('AI dan javob kelmadi (Gemini)');
      }
      return body['candidates'][0]['content']['parts'][0]['text']?.toString() ?? '';
    } else {
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      String msg = body['error']?['message']?.toString() ?? response.body;
      throw Exception(msg);
    }
  }
}
