import 'dart:convert';
import 'package:http/http.dart' as http;

class ChatService {
  static const String baseUrl =
      'https://api.kooktalayi.com/heratbazar-api/api';

  static Future<List> getMessages(int adId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/chat/messages/$adId'),
    );

    final data = jsonDecode(response.body);

    if (data['success'] == true) {
      return data['messages'] ?? [];
    }

    throw Exception(data['error'] ?? 'خطا در دریافت پیام‌ها');
  }

  static Future<void> sendMessage({
    required int adId,
    required String senderPhone,
    required String message,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/chat/send'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'ad_id': adId,
        'sender_phone': senderPhone,
        'message': message,
      }),
    );

    final data = jsonDecode(response.body);

    if (data['success'] != true) {
      throw Exception(data['error'] ?? 'خطا در ارسال پیام');
    }
  }
}