import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiKeyManager {
  static const _storageKey = 'openai_api_key';
  final FlutterSecureStorage _storage;

  ApiKeyManager({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  /// Saves the API key to secure storage
  Future<void> saveApiKey(String apiKey) async {
    await _storage.write(key: _storageKey, value: apiKey);
  }

  /// Retrieves the stored API key
  Future<String?> getApiKey() async {
    return await _storage.read(key: _storageKey);
  }

  /// Deletes the stored API key
  Future<void> deleteApiKey() async {
    await _storage.delete(key: _storageKey);
  }

  /// Validates the API key format
  /// Returns true if the key has at least 20 characters
  bool validateKeyFormat(String apiKey) {
    return apiKey.length >= 20;
  }
}
