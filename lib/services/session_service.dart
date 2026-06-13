import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Foydalanuvchi sessiyasini boshqaradi.
/// Parol xavfsiz (flutter_secure_storage) saqlanadi.
/// Boshqa ma'lumotlar SharedPreferences da saqlanadi.
class SessionService {
  static const _kLoggedIn = 'logged_in';
  static const _kName = 'user_name';
  static const _kEmail = 'user_email';
  static const _kImagePath = 'profile_image_path';
  static const _kLocale = 'app_locale';
  static const _kNotificationsEnabled = 'notifications_enabled';

  // ✅ Parol uchun xavfsiz storage key
  static const _kPassword = 'user_password_secure';

  static const _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  // ─────────────────────────────────────────
  // Login state
  // ─────────────────────────────────────────

  static Future<bool> isLoggedIn() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(_kLoggedIn) ?? false;
  }

  static Future<void> setLoggedIn(bool v) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kLoggedIn, v);
  }

  // ─────────────────────────────────────────
  // Foydalanuvchi ma'lumotlari
  // ─────────────────────────────────────────

  static Future<void> saveUser({
    required String name,
    required String email,
    required String password,
  }) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kName, name);
    await p.setString(_kEmail, email);

    // ✅ Parol faqat xavfsiz storage da saqlanadi
    await _secureStorage.write(key: _kPassword, value: password);
  }

  static Future<Map<String, String>> getUser() async {
    final p = await SharedPreferences.getInstance();

    // ✅ Parol xavfsiz storage dan o'qiladi
    final password = await _secureStorage.read(key: _kPassword) ?? '';

    return {
      'name': p.getString(_kName) ?? '',
      'email': p.getString(_kEmail) ?? '',
      'password': password,
    };
  }

  // ─────────────────────────────────────────
  // Profil rasmi
  // ─────────────────────────────────────────

  static Future<void> saveProfileImagePath(String path) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kImagePath, path);
  }

  static Future<String?> getProfileImagePath() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(_kImagePath);
  }

  // ─────────────────────────────────────────
  // Til sozlamalari
  // ─────────────────────────────────────────

  static Future<void> saveLocaleCode(String code) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kLocale, code);
  }

  static Future<String?> getLocaleCode() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(_kLocale);
  }

  // ─────────────────────────────────────────
  // Bildirishnomalar
  // ─────────────────────────────────────────

  static Future<bool> areNotificationsEnabled() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(_kNotificationsEnabled) ?? true;
  }

  static Future<void> setNotificationsEnabled(bool value) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kNotificationsEnabled, value);
  }

  // ─────────────────────────────────────────
  // Logout
  // ─────────────────────────────────────────

  static Future<void> clearAll() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_kLoggedIn);
    await p.remove(_kName);
    await p.remove(_kEmail);
    await p.remove(_kImagePath);
    // ✅ Xavfsiz storage dan ham o'chiramiz
    await _secureStorage.delete(key: _kPassword);
    // Locale ni saqlaymiz (til tanlovi qolsin)
  }
}
