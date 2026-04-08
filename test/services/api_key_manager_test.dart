import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:task_manager/services/api_key_manager.dart';

/// Unit tests for ApiKeyManager
///
/// **Validates: Requirements 1.3, 1.4, 1.6**
///
/// These tests verify:
/// - Valid API key format acceptance (Requirement 1.3)
/// - Invalid API key format rejection (Requirement 1.3)
/// - Secure storage save/retrieve operations (Requirements 1.4, 1.6)
/// - Key deletion (Requirement 1.6)
void main() {
  late ApiKeyManager apiKeyManager;
  late MockSecureStorage mockStorage;

  setUp(() {
    mockStorage = MockSecureStorage();
    apiKeyManager = ApiKeyManager(storage: mockStorage);
  });

  tearDown(() {
    mockStorage.clear();
  });

  group('API Key Format Validation', () {
    group('Valid API key format acceptance', () {
      test('accepts valid key with sk- prefix and exactly 20 characters', () {
        final validKey = 'sk-' + 'a' * 17; // Exactly 20 chars
        expect(apiKeyManager.validateKeyFormat(validKey), isTrue);
      });

      test('accepts valid key with sk- prefix and more than 20 characters', () {
        final validKey = 'sk-' + 'a' * 50; // 53 chars total
        expect(apiKeyManager.validateKeyFormat(validKey), isTrue);
      });

      test('accepts valid key with alphanumeric characters', () {
        const validKey = 'sk-abc123XYZ789defGHI';
        expect(apiKeyManager.validateKeyFormat(validKey), isTrue);
      });

      test('accepts valid key with special characters', () {
        const validKey = 'sk-abc_123-xyz.789!@#'; // 23 chars total
        expect(apiKeyManager.validateKeyFormat(validKey), isTrue);
      });
    });

    group('Invalid API key format rejection', () {
      test('rejects key without sk- prefix', () {
        const invalidKey = 'api-key1234567890123';
        expect(apiKeyManager.validateKeyFormat(invalidKey), isFalse);
      });

      test('rejects key with uppercase SK- prefix', () {
        const invalidKey = 'SK-1234567890123456';
        expect(apiKeyManager.validateKeyFormat(invalidKey), isFalse);
      });

      test('rejects key with sk- prefix but less than 20 characters', () {
        const invalidKey = 'sk-12345678901234'; // 19 chars
        expect(apiKeyManager.validateKeyFormat(invalidKey), isFalse);
      });

      test('rejects key with sk_ instead of sk-', () {
        const invalidKey = 'sk_1234567890123456';
        expect(apiKeyManager.validateKeyFormat(invalidKey), isFalse);
      });

      test('rejects empty string', () {
        const invalidKey = '';
        expect(apiKeyManager.validateKeyFormat(invalidKey), isFalse);
      });

      test('rejects key with only sk-', () {
        const invalidKey = 'sk-';
        expect(apiKeyManager.validateKeyFormat(invalidKey), isFalse);
      });

      test('rejects key with whitespace before sk-', () {
        const invalidKey = ' sk-1234567890123456';
        expect(apiKeyManager.validateKeyFormat(invalidKey), isFalse);
      });
    });
  });

  group('Secure Storage Operations', () {
    group('Save and retrieve operations', () {
      test('saves and retrieves valid API key correctly', () async {
        const apiKey = 'sk-1234567890abcdefghij';

        await apiKeyManager.saveApiKey(apiKey);
        final retrieved = await apiKeyManager.getApiKey();

        expect(retrieved, equals(apiKey));
      });

      test('retrieves null when no key is stored', () async {
        final retrieved = await apiKeyManager.getApiKey();
        expect(retrieved, isNull);
      });

      test('overwrites existing key with new save', () async {
        const firstKey = 'sk-1234567890abcdefghij';
        const secondKey = 'sk-9876543210zyxwvutsrq';

        await apiKeyManager.saveApiKey(firstKey);
        await apiKeyManager.saveApiKey(secondKey);
        final retrieved = await apiKeyManager.getApiKey();

        expect(retrieved, equals(secondKey));
        expect(retrieved, isNot(equals(firstKey)));
      });

      test('preserves special characters in saved key', () async {
        const apiKey = 'sk-abc_123-xyz.789!@#';

        await apiKeyManager.saveApiKey(apiKey);
        final retrieved = await apiKeyManager.getApiKey();

        expect(retrieved, equals(apiKey));
      });

      test('preserves exact length of saved key', () async {
        const apiKey = 'sk-1234567890abcdefghij';

        await apiKeyManager.saveApiKey(apiKey);
        final retrieved = await apiKeyManager.getApiKey();

        expect(retrieved?.length, equals(apiKey.length));
      });

      test('uses correct storage key "openai_api_key"', () async {
        const apiKey = 'sk-1234567890abcdefghij';

        await apiKeyManager.saveApiKey(apiKey);

        // Verify the mock storage has the key with correct storage key
        final storedValue = await mockStorage.read(key: 'openai_api_key');
        expect(storedValue, equals(apiKey));
      });
    });

    group('Key deletion', () {
      test('deletes stored API key successfully', () async {
        const apiKey = 'sk-1234567890abcdefghij';

        await apiKeyManager.saveApiKey(apiKey);
        await apiKeyManager.deleteApiKey();
        final retrieved = await apiKeyManager.getApiKey();

        expect(retrieved, isNull);
      });

      test('delete operation is idempotent', () async {
        const apiKey = 'sk-1234567890abcdefghij';

        await apiKeyManager.saveApiKey(apiKey);
        await apiKeyManager.deleteApiKey();
        await apiKeyManager.deleteApiKey(); // Delete again

        final retrieved = await apiKeyManager.getApiKey();
        expect(retrieved, isNull);
      });

      test('can save new key after deletion', () async {
        const firstKey = 'sk-1234567890abcdefghij';
        const secondKey = 'sk-9876543210zyxwvutsrq';

        await apiKeyManager.saveApiKey(firstKey);
        await apiKeyManager.deleteApiKey();
        await apiKeyManager.saveApiKey(secondKey);
        final retrieved = await apiKeyManager.getApiKey();

        expect(retrieved, equals(secondKey));
      });
    });
  });

  group('Edge Cases', () {
    test('handles very long API keys', () async {
      final longKey = 'sk-' + 'a' * 200; // 203 chars total

      await apiKeyManager.saveApiKey(longKey);
      final retrieved = await apiKeyManager.getApiKey();

      expect(retrieved, equals(longKey));
    });

    test('validates minimum length boundary (19 chars rejected)', () {
      final key19 = 'sk-' + 'a' * 16; // Exactly 19 chars
      expect(apiKeyManager.validateKeyFormat(key19), isFalse);
    });

    test('validates minimum length boundary (20 chars accepted)', () {
      final key20 = 'sk-' + 'a' * 17; // Exactly 20 chars
      expect(apiKeyManager.validateKeyFormat(key20), isTrue);
    });
  });
}

/// Mock implementation of FlutterSecureStorage for testing
class MockSecureStorage implements FlutterSecureStorage {
  final Map<String, String> _storage = {};

  @override
  Future<void> write({
    required String key,
    required String? value,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (value != null) {
      _storage[key] = value;
    }
  }

  @override
  Future<String?> read({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    return _storage[key];
  }

  @override
  Future<void> delete({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    _storage.remove(key);
  }

  void clear() {
    _storage.clear();
  }

  @override
  Future<Map<String, String>> readAll({
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    return Map.from(_storage);
  }

  @override
  Future<void> deleteAll({
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    _storage.clear();
  }

  @override
  Future<bool> containsKey({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    return _storage.containsKey(key);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    return super.noSuchMethod(invocation);
  }
}
