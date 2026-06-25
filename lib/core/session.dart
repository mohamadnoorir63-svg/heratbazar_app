import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class Session {
  static const String userKey = "hb_current_user";
  static const String ownerTokenKey = "hb_owner_token";
  static const String favoritesKey = "hb_favorite_ads";
  static const String adminTokenKey = "hb_admin_token";

  static const String groupNameKey = "hb_group_guest_name";
  static const String groupAvatarKey = "hb_group_guest_avatar";
  static const String groupGuestIdKey = "hb_group_guest_id";

  static const String ownerPhone = "015906771961";
  static const String ownerPhoneIntl = "+4915906771961";

  static Map<String, dynamic>? currentUser;
  static String? _ownerToken;
  static String? _adminToken;
  static String? _groupGuestId;

  static bool get isLoggedIn => currentUser != null;

  static bool get isAdmin {
    final role = currentUser?["role"]?.toString() ?? "";
    return role == "admin" || role == "owner" || isOwner;
  }

  static bool get isOwner {
    final role = currentUser?["role"]?.toString() ?? "";
    final phone = userPhone.trim();

    return role == "owner" ||
        phone == ownerPhone ||
        phone == ownerPhoneIntl;
  }

  static int? get userId {
    final value = currentUser?["id"];
    if (value == null) return null;
    return int.tryParse(value.toString());
  }

  static String get userFullName {
    final firstName = currentUser?["first_name"]?.toString() ?? "";
    final lastName = currentUser?["last_name"]?.toString() ?? "";
    return "$firstName $lastName".trim();
  }

  static String get userPhone {
    return currentUser?["phone"]?.toString() ?? "";
  }

  static String get userEmail {
    return currentUser?["email"]?.toString() ?? "";
  }

  static String get userAvatar {
    return currentUser?["avatar_url"]?.toString() ?? "";
  }

  static bool get isVerified {
    final value = currentUser?["is_verified"];
    return value == true ||
        value.toString() == "true" ||
        value.toString() == "1";
  }

  static String get adminToken {
    return _adminToken ?? "";
  }

  static String get ownerHeaderPhone {
    return ownerPhone;
  }

  static Future<void> loadUser() async {
    final prefs = await SharedPreferences.getInstance();

    final text = prefs.getString(userKey);
    _ownerToken = prefs.getString(ownerTokenKey);
    _adminToken = prefs.getString(adminTokenKey);
    _groupGuestId = prefs.getString(groupGuestIdKey);

    if (text == null || text.isEmpty) {
      currentUser = null;
      await getGroupGuestId();
      return;
    }

    try {
      final data = jsonDecode(text);

      if (data is Map) {
        currentUser = Map<String, dynamic>.from(data);
      } else {
        currentUser = null;
        await prefs.remove(userKey);
      }
    } catch (_) {
      currentUser = null;
      await prefs.remove(userKey);
    }

    await getGroupGuestId();
  }

  static Future<void> saveUser(Map<String, dynamic> user) async {
    currentUser = Map<String, dynamic>.from(user);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(userKey, jsonEncode(currentUser));

    await getGroupGuestId();
  }

  static Future<void> updateCurrentUserField(String key, dynamic value) async {
    if (currentUser == null) return;

    currentUser![key] = value;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(userKey, jsonEncode(currentUser));
  }

  static Future<void> saveAdminToken(String token) async {
    final cleanToken = token.trim();
    _adminToken = cleanToken;

    final prefs = await SharedPreferences.getInstance();

    if (cleanToken.isEmpty) {
      await prefs.remove(adminTokenKey);
      return;
    }

    await prefs.setString(adminTokenKey, cleanToken);
  }

  static Future<void> clearAdminToken() async {
    _adminToken = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(adminTokenKey);
  }

  static Future<void> logout({
    bool keepGroupProfile = true,
  }) async {
    currentUser = null;
    _adminToken = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(userKey);
    await prefs.remove(adminTokenKey);

    if (!keepGroupProfile) {
      await clearGroupProfile(resetGuestId: true);
    }
  }

  static Future<String> getOwnerToken() async {
    if (_ownerToken != null && _ownerToken!.isNotEmpty) {
      return _ownerToken!;
    }

    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(ownerTokenKey);

    if (saved != null && saved.isNotEmpty) {
      _ownerToken = saved;
      return saved;
    }

    final token = "owner_${DateTime.now().millisecondsSinceEpoch}";
    _ownerToken = token;

    await prefs.setString(ownerTokenKey, token);
    return token;
  }

  static Future<String> getGroupGuestId() async {
    if (_groupGuestId != null && _groupGuestId!.isNotEmpty) {
      return _groupGuestId!;
    }

    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(groupGuestIdKey);

    if (saved != null && saved.isNotEmpty) {
      _groupGuestId = saved;
      return saved;
    }

    final now = DateTime.now();
    final id =
        "guest_${now.millisecondsSinceEpoch}_${now.microsecondsSinceEpoch}";

    _groupGuestId = id;
    await prefs.setString(groupGuestIdKey, id);

    return id;
  }

  static String get cachedGroupGuestId {
    return _groupGuestId ?? "";
  }

  static Future<void> resetGroupGuestId() async {
    _groupGuestId = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(groupGuestIdKey);

    await getGroupGuestId();
  }

  static Future<String> getGroupName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(groupNameKey) ?? "";
  }

  static Future<String> getGroupAvatar() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(groupAvatarKey) ?? "";
  }

  static Future<Map<String, String>> getGroupProfile() async {
    return {
      "guest_id": await getGroupGuestId(),
      "guest_name": await getGroupName(),
      "guest_avatar_url": await getGroupAvatar(),
    };
  }

  static Future<bool> hasGroupProfile() async {
    final name = await getGroupName();
    return name.trim().isNotEmpty;
  }

  static Future<void> saveGroupProfile({
    required String name,
    String avatarUrl = "",
  }) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(groupNameKey, name.trim());
    await prefs.setString(groupAvatarKey, avatarUrl.trim());

    await getGroupGuestId();
  }

  static Future<void> clearGroupProfile({
    bool resetGuestId = false,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(groupNameKey);
    await prefs.remove(groupAvatarKey);

    if (resetGuestId) {
      _groupGuestId = null;
      await prefs.remove(groupGuestIdKey);
    }
  }

  static Future<bool> isMyAd(String? adToken) async {
    if (adToken == null || adToken.trim().isEmpty) return false;

    final myToken = await getOwnerToken();
    return myToken == adToken.trim();
  }

  static String favoriteKeyForUser() {
    final id = userId;

    if (id != null) return "${favoritesKey}_user_$id";

    final phone = userPhone.trim();

    if (phone.isNotEmpty) return "${favoritesKey}_phone_$phone";

    return "${favoritesKey}_guest";
  }

  static String adIdOf(Map ad) {
    return ad["id"]?.toString() ?? "";
  }

  static Future<List<String>> getFavoriteAdIds() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(favoriteKeyForUser()) ?? [];
  }

  static Future<bool> isFavoriteAd(String adId) async {
    final cleanId = adId.trim();

    if (cleanId.isEmpty) return false;

    final ids = await getFavoriteAdIds();
    return ids.contains(cleanId);
  }

  static Future<bool> isFavoriteMap(Map ad) async {
    final adId = adIdOf(ad);
    return isFavoriteAd(adId);
  }

  static Future<bool> toggleFavoriteAd(String adId) async {
    final cleanId = adId.trim();

    if (cleanId.isEmpty) return false;

    final prefs = await SharedPreferences.getInstance();
    final key = favoriteKeyForUser();
    final ids = prefs.getStringList(key) ?? [];

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
    final adId = adIdOf(ad);
    return toggleFavoriteAd(adId);
  }

  static Future<void> removeFavoriteAd(String adId) async {
    final cleanId = adId.trim();

    if (cleanId.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final key = favoriteKeyForUser();
    final ids = prefs.getStringList(key) ?? [];

    ids.remove(cleanId);
    await prefs.setStringList(key, ids);
  }

  static Future<void> clearFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(favoriteKeyForUser());
  }
}