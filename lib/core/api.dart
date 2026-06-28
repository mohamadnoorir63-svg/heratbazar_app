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

  static Map<String, String> get publicHeaders {
    return {
      "Content-Type": "application/json",
      "Accept": "application/json",
    };
  }

  static Map<String, String> ownerHeaders() {
    return {
      ...headers,
      "x-owner-phone": Session.ownerHeaderPhone,
    };
  }

  static Map<String, String> uploadHeaders() {
    final token = Session.adminToken.trim();

    return {
      "Accept": "application/json",
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
    if (data is Map) return Map<String, dynamic>.from(data);
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

      final request = http.MultipartRequest("POST", url("/uploads"));
      request.headers.addAll(uploadHeaders());

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

  static Future<List<dynamic>> getAdsByUser(int userId) async {
    final ads = await getAds();

    return ads.where((ad) {
      if (ad is! Map) return false;
      final value = ad["user_id"];
      return int.tryParse(value?.toString() ?? "") == userId;
    }).toList();
  }

  static Future<void> saveAd({
    required bool isEdit,
    required int? adId,
    required Map<String, dynamic> body,
  }) async {
    final response = isEdit
        ? await http.put(
            url("/ads/$adId"),
            headers: ownerHeaders(),
            body: jsonEncode(body),
          )
        : await http.post(
            url("/ads"),
            headers: ownerHeaders(),
            body: jsonEncode(body),
          );

    if (response.statusCode == 200 || response.statusCode == 201) return;

    final data = decode(response);
    throw Exception(errorMessage(data, "ذخیره آگهی انجام نشد"));
  }

  static Future<void> reportAd({
    required int adId,
    required String reason,
    String? reporterPhone,
  }) async {
    final response = await http.post(
      url("/ads/$adId/report"),
      headers: headers,
      body: jsonEncode({
        "reason": reason.trim(),
        "reporter_phone": reporterPhone ?? Session.userContact,
      }),
    );

    final data = decode(response);

    if (response.statusCode == 200 || response.statusCode == 201) return;

    throw Exception(errorMessage(data, "ارسال گزارش انجام نشد"));
  }

  // ==================== AUTH PHONE ====================

  static Future<Map<String, dynamic>> login({
    required String phone,
    required String loginCode,
  }) async {
    final response = await http.post(
      url("/auth/login"),
      headers: publicHeaders,
      body: jsonEncode({
        "phone": phone.trim(),
        "login_code": loginCode.trim(),
      }),
    );

    final data = decode(response);

    if (response.statusCode == 200 && data is Map) {
      final result = Map<String, dynamic>.from(data);
      await Session.saveLoginResponse(result);
      return result;
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
      headers: publicHeaders,
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
      final result = Map<String, dynamic>.from(data);
      await Session.saveLoginResponse(result);
      return result;
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
      headers: publicHeaders,
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
  // ==================== AUTH EMAIL ====================

  static Future<Map<String, dynamic>> registerEmail({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      url("/auth/register-email"),
      headers: publicHeaders,
      body: jsonEncode({
        "first_name": firstName.trim(),
        "last_name": lastName.trim(),
        "email": email.trim(),
        "password": password,
      }),
    );

    final data = decode(response);

    if ((response.statusCode == 200 || response.statusCode == 201) &&
        data is Map) {
      final result = Map<String, dynamic>.from(data);
      await Session.saveLoginResponse(result);
      return result;
    }

    throw Exception(errorMessage(data, "ثبت‌نام ایمیلی انجام نشد"));
  }

  static Future<Map<String, dynamic>> verifyEmail({
    required String email,
    required String code,
  }) async {
    final response = await http.post(
      url("/auth/verify-email"),
      headers: publicHeaders,
      body: jsonEncode({
        "email": email.trim(),
        "code": code.trim(),
      }),
    );

    final data = decode(response);

    if (response.statusCode == 200 && data is Map) {
      final result = Map<String, dynamic>.from(data);
      await Session.saveLoginResponse(result);
      return result;
    }

    throw Exception(errorMessage(data, "تأیید ایمیل انجام نشد"));
  }

  static Future<Map<String, dynamic>> resendEmailCode({
    required String email,
  }) async {
    final response = await http.post(
      url("/auth/resend-email-code"),
      headers: publicHeaders,
      body: jsonEncode({
        "email": email.trim(),
      }),
    );

    final data = decode(response);

    if (response.statusCode == 200 && data is Map) {
      return Map<String, dynamic>.from(data);
    }

    throw Exception(errorMessage(data, "ارسال دوباره کد انجام نشد"));
  }

  static Future<Map<String, dynamic>> loginEmail({
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      url("/auth/login-email"),
      headers: publicHeaders,
      body: jsonEncode({
        "email": email.trim(),
        "password": password,
      }),
    );

    final data = decode(response);

    if (response.statusCode == 200 && data is Map) {
      final result = Map<String, dynamic>.from(data);
      await Session.saveLoginResponse(result);
      return result;
    }

    throw Exception(errorMessage(data, "ورود ایمیلی انجام نشد"));
  }

  static Future<Map<String, dynamic>> forgotPasswordEmail({
    required String email,
  }) async {
    final response = await http.post(
      url("/auth/forgot-password-email"),
      headers: publicHeaders,
      body: jsonEncode({
        "email": email.trim(),
      }),
    );

    final data = decode(response);

    if (response.statusCode == 200 && data is Map) {
      return Map<String, dynamic>.from(data);
    }

    throw Exception(errorMessage(data, "ارسال کد بازیابی انجام نشد"));
  }

  static Future<Map<String, dynamic>> resetPasswordEmail({
    required String email,
    required String code,
    required String password,
  }) async {
    final response = await http.post(
      url("/auth/reset-password-email"),
      headers: publicHeaders,
      body: jsonEncode({
        "email": email.trim(),
        "code": code.trim(),
        "password": password,
      }),
    );

    final data = decode(response);

    if (response.statusCode == 200 && data is Map) {
      return Map<String, dynamic>.from(data);
    }

    throw Exception(errorMessage(data, "تغییر رمز عبور انجام نشد"));
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

  // ==================== ADMIN USERS ====================

  static Future<Map<String, dynamic>> getAdminStats() async {
    final response = await http.get(url("/admin/stats"), headers: headers);
    final data = decode(response);

    if (response.statusCode == 200 && data is Map) {
      return mapFrom(data["stats"]);
    }

    throw Exception(errorMessage(data, "خطا در دریافت آمار مدیریت"));
  }

  static Future<Map<String, dynamic>> getAdminDashboard() async {
    final response = await http.get(url("/admin/dashboard"), headers: headers);
    final data = decode(response);

    if (response.statusCode == 200 && data is Map) {
      return mapFrom(data["dashboard"]);
    }

    throw Exception(errorMessage(data, "خطا در دریافت داشبورد مدیریت"));
  }

  static Future<List<dynamic>> getAdminUsers() async {
    final response = await http.get(url("/admin/users"), headers: headers);
    final data = decode(response);

    if (response.statusCode == 200) {
      return listFrom(data, "users");
    }

    throw Exception(errorMessage(data, "خطا در دریافت کاربران"));
  }

  static Future<void> banUser(int userId, String reason) async {
    final response = await http.patch(
      url("/admin/users/$userId/ban"),
      headers: headers,
      body: jsonEncode({"reason": reason}),
    );

    final data = decode(response);

    if (response.statusCode == 200) return;

    throw Exception(errorMessage(data, "مسدود کردن کاربر انجام نشد"));
  }

  static Future<void> unbanUser(int userId) async {
    final response = await http.patch(
      url("/admin/users/$userId/unban"),
      headers: headers,
    );

    final data = decode(response);

    if (response.statusCode == 200) return;

    throw Exception(errorMessage(data, "رفع مسدودی کاربر انجام نشد"));
  }

  static Future<void> verifyUser(int userId) async {
    final response = await http.patch(
      url("/admin/users/$userId/verify"),
      headers: headers,
    );

    final data = decode(response);

    if (response.statusCode == 200) return;

    throw Exception(errorMessage(data, "تأیید کاربر انجام نشد"));
  }

  static Future<void> unverifyUser(int userId) async {
    final response = await http.patch(
      url("/admin/users/$userId/unverify"),
      headers: headers,
    );

    final data = decode(response);

    if (response.statusCode == 200) return;

    throw Exception(errorMessage(data, "لغو تأیید کاربر انجام نشد"));
  }

  static Future<void> blueVerifyUser(int userId) async {
    final response = await http.patch(
      url("/admin/users/$userId/blue-verify"),
      headers: headers,
    );

    final data = decode(response);

    if (response.statusCode == 200) return;

    throw Exception(errorMessage(data, "فعال کردن تیک آبی انجام نشد"));
  }

  static Future<void> unblueVerifyUser(int userId) async {
    final response = await http.patch(
      url("/admin/users/$userId/unblue-verify"),
      headers: headers,
    );

    final data = decode(response);

    if (response.statusCode == 200) return;

    throw Exception(errorMessage(data, "لغو تیک آبی انجام نشد"));
  }

  static Future<void> premiumUser(int userId, {int days = 30}) async {
    final response = await http.patch(
      url("/admin/users/$userId/premium"),
      headers: headers,
      body: jsonEncode({"days": days}),
    );

    final data = decode(response);

    if (response.statusCode == 200) return;

    throw Exception(errorMessage(data, "فعال کردن پریمیوم انجام نشد"));
  }

  static Future<void> unpremiumUser(int userId) async {
    final response = await http.patch(
      url("/admin/users/$userId/unpremium"),
      headers: headers,
    );

    final data = decode(response);

    if (response.statusCode == 200) return;

    throw Exception(errorMessage(data, "لغو پریمیوم انجام نشد"));
  }
  // ==================== ADMIN ADS ====================

  static Future<void> hideAd(int adId, String reason) async {
    final response = await http.patch(
      url("/admin/ads/$adId/hide"),
      headers: headers,
      body: jsonEncode({"reason": reason}),
    );

    final data = decode(response);

    if (response.statusCode == 200) return;

    throw Exception(errorMessage(data, "مخفی کردن آگهی انجام نشد"));
  }

  static Future<void> unhideAd(int adId) async {
    final response = await http.patch(
      url("/admin/ads/$adId/unhide"),
      headers: headers,
    );

    final data = decode(response);

    if (response.statusCode == 200) return;

    throw Exception(errorMessage(data, "نمایش دوباره آگهی انجام نشد"));
  }

  static Future<void> featureAd(int adId, {int days = 7}) async {
    final response = await http.patch(
      url("/admin/ads/$adId/feature"),
      headers: headers,
      body: jsonEncode({"days": days}),
    );

    final data = decode(response);

    if (response.statusCode == 200) return;

    throw Exception(errorMessage(data, "ویژه کردن آگهی انجام نشد"));
  }

  static Future<void> unfeatureAd(int adId) async {
    final response = await http.patch(
      url("/admin/ads/$adId/unfeature"),
      headers: headers,
    );

    final data = decode(response);

    if (response.statusCode == 200) return;

    throw Exception(errorMessage(data, "لغو ویژه آگهی انجام نشد"));
  }

  static Future<void> pinAd(
    int adId, {
    int days = 7,
    int position = 1,
  }) async {
    final response = await http.patch(
      url("/admin/ads/$adId/pin"),
      headers: headers,
      body: jsonEncode({
        "days": days,
        "position": position,
      }),
    );

    final data = decode(response);

    if (response.statusCode == 200) return;

    throw Exception(errorMessage(data, "پن کردن آگهی انجام نشد"));
  }

  static Future<void> unpinAd(int adId) async {
    final response = await http.patch(
      url("/admin/ads/$adId/unpin"),
      headers: headers,
    );

    final data = decode(response);

    if (response.statusCode == 200) return;

    throw Exception(errorMessage(data, "لغو پن آگهی انجام نشد"));
  }

  static Future<void> deleteAd(int adId) async {
    final response = await http.delete(
      url("/admin/ads/$adId"),
      headers: headers,
    );

    final data = decode(response);

    if (response.statusCode == 200 || response.statusCode == 204) return;

    throw Exception(errorMessage(data, "حذف آگهی انجام نشد"));
  }

  // ==================== ADMIN REPORTS ====================

  static Future<List<dynamic>> getAdminReports({String status = "all"}) async {
    final uri = url("/admin/reports").replace(
      queryParameters: {"status": status},
    );

    final response = await http.get(uri, headers: headers);
    final data = decode(response);

    if (response.statusCode == 200) {
      return listFrom(data, "reports");
    }

    throw Exception(errorMessage(data, "خطا در دریافت گزارش‌ها"));
  }

  static Future<void> updateReportStatus(int reportId, String status) async {
    final response = await http.patch(
      url("/admin/reports/$reportId/status"),
      headers: headers,
      body: jsonEncode({"status": status}),
    );

    final data = decode(response);

    if (response.statusCode == 200) return;

    throw Exception(errorMessage(data, "تغییر وضعیت گزارش انجام نشد"));
  }

  static Future<void> deleteReport(int reportId) async {
    final response = await http.delete(
      url("/admin/reports/$reportId"),
      headers: headers,
    );

    final data = decode(response);

    if (response.statusCode == 200 || response.statusCode == 204) return;

    throw Exception(errorMessage(data, "حذف گزارش انجام نشد"));
  }

  // ==================== ADMIN CHATS ====================

  static Future<List<dynamic>> getAdminChats() async {
    final response = await http.get(url("/admin/chats"), headers: headers);
    final data = decode(response);

    if (response.statusCode == 200) {
      return listFrom(data, "chats");
    }

    throw Exception(errorMessage(data, "خطا در دریافت چت‌ها"));
  }

  // ==================== ADMIN NOTIFICATIONS ====================

  static Future<List<dynamic>> getAdminNotifications() async {
    final response = await http.get(
      url("/admin/notifications"),
      headers: headers,
    );

    final data = decode(response);

    if (response.statusCode == 200) {
      return listFrom(data, "notifications");
    }

    throw Exception(errorMessage(data, "خطا در دریافت اعلان‌ها"));
  }

  static Future<void> sendAdminNotification({
    int? userId,
    required String title,
    required String body,
    String type = "admin",
    int? relatedAdId,
  }) async {
    final response = await http.post(
      url("/admin/notifications"),
      headers: headers,
      body: jsonEncode({
        "user_id": userId,
        "title": title,
        "body": body,
        "type": type,
        "related_ad_id": relatedAdId,
      }),
    );

    final data = decode(response);

    if (response.statusCode == 200 || response.statusCode == 201) return;

    throw Exception(errorMessage(data, "ارسال اعلان انجام نشد"));
  }
  // ==================== ADMIN PAYMENTS ====================

  static Future<List<dynamic>> getAdminPayments() async {
    final response = await http.get(
      url("/admin/payments"),
      headers: headers,
    );

    final data = decode(response);

    if (response.statusCode == 200) {
      return listFrom(data, "payments");
    }

    throw Exception(errorMessage(data, "خطا در دریافت پرداخت‌ها"));
  }

  static Future<void> createAdminPayment({
    int? userId,
    int? adId,
    required int amount,
    String currency = "AFN",
    String status = "paid",
    String purpose = "manual",
    String note = "",
  }) async {
    final response = await http.post(
      url("/admin/payments"),
      headers: headers,
      body: jsonEncode({
        "user_id": userId,
        "ad_id": adId,
        "amount": amount,
        "currency": currency,
        "status": status,
        "purpose": purpose,
        "note": note,
      }),
    );

    final data = decode(response);

    if (response.statusCode == 200 || response.statusCode == 201) return;

    throw Exception(errorMessage(data, "ثبت پرداخت انجام نشد"));
  }

  // ==================== ADMIN SETTINGS ====================

  static Future<Map<String, dynamic>> getAdminSettings() async {
    final response = await http.get(
      url("/admin/settings"),
      headers: headers,
    );

    final data = decode(response);

    if (response.statusCode == 200) {
      return mapFrom(data["settings"]);
    }

    throw Exception(errorMessage(data, "خطا در دریافت تنظیمات"));
  }

  static Future<void> saveAdminSetting({
    required String key,
    required dynamic value,
  }) async {
    final response = await http.post(
      url("/admin/settings"),
      headers: headers,
      body: jsonEncode({
        "key": key,
        "value": value,
      }),
    );

    final data = decode(response);

    if (response.statusCode == 200 || response.statusCode == 201) return;

    throw Exception(errorMessage(data, "ذخیره تنظیمات انجام نشد"));
  }

  // ==================== LOGS ====================

  static Future<List<dynamic>> getAdminLogs() async {
    final response = await http.get(
      url("/admin/logs"),
      headers: headers,
    );

    final data = decode(response);

    if (response.statusCode == 200) {
      return listFrom(data, "logs");
    }

    throw Exception(errorMessage(data, "خطا در دریافت لاگ‌ها"));
  }

  static Future<List<dynamic>> getAdminAuditLogs() async {
    return getAdminLogs();
  }

  static Future<void> createAdminAuditLog({
    required String action,
    String? targetType,
    int? targetId,
    Map<String, dynamic>? details,
  }) async {
    final response = await http.post(
      url("/admin/logs"),
      headers: headers,
      body: jsonEncode({
        "action": action,
        "target_type": targetType,
        "target_id": targetId,
        "details": details == null ? null : jsonEncode(details),
      }),
    );

    final data = decode(response);

    if (response.statusCode == 200 || response.statusCode == 201) return;

    throw Exception(errorMessage(data, "ثبت لاگ مدیریتی انجام نشد"));
  }

  // ==================== HEALTH ====================

  static Future<bool> ping() async {
    try {
      final response = await http.get(
        url("/health"),
        headers: publicHeaders,
      );

      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  static Future<String> serverVersion() async {
    try {
      final response = await http.get(
        url("/version"),
        headers: publicHeaders,
      );

      final data = decode(response);

      if (response.statusCode == 200 && data is Map) {
        return data["version"]?.toString() ?? "";
      }

      return "";
    } catch (_) {
      return "";
    }
  }

  static Future<Map<String, dynamic>> me() async {
  final response = await http.get(
    url("/auth/me"),
    headers: headers,
  );

  final data = decode(response);

  if (response.statusCode == 200 && data is Map) {
    return Map<String, dynamic>.from(data);
  }

  throw Exception(errorMessage(data, "خطا در دریافت اطلاعات کاربر"));
}

static Future<Map<String, String>> reverseGeocode(
  double latitude,
  double longitude,
) async {
  return {
    "province": "",
    "district": "",
    "address": "موقعیت GPS ثبت شد",
  };
}

static Future<void> logout() async {
  try {
    await http.post(
      url("/auth/logout"),
      headers: headers,
    );
  } catch (_) {}

  await Session.logout();
}
}