import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

const apiBase = "https://api.kooktalayi.com/heratbazar-api/api";

class AuthService {
  static const String userKey = "hb_current_user";

  static Map<String, dynamic>? currentUser;

  static bool get isLoggedIn => currentUser != null;

  static int? get userId {
    if (currentUser == null) return null;

    final value = currentUser!["id"];
    if (value == null) return null;

    return int.tryParse(value.toString());
  }

  static String get userFullName {
    if (currentUser == null) return "";

    final firstName = currentUser!["first_name"]?.toString() ?? "";
    final lastName = currentUser!["last_name"]?.toString() ?? "";

    return "$firstName $lastName".trim();
  }

  static String get userPhone {
    if (currentUser == null) return "";

    return currentUser!["phone"]?.toString() ?? "";
  }

  static Future<void> saveUser(Map<String, dynamic> user) async {
    currentUser = user;

    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(
      userKey,
      jsonEncode(user),
    );
  }

  static Future<void> loadUser() async {
    final prefs = await SharedPreferences.getInstance();

    final text = prefs.getString(userKey);

    if (text == null || text.isEmpty) {
      currentUser = null;
      return;
    }

    try {
      final data = jsonDecode(text);

      if (data is Map<String, dynamic>) {
        currentUser = data;
      } else {
        currentUser = Map<String, dynamic>.from(data as Map);
      }
    } catch (e) {
      currentUser = null;
      await prefs.remove(userKey);
    }
  }

  static Future<Map<String, dynamic>> register({
    required String firstName,
    required String lastName,
    required String phone,
    required String securityAnswer,
  }) async {
    final response = await http.post(
      Uri.parse("$apiBase/auth/register"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "first_name": firstName.trim(),
        "last_name": lastName.trim(),
        "phone": phone.trim(),
        "security_question": "نام اولین معلم شما چیست؟",
        "security_answer": securityAnswer.trim(),
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      final user = Map<String, dynamic>.from(data["user"]);
      await saveUser(user);

      return data;
    }

    throw Exception(data["error"] ?? "ثبت‌نام انجام نشد");
  }

  static Future<Map<String, dynamic>> login({
    required String phone,
    required String loginCode,
  }) async {
    final response = await http.post(
      Uri.parse("$apiBase/auth/login"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "phone": phone.trim(),
        "login_code": loginCode.trim(),
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      final user = Map<String, dynamic>.from(data["user"]);
      await saveUser(user);

      return data;
    }

    throw Exception(data["error"] ?? "ورود انجام نشد");
  }

  static Future<Map<String, dynamic>> forgotCode({
    required String firstName,
    required String lastName,
    required String phone,
    required String securityAnswer,
  }) async {
    final response = await http.post(
      Uri.parse("$apiBase/auth/forgot-code"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "first_name": firstName.trim(),
        "last_name": lastName.trim(),
        "phone": phone.trim(),
        "security_answer": securityAnswer.trim(),
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data;
    }

    throw Exception(data["error"] ?? "بازیابی کد انجام نشد");
  }

  static Future<void> logout() async {
    currentUser = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(userKey);
  }
}