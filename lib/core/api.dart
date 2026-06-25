import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'session.dart';

class Api {
  static const String baseUrl =
      "https://api.kooktalayi.com/heratbazar-api/api";

  static const String publicBase =
      "https://api.kooktalayi.com/heratbazar-api";

  static Uri url(String path) {
    final cleanPath = path.startsWith('/') ? path : '/$path';
    return Uri.parse("$baseUrl$cleanPath");
  }

  static Map<String, String> get headers {
    final token = Session.adminToken.trim();

    return {
      "Content-Type": "application/json",
      "Accept": "application/json",
      if (token.isNotEmpty) "Authorization": "Bearer $token",
    };
  }

  static Map<String, String> ownerHeaders() {
    final token = Session.adminToken.trim();

    return {
      ...headers,
      "x-owner-phone": Session.ownerHeaderPhone,
      if (token.isNotEmpty) "Authorization": "Bearer $token",
    };
  }

  static dynamic decode(http.Response response) {
    try {
      if (response.bodyBytes.isEmpty) return null;
      return jsonDecode(utf8.decode(response.bodyBytes));
    } catch (_) {
      throw Exception("پاسخ سرور نامعتبر است");
    }
  }

  static String errorMessage(dynamic data, String fallback) {
    if (data is Map) {
      if (data["error"] != null) return data["error"].toString();
      if (data["message"] != null) return data["message"].toString();
    }

    return fallback;
  }

  static List<dynamic> listFrom(dynamic data, String key) {
    if (data is List) return data;

    if (data is Map && data[key] is List) {
      return List<dynamic>.from(data[key]);
    }

    if (data is Map && data["data"] is List) {
      return List<dynamic>.from(data["data"]);
    }

    return [];
  }

  static Map<String, dynamic> mapFrom(dynamic data) {
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }

