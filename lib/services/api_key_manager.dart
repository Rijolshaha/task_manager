import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiKeyManager {
  static const _storageKey = 'gemini_api_key';
  final FlutterSecureStorage _storage;

  ApiKeyManager({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  Future<void> saveApiKey(String apiKey) async {
    await _storage.write(key: _storageKey, value: apiKey);
  }

  Future<String?> getApiKey() async {
    return await _storage.read(key: _storageKey);
  }

  Future<void> deleteApiKey() async {
    await _storage.delete(key: _storageKey);
  }

  Future<bool> hasApiKey() async {
    final key = await getApiKey();
    return key != null && key.trim().isNotEmpty;
  }

  bool validateKeyFormat(String apiKey) {
    return apiKey.trim().length >= 20;
  }
}
