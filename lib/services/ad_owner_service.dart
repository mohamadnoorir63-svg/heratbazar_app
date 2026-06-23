import 'dart:math';

class AdOwnerService {
  static String? _ownerToken;

  static Future<String> getOwnerToken() async {
    _ownerToken ??= _generateToken();
    return _ownerToken!;
  }

  static Future<bool> isMyAd(String? adToken) async {
    if (adToken == null || adToken.isEmpty) return false;

    final myToken = await getOwnerToken();
    return myToken == adToken;
  }

  static String _generateToken() {
    final random = Random();
    final time = DateTime.now().millisecondsSinceEpoch;
    final number = random.nextInt(999999999);
    return 'owner_${time}_$number';
  }
}