    return {};
  }

  static String fullImageUrl(String? imageUrl) {
    if (imageUrl == null || imageUrl.trim().isEmpty) return "";

    final clean = imageUrl.trim();

    if (clean.startsWith("http://") || clean.startsWith("https://")) {
      return clean;
    }

    if (clean.startsWith("/")) {
      return "$publicBase$clean";
    }

    return "$publicBase/$clean";
  }

  static String apiImageValue(String? imageUrl) {
    if (imageUrl == null || imageUrl.trim().isEmpty) return "";

    final clean = imageUrl.trim();

    if (clean.startsWith(publicBase)) {
      return clean.substring(publicBase.length);
    }

    return clean;
  }

  static Future<String?> uploadImageBytes({
    required List<int> bytes,
    required String filename,
  }) async {
    try {
      debugPrint("UPLOAD START => $filename / ${bytes.length} bytes");

      final request = http.MultipartRequest(
        "POST",
        url("/uploads"),
      );

      request.files.add(
        http.MultipartFile.fromBytes(
          "image",
          bytes,
          filename: filename,
        ),
      );

      final response = await request.send();
      final body = await response.stream.bytesToString();

      debugPrint("UPLOAD STATUS => ${response.statusCode}");
      debugPrint("UPLOAD BODY => $body");

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception("آپلود ناموفق: ${response.statusCode} - $body");
      }

      dynamic data;

      try {
        data = jsonDecode(body);
      } catch (_) {
        throw Exception("پاسخ آپلود نامعتبر است: $body");
      }

      final rawUrl = data is Map ? data["url"]?.toString() : null;

      if (rawUrl == null || rawUrl.isEmpty) {
        throw Exception("آدرس عکس از سرور برنگشت");
      }

      return apiImageValue(rawUrl);
    } catch (e) {
      debugPrint("UPLOAD ERROR => $e");
      rethrow;
    }
  }

  // ==================== ADS ====================

  static Future<List<dynamic>> getAds() async {
    final response = await http.get(url("/ads"), headers: headers);
    final data = decode(response);

    if (response.statusCode == 200) {
      return listFrom(data, "ads");
    }

    throw Exception(errorMessage(data, "خطا در دریافت آگهی‌ها"));
  }

  static Future<void> saveAd({
    required bool isEdit,
    required int? adId,
    required Map<String, dynamic> body,
  }) async {
    final response = isEdit
        ? await http.put(
            url("/ads/$adId"),
            headers: headers,
            body: jsonEncode(body),
          )
        : await http.post(
            url("/ads"),
            headers: headers,
            body: jsonEncode(body),
          );

    if (response.statusCode == 200 || response.statusCode == 201) return;

    final data = decode(response);

    throw Exception(errorMessage(data, "ذخیره آگهی انجام نشد"));
  }

  // ==================== AUTH ====================

  static Future<Map<String, dynamic>> login({
    required String phone,
    required String loginCode,
  }) async {
    final response = await http.post(
      url("/auth/login"),
      headers: headers,
      body: jsonEncode({
        "phone": phone.trim(),
        "login_code": loginCode.trim(),
      }),
    );

    final data = decode(response);

    if (response.statusCode == 200 && data is Map) {
      final userData = data["user"];

      if (userData is Map) {
        final user = Map<String, dynamic>.from(userData);
        await Session.saveUser(user);
      }

      return Map<String, dynamic>.from(data);
    }

    throw Exception(errorMessage(data, "ورود انجام نشد"));
  }

  static Future<Map<String, dynamic>> register({
    required String firstName,
    required String lastName,
    required String phone,
    required String securityAnswer,
  }) async {
    final response = await http.post(
      url("/auth/register"),
      headers: headers,
      body: jsonEncode({
        "first_name": firstName.trim(),
        "last_name": lastName.trim(),
        "phone": phone.trim(),
        "security_question": "نام اولین معلم شما چیست؟",
        "security_answer": securityAnswer.trim(),
      }),
    );

    final data = decode(response);

    if ((response.statusCode == 200 || response.statusCode == 201) &&
        data is Map) {
      final userData = data["user"];

      if (userData is Map) {
        final user = Map<String, dynamic>.from(userData);
        await Session.saveUser(user);
      }

      return Map<String, dynamic>.from(data);
    }

    throw Exception(errorMessage(data, "ثبت‌نام انجام نشد"));
  }

  static Future<Map<String, dynamic>> forgotCode({
    required String firstName,
    required String lastName,
    required String phone,
    required String securityAnswer,
  }) async {
    final response = await http.post(
      url("/auth/forgot-code"),
      headers: headers,
      body: jsonEncode({
        "first_name": firstName.trim(),
        "last_name": lastName.trim(),
        "phone": phone.trim(),
        "security_answer": securityAnswer.trim(),
      }),
    );

    final data = decode(response);

    if (response.statusCode == 200 && data is Map) {
      return Map<String, dynamic>.from(data);
    }

    throw Exception(errorMessage(data, "بازیابی کد انجام نشد"));
  }

  // ==================== CHAT ====================

  static Future<List<dynamic>> getConversations({
    required String myPhone,
  }) async {
    final uri = url("/chat/conversations").replace(
      queryParameters: {
        "my_phone": myPhone.trim(),
      },
    );

    final response = await http.get(uri, headers: headers);
    final data = decode(response);

    if (response.statusCode == 200) {
      if (data is Map && data["success"] == false) {
        throw Exception(errorMessage(data, "خطا در دریافت گفتگوها"));
      }

      return listFrom(data, "conversations");
    }

    throw Exception(errorMessage(data, "خطا در دریافت گفتگوها"));
  }

  static Future<List<dynamic>> getMessages({
    required int adId,
    required String myPhone,
    required String otherPhone,
  }) async {
    final uri = url("/chat/messages/$adId").replace(
      queryParameters: {
        "my_phone": myPhone.trim(),
        "other_phone": otherPhone.trim(),
      },
    );

    final response = await http.get(uri, headers: headers);
    final data = decode(response);

    if (response.statusCode == 200) {
      if (data is Map && data["success"] == false) {
        throw Exception(errorMessage(data, "خطا در دریافت پیام‌ها"));
      }

      return listFrom(data, "messages");
    }

    throw Exception(errorMessage(data, "خطا در دریافت پیام‌ها"));
  }

  static Future<int> getUnreadMessagesCount({
    required String myPhone,
  }) async {
    if (myPhone.trim().isEmpty) return 0;

    final conversations = await getConversations(myPhone: myPhone);

    int total = 0;

    for (final item in conversations) {
      if (item is! Map) continue;

      final unread = item["unread_count"] ??
          item["unread"] ??
          item["new_messages"] ??
          item["new_count"];

      if (unread != null) {
        total += int.tryParse(unread.toString()) ?? 0;
      }
    }

    return total;
  }

  static Future<void> sendMessage({
    required int adId,
    required String senderPhone,
    required String receiverPhone,
    required String message,
  }) async {
    final response = await http.post(
      url("/chat/send"),
      headers: headers,
      body: jsonEncode({
        "ad_id": adId,
        "sender_phone": senderPhone.trim(),
        "receiver_phone": receiverPhone.trim(),
        "message": message.trim(),
      }),
    );

    final data = decode(response);

    if (response.statusCode == 200 || response.statusCode == 201) {
      if (data is Map && data["success"] == false) {
        throw Exception(errorMessage(data, "خطا در ارسال پیام"));
      }

      return;
    }

    throw Exception(errorMessage(data, "خطا در ارسال پیام"));
  }
}