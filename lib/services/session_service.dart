import 'package:shared_preferences/shared_preferences.dart';

class SessionService {
  static const _kLoggedIn = 'logged_in';
  static const _kName = 'user_name';
  static const _kEmail = 'user_email';
  static const _kPassword = 'user_password';
  static const _kImagePath = 'profile_image_path';
  static const _kLocale = 'app_locale';

  static Future<bool> isLoggedIn() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(_kLoggedIn) ?? false;
  }

  static Future<void> setLoggedIn(bool v) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kLoggedIn, v);
  }

  static Future<void> saveUser({
    required String name,
    required String email,
    required String password,
  }) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kName, name);
    await p.setString(_kEmail, email);
    await p.setString(_kPassword, password);
  }

  static Future<Map<String, String>> getUser() async {
    final p = await SharedPreferences.getInstance();
    return {
      'name': p.getString(_kName) ?? '',
      'email': p.getString(_kEmail) ?? '',
      'password': p.getString(_kPassword) ?? '',
    };
  }

  static Future<void> saveProfileImagePath(String path) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kImagePath, path);
  }

  static Future<String?> getProfileImagePath() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(_kImagePath);
  }

  static Future<void> saveLocaleCode(String code) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kLocale, code);
  }

  static Future<String?> getLocaleCode() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(_kLocale);
  }

  static Future<void> clearAll() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_kLoggedIn);
    await p.remove(_kName);
    await p.remove(_kEmail);
    await p.remove(_kPassword);
    await p.remove(_kImagePath);
    // locale ni o‘chirmaymiz (xohlasangiz remove qilamiz)
  }
}
