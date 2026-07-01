
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'session.dart';

class Api {
  // آدرس صحیح API
  static const String baseUrl =
      "https://api.kooktalayi.com/api";

  // آدرس اصلی سایت برای عکس‌ها
  static const String publicBase =
      "https://api.kooktalayi.com";

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

      final body = utf8.decode(response.bodyBytes).trim();

      if (body.startsWith("<!DOCTYPE") || body.startsWith("<html")) {
        throw Exception(
          "این مسیر در سرور JSON برنگرداند. آدرس API یا route اشتباه است.",
        );
      }

      return jsonDecode(body);
    } catch (e) {
      if (e is Exception) rethrow;
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

    if (data is Map && data["items"] is List) {
      return List<dynamic>.from(data["items"]);
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

  static int asInt(dynamic value, {int fallback = 0}) {
    if (value == null) return fallback;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString()) ?? fallback;
  }

  static bool okStatus(http.Response response) {
    return response.statusCode >= 200 && response.statusCode < 300;
  }

  static Future<void> ensureOk(http.Response response, String fallback) async {
    final data = decode(response);

    if (okStatus(response)) {
      if (data is Map && data["success"] == false) {
        throw Exception(errorMessage(data, fallback));
      }
      return;
    }

    throw Exception(errorMessage(data, fallback));
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

  // ==================== ADMIN BASIC ====================

  static Future<Map<String, dynamic>> getAdminStats() async {
    final response = await http.get(url("/admin/stats"), headers: headers);
    final data = decode(response);

    if (response.statusCode == 200 && data is Map) {
      return mapFrom(data["stats"] ?? data);
    }

    throw Exception(errorMessage(data, "خطا در دریافت آمار مدیریت"));
  }

  static Future<Map<String, dynamic>> getAdminDashboard() async {
    final response = await http.get(url("/admin/dashboard"), headers: headers);
    final data = decode(response);

    if (response.statusCode == 200 && data is Map) {
      return mapFrom(data["dashboard"] ?? data["stats"] ?? data);
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

    await ensureOk(response, "مسدود کردن کاربر انجام نشد");
  }

  static Future<void> unbanUser(int userId) async {
    final response = await http.patch(
      url("/admin/users/$userId/unban"),
      headers: headers,
    );

    await ensureOk(response, "رفع مسدودی کاربر انجام نشد");
  }

  static Future<void> verifyUser(int userId) async {
    final response = await http.patch(
      url("/admin/users/$userId/verify"),
      headers: headers,
    );

    await ensureOk(response, "تأیید کاربر انجام نشد");
  }

  static Future<void> unverifyUser(int userId) async {
    final response = await http.patch(
      url("/admin/users/$userId/unverify"),
      headers: headers,
    );

    await ensureOk(response, "لغو تأیید کاربر انجام نشد");
  }

  static Future<void> blueVerifyUser(int userId) async {
    final response = await http.patch(
      url("/admin/users/$userId/blue-verify"),
      headers: headers,
    );

    await ensureOk(response, "فعال کردن تیک آبی انجام نشد");
  }

  static Future<void> unblueVerifyUser(int userId) async {
    final response = await http.patch(
      url("/admin/users/$userId/unblue-verify"),
      headers: headers,
    );

    await ensureOk(response, "لغو تیک آبی انجام نشد");
  }

  static Future<void> premiumUser(int userId, {int days = 30}) async {
    final response = await http.patch(
      url("/admin/users/$userId/premium"),
      headers: headers,
      body: jsonEncode({"days": days}),
    );

    await ensureOk(response, "فعال کردن پریمیوم انجام نشد");
  }

  static Future<void> unpremiumUser(int userId) async {
    final response = await http.patch(
      url("/admin/users/$userId/unpremium"),
      headers: headers,
    );

    await ensureOk(response, "لغو پریمیوم انجام نشد");
  }

  // ==================== ADMIN ADS ====================

  static Future<void> hideAd(int adId, String reason) async {
    final response = await http.patch(
      url("/admin/ads/$adId/hide"),
      headers: headers,
      body: jsonEncode({"reason": reason}),
    );

    await ensureOk(response, "مخفی کردن آگهی انجام نشد");
  }

  static Future<void> unhideAd(int adId) async {
    final response = await http.patch(
      url("/admin/ads/$adId/unhide"),
      headers: headers,
    );

    await ensureOk(response, "نمایش دوباره آگهی انجام نشد");
  }

  static Future<void> featureAd(int adId, {int days = 7}) async {
    final response = await http.patch(
      url("/admin/ads/$adId/feature"),
      headers: headers,
      body: jsonEncode({"days": days}),
    );

    await ensureOk(response, "ویژه کردن آگهی انجام نشد");
  }

  static Future<void> unfeatureAd(int adId) async {
    final response = await http.patch(
      url("/admin/ads/$adId/unfeature"),
      headers: headers,
    );

    await ensureOk(response, "لغو ویژه آگهی انجام نشد");
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

    await ensureOk(response, "پن کردن آگهی انجام نشد");
  }

  static Future<void> unpinAd(int adId) async {
    final response = await http.patch(
      url("/admin/ads/$adId/unpin"),
      headers: headers,
    );

    await ensureOk(response, "لغو پن آگهی انجام نشد");
  }

  static Future<void> deleteAd(int adId) async {
    final response = await http.delete(
      url("/admin/ads/$adId"),
      headers: headers,
    );

    await ensureOk(response, "حذف آگهی انجام نشد");
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

    await ensureOk(response, "تغییر وضعیت گزارش انجام نشد");
  }

  static Future<void> deleteReport(int reportId) async {
    final response = await http.delete(
      url("/admin/reports/$reportId"),
      headers: headers,
    );

    await ensureOk(response, "حذف گزارش انجام نشد");
  }

  // ==================== ADMIN CHATS BASIC ====================

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

    await ensureOk(response, "ارسال اعلان انجام نشد");
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

    await ensureOk(response, "ثبت پرداخت انجام نشد");
  }

  // ==================== ADMIN SETTINGS ====================

  static Future<Map<String, dynamic>> getAdminSettings() async {
    final response = await http.get(
      url("/admin/settings"),
      headers: headers,
    );

    final data = decode(response);

    if (response.statusCode == 200) {
      return mapFrom(data is Map ? data["settings"] : null);
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

    await ensureOk(response, "ذخیره تنظیمات انجام نشد");
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

  static Future<List<dynamic>> getAdminAdvancedLogs() async {
    final response = await http.get(
      url("/admin/advanced/logs"),
      headers: headers,
    );

    final data = decode(response);

    if (response.statusCode == 200) {
      return listFrom(data, "logs");
    }

    throw Exception(errorMessage(data, "خطا در دریافت لاگ‌ها"));
  }

  static Future<List<dynamic>> getAdminAuditLogs() async {
    try {
      return await getAdminAdvancedLogs();
    } catch (_) {
      return getAdminLogs();
    }
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

    await ensureOk(response, "ثبت لاگ مدیریتی انجام نشد");
  }

  // ==================== ADMIN ADVANCED DASHBOARD ====================

  static Future<Map<String, dynamic>> getAdminAdvancedStats() async {
    final response = await http.get(
      url("/admin/advanced/dashboard/advanced"),
      headers: headers,
    );

    final data = decode(response);

    if (response.statusCode == 200 && data is Map) {
      return mapFrom(data["stats"] ?? data["dashboard"] ?? data);
    }

    throw Exception(errorMessage(data, "خطا در دریافت داشبورد پیشرفته"));
  }

  static Future<Map<String, dynamic>> getAdminAdvancedSummary() async {
    final response = await http.get(
      url("/admin/advanced/summary"),
      headers: headers,
    );

    final data = decode(response);

    if (response.statusCode == 200 && data is Map) {
      return mapFrom(data["summary"] ?? data["stats"] ?? data);
    }

    throw Exception(errorMessage(data, "خطا در دریافت خلاصه مدیریت"));
  }

  // ==================== ADMIN ADVANCED USERS ====================

  static Future<List<dynamic>> getAdminAdvancedUsers({
    String q = "",
    String status = "all",
  }) async {
    final response = await http.get(
      url("/admin/advanced/users").replace(
        queryParameters: {
          if (q.trim().isNotEmpty) "q": q.trim(),
          if (status != "all") "status": status,
        },
      ),
      headers: headers,
    );

    final data = decode(response);

    if (response.statusCode == 200) return listFrom(data, "users");
    if (response.statusCode == 404) return getAdminUsers();

    throw Exception(errorMessage(data, "خطا در دریافت کاربران پیشرفته"));
  }

  static Future<List<dynamic>> getAdminOnlineUsers() async {
    final response = await http.get(
      url("/admin/advanced/users/online"),
      headers: headers,
    );

    final data = decode(response);

    if (response.statusCode == 200) return listFrom(data, "users");

    throw Exception(errorMessage(data, "خطا در دریافت کاربران آنلاین"));
  }

  static Future<void> muteUser(
    int userId, {
    int hours = 24,
    int? days,
  }) async {
    final muteDays = days ?? ((hours / 24).ceil() < 1 ? 1 : (hours / 24).ceil());

    final response = await http.patch(
      url("/admin/advanced/users/$userId/mute"),
      headers: headers,
      body: jsonEncode({
        "days": muteDays,
        "hours": hours,
      }),
    );

    await ensureOk(response, "سکوت کردن کاربر انجام نشد");
  }

  static Future<void> unmuteUser(int userId) async {
    final response = await http.patch(
      url("/admin/advanced/users/$userId/unmute"),
      headers: headers,
    );

    await ensureOk(response, "رفع سکوت کاربر انجام نشد");
  }

  // ==================== ADMIN ADVANCED ADS ====================

  static Future<List<dynamic>> getAdminAdvancedAds({
    String q = "",
    String status = "all",
    int? userId,
  }) async {
    final response = await http.get(
      url("/admin/advanced/ads").replace(
        queryParameters: {
          if (q.trim().isNotEmpty) "q": q.trim(),
          if (status != "all") "status": status,
          if (userId != null) "user_id": userId.toString(),
        },
      ),
      headers: headers,
    );

    final data = decode(response);

    if (response.statusCode == 200) return listFrom(data, "ads");

    if (response.statusCode == 404) {
      final ads = await getAds();
      return ads.where((ad) {
        if (ad is! Map) return false;

        if (userId != null) {
          final adUserId = int.tryParse(ad["user_id"]?.toString() ?? "") ?? 0;
          if (adUserId != userId) return false;
        }

        if (status != "all") {
          final adStatus = ad["status"]?.toString() ?? "approved";
          if (adStatus != status) return false;
        }

        if (q.trim().isEmpty) return true;

        final text = [
          ad["id"],
          ad["title"],
          ad["description"],
          ad["phone"],
          ad["province"],
          ad["district"],
          ad["city"],
          ad["category_name"],
        ].join(" ").toLowerCase();

        return text.contains(q.trim().toLowerCase());
      }).toList();
    }

    throw Exception(errorMessage(data, "خطا در دریافت آگهی‌های پیشرفته"));
  }

  static Future<List<dynamic>> getPendingAds() async {
    final response = await http.get(
      url("/admin/advanced/ads/pending"),
      headers: headers,
    );

    final data = decode(response);

    if (response.statusCode == 200) return listFrom(data, "ads");

    throw Exception(errorMessage(data, "خطا در دریافت آگهی‌های منتظر بررسی"));
  }

  static Future<void> approveAd(int adId) async {
    final response = await http.post(
      url("/admin/advanced/ads/$adId/approve"),
      headers: headers,
    );

    await ensureOk(response, "تأیید آگهی انجام نشد");
  }

  static Future<void> rejectAd(int adId, String reason) async {
    final response = await http.post(
      url("/admin/advanced/ads/$adId/reject"),
      headers: headers,
      body: jsonEncode({"reason": reason.trim()}),
    );

    await ensureOk(response, "رد آگهی انجام نشد");
  }

  static Future<void> setAdStatus({
    required int adId,
    required String status,
    String reason = "",
  }) async {
    if (status == "approved") {
      return approveAd(adId);
    }

    if (status == "rejected") {
      return rejectAd(adId, reason);
    }

    final response = await http.patch(
      url("/admin/advanced/ads/$adId/status"),
      headers: headers,
      body: jsonEncode({
        "status": status,
        "reason": reason,
      }),
    );

    await ensureOk(response, "تغییر وضعیت آگهی انجام نشد");
  }

  static Future<void> expireAd(int adId) async {
    final response = await http.patch(
      url("/admin/advanced/ads/$adId/expire"),
      headers: headers,
    );

    await ensureOk(response, "منقضی کردن آگهی انجام نشد");
  }

  static Future<void> extendAd(int adId, {int days = 30}) async {
    final response = await http.patch(
      url("/admin/advanced/ads/$adId/extend"),
      headers: headers,
      body: jsonEncode({"days": days}),
    );

    await ensureOk(response, "تمدید آگهی انجام نشد");
  }

  static Future<void> pinAdAdvanced(
    int adId, {
    int days = 7,
    int position = 1,
  }) async {
    final safeDays = days < 1 ? 1 : days;
    final safePosition = position < 1 ? 1 : (position > 20 ? 20 : position);

    final response = await http.patch(
      url("/admin/advanced/ads/$adId/pin-advanced"),
      headers: headers,
      body: jsonEncode({
        "days": safeDays,
        "position": safePosition,
      }),
    );

    await ensureOk(response, "پن پیشرفته آگهی انجام نشد");
  }

  static Future<void> unpinAdAdvanced(int adId) async {
    final response = await http.patch(
      url("/admin/advanced/ads/$adId/unpin-advanced"),
      headers: headers,
    );

    await ensureOk(response, "لغو پن پیشرفته انجام نشد");
  }

  // aliases for older AdminPage names
  static Future<void> pinAdvanced(
    int adId, {
    int days = 7,
    int position = 1,
  }) async {
    return pinAdAdvanced(adId, days: days, position: position);
  }

  static Future<void> unpinAdvanced(int adId) async {
    return unpinAdAdvanced(adId);
  }

  static Future<void> increaseAdCallCount(int adId) async {
    final response = await http.post(
      url("/admin/advanced/ads/$adId/call"),
      headers: headers,
    );

    await ensureOk(response, "ثبت تماس آگهی انجام نشد");
  }

  static Future<void> increaseAdChatCount(int adId) async {
    final response = await http.post(
      url("/admin/advanced/ads/$adId/chat"),
      headers: headers,
    );

    await ensureOk(response, "ثبت چت آگهی انجام نشد");
  }

  // ==================== ADMIN ADVANCED CHATS / MESSAGES ====================

  static Future<List<dynamic>> getAdminAdvancedChats({
    String q = "",
    String chatSearchText = "",
  }) async {
    final search = chatSearchText.trim().isNotEmpty ? chatSearchText : q;

    final response = await http.get(
      url("/admin/advanced/chats").replace(
        queryParameters: {
          if (search.trim().isNotEmpty) "q": search.trim(),
        },
      ),
      headers: headers,
    );

    final data = decode(response);

    if (response.statusCode == 200) {
      final chats = listFrom(data, "chats");
      if (chats.isNotEmpty) return chats;
      return listFrom(data, "messages");
    }

    throw Exception(errorMessage(data, "خطا در دریافت پیام‌های مدیریت"));
  }

  static Future<List<dynamic>> getAdminAdvancedMessages({
    String q = "",
    int? adId,
    String user = "",
  }) async {
    if (adId == null && user.trim().isEmpty) {
      return getAdminAdvancedChats(q: q);
    }

    final response = await http.get(
      url("/admin/advanced/chats").replace(
        queryParameters: {
          if (q.trim().isNotEmpty) "q": q.trim(),
          if (adId != null) "ad_id": adId.toString(),
          if (user.trim().isNotEmpty) "user": user.trim(),
        },
      ),
      headers: headers,
    );

    final data = decode(response);

    if (response.statusCode == 200) {
      final messages = listFrom(data, "messages");
      if (messages.isNotEmpty) return messages;
      return listFrom(data, "chats");
    }

    throw Exception(errorMessage(data, "خطا در دریافت پیام‌های مدیریت"));
  }

  static Future<void> deleteAdminMessage(int messageId) async {
    final response = await http.patch(
      url("/admin/advanced/chats/$messageId/delete"),
      headers: headers,
    );

    await ensureOk(response, "حذف پیام انجام نشد");
  }

  static Future<void> restoreAdminMessage(int messageId) async {
    final response = await http.patch(
      url("/admin/advanced/chats/$messageId/restore"),
      headers: headers,
    );

    await ensureOk(response, "برگرداندن پیام انجام نشد");
  }

  // ==================== ADMIN ADVANCED BLOCKED WORDS ====================

  static Future<List<dynamic>> getBlockedWords() async {
    final response = await http.get(
      url("/admin/advanced/blocked-words"),
      headers: headers,
    );

    final data = decode(response);

    if (response.statusCode == 200) return listFrom(data, "words");

    throw Exception(errorMessage(data, "خطا در دریافت کلمات ممنوعه"));
  }

  static Future<void> addBlockedWord({
    required String word,
    String type = "general",
  }) async {
    final response = await http.post(
      url("/admin/advanced/blocked-words"),
      headers: headers,
      body: jsonEncode({
        "word": word.trim(),
        "type": type.trim(),
      }),
    );

    await ensureOk(response, "افزودن کلمه ممنوعه انجام نشد");
  }

  static Future<void> deleteBlockedWord(int id) async {
    final response = await http.delete(
      url("/admin/advanced/blocked-words/$id"),
      headers: headers,
    );

    await ensureOk(response, "حذف کلمه ممنوعه انجام نشد");
  }

  static Future<void> toggleBlockedWord(int id, bool isActive) async {
    final response = await http.patch(
      url("/admin/advanced/blocked-words/$id"),
      headers: headers,
      body: jsonEncode({"is_active": isActive}),
    );

    await ensureOk(response, "تغییر وضعیت کلمه ممنوعه انجام نشد");
  }

  // ==================== ADMIN ADVANCED DEVICES ====================

  static Future<List<dynamic>> getAdminDevices() async {
    final response = await http.get(
      url("/admin/advanced/devices"),
      headers: headers,
    );

    final data = decode(response);

    if (response.statusCode == 200) return listFrom(data, "devices");

    throw Exception(errorMessage(data, "خطا در دریافت دستگاه‌ها"));
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
