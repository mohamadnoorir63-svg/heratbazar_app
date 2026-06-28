import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class Session {
  static const String userKey = "hb_current_user";
  static const String ownerTokenKey = "hb_owner_token";
  static const String favoritesKey = "hb_favorite_ads";
  static const String adminTokenKey = "hb_admin_token";

  static const String ownerPhone = "015906771961";
  static const String ownerPhoneIntl = "+4915906771961";
  static const String ownerEmail = "mohamadnoorir63@gmail.com";

  static Map<String, dynamic>? currentUser;
  static String? _ownerToken;
  static String? _adminToken;

  static bool get isLoggedIn => currentUser != null;

  static String _stringValue(String key) {
    return currentUser?[key]?.toString() ?? "";
  }

  static bool _boolValue(String key) {
    final value = currentUser?[key];
    return value == true ||
        value.toString() == "true" ||
        value.toString() == "1";
  }

  static bool get isOwner {
    final role = _stringValue("role");
    final phone = userPhone.trim();
    final email = userEmail.trim().toLowerCase();

    return role == "owner" ||
        phone == ownerPhone ||
        phone == ownerPhoneIntl ||
        email == ownerEmail;
  }

  static bool get isAdmin {
    final role = _stringValue("role");
    return role == "admin" || role == "owner" || isOwner;
  }

  static int? get userId {
    final value = currentUser?["id"];
    if (value == null) return null;
    return int.tryParse(value.toString());
  }

  static String get userFullName {
    final firstName = _stringValue("first_name");
    final lastName = _stringValue("last_name");
    return "$firstName $lastName".trim();
  }

  static String get userPhone => _stringValue("phone");

  static String get userEmail => _stringValue("email");

  static String get userContact {
    final email = userEmail.trim();
    final phone = userPhone.trim();

    if (email.isNotEmpty) return email;
    return phone;
  }

  static String get userAvatar => _stringValue("avatar_url");

  static bool get isVerified => _boolValue("is_verified") || isOwner;

  static bool get isPremium => _boolValue("is_premium");

  static bool get isBlueVerified => _boolValue("is_blue_verified");

  static String get adminToken => _adminToken ?? "";

  static String get ownerHeaderPhone => ownerPhone;

  static Future<SharedPreferences> get _prefs async {
    return SharedPreferences.getInstance();
  }

  static Future<void> loadUser() async {
    final prefs = await _prefs;

    _ownerToken = prefs.getString(ownerTokenKey);
    _adminToken = prefs.getString(adminTokenKey);

    final text = prefs.getString(userKey);

    if (text == null || text.trim().isEmpty) {
      currentUser = null;
      return;
    }

    try {
      final decoded = jsonDecode(text);

      if (decoded is Map) {
        currentUser = Map<String, dynamic>.from(decoded);
      } else {
        currentUser = null;
        await prefs.remove(userKey);
      }
    } catch (_) {
      currentUser = null;
      await prefs.remove(userKey);
    }
  }

  static Future<void> saveUser(Map<String, dynamic> user) async {
    currentUser = Map<String, dynamic>.from(user);

    final token = currentUser?["admin_token"]?.toString().trim() ?? "";

    if (token.isNotEmpty) {
      await saveAdminToken(token);
      currentUser?.remove("admin_token");
    }

    final prefs = await _prefs;
    await prefs.setString(userKey, jsonEncode(currentUser));
  }

  static Future<void> saveLoginResponse(Map<String, dynamic> data) async {
    final userData = data["user"];

    if (userData is Map) {
      await saveUser(Map<String, dynamic>.from(userData));
    }

    final token = data["admin_token"]?.toString().trim() ?? "";

    if (token.isNotEmpty) {
      await saveAdminToken(token);
    }
  }

  static Future<void> updateCurrentUserField(String key, dynamic value) async {
    if (currentUser == null) return;

    currentUser![key] = value;

    final prefs = await _prefs;
    await prefs.setString(userKey, jsonEncode(currentUser));
  }

  static Future<void> saveAdminToken(String token) async {
    final cleanToken = token.trim();
    _adminToken = cleanToken.isEmpty ? null : cleanToken;

    final prefs = await _prefs;

    if (cleanToken.isEmpty) {
      await prefs.remove(adminTokenKey);
      return;
    }

    await prefs.setString(adminTokenKey, cleanToken);
  }

  static Future<void> clearAdminToken() async {
    _adminToken = null;

    final prefs = await _prefs;
    await prefs.remove(adminTokenKey);
  }

  static Future<void> logout() async {
    currentUser = null;
    _adminToken = null;

    final prefs = await _prefs;
    await prefs.remove(userKey);
    await prefs.remove(adminTokenKey);
  }

  static Future<String> getOwnerToken() async {
    if (_ownerToken != null && _ownerToken!.trim().isNotEmpty) {
      return _ownerToken!;
    }

    final prefs = await _prefs;
    final saved = prefs.getString(ownerTokenKey);

    if (saved != null && saved.trim().isNotEmpty) {
      _ownerToken = saved;
      return saved;
    }

    final token = "owner_${DateTime.now().millisecondsSinceEpoch}";
    _ownerToken = token;

    await prefs.setString(ownerTokenKey, token);
    return token;
  }
  static Future<bool> isMyAd(String? adToken) async {
    final cleanToken = adToken?.trim() ?? "";

    if (cleanToken.isEmpty) return false;

    final myToken = await getOwnerToken();
    return myToken == cleanToken;
  }

  static String favoriteKeyForUser() {
    final id = userId;

    if (id != null) {
      return "${favoritesKey}_user_$id";
    }

    final email = userEmail.trim().toLowerCase();

    if (email.isNotEmpty) {
      return "${favoritesKey}_email_$email";
    }

    final phone = userPhone.trim();

    if (phone.isNotEmpty) {
      return "${favoritesKey}_phone_$phone";
    }

    return "${favoritesKey}_guest";
  }

  static String adIdOf(Map ad) {
    return ad["id"]?.toString() ?? "";
  }

  static Future<List<String>> getFavoriteAdIds() async {
    final prefs = await _prefs;
    return prefs.getStringList(favoriteKeyForUser()) ?? <String>[];
  }

  static Future<bool> isFavoriteAd(String adId) async {
    final cleanId = adId.trim();

    if (cleanId.isEmpty) return false;

    final ids = await getFavoriteAdIds();
    return ids.contains(cleanId);
  }

  static Future<bool> isFavoriteMap(Map ad) async {
    return isFavoriteAd(adIdOf(ad));
  }

  static Future<void> addFavoriteAd(String adId) async {
    final cleanId = adId.trim();

    if (cleanId.isEmpty) return;

    final prefs = await _prefs;
    final key = favoriteKeyForUser();
    final ids = prefs.getStringList(key) ?? <String>[];

    if (!ids.contains(cleanId)) {
      ids.add(cleanId);
      await prefs.setStringList(key, ids);
    }
  }

  static Future<void> addFavoriteMap(Map ad) async {
    await addFavoriteAd(adIdOf(ad));
  }

  static Future<void> removeFavoriteAd(String adId) async {
    final cleanId = adId.trim();

    if (cleanId.isEmpty) return;

    final prefs = await _prefs;
    final key = favoriteKeyForUser();
    final ids = prefs.getStringList(key) ?? <String>[];

    ids.remove(cleanId);
    await prefs.setStringList(key, ids);
  }

  static Future<void> removeFavoriteMap(Map ad) async {
    await removeFavoriteAd(adIdOf(ad));
  }

  static Future<bool> toggleFavoriteAd(String adId) async {
    final cleanId = adId.trim();

    if (cleanId.isEmpty) return false;

    final prefs = await _prefs;
    final key = favoriteKeyForUser();
    final ids = prefs.getStringList(key) ?? <String>[];

    if (ids.contains(cleanId)) {
      ids.remove(cleanId);
      await prefs.setStringList(key, ids);
      return false;
    }

    ids.add(cleanId);
    await prefs.setStringList(key, ids);
    return true;
  }

  static Future<bool> toggleFavoriteMap(Map ad) async {
    return toggleFavoriteAd(adIdOf(ad));
  }

  static Future<void> clearFavorites() async {
    final prefs = await _prefs;
    await prefs.remove(favoriteKeyForUser());
  }
}