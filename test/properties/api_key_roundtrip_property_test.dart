import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:task_manager/services/api_key_manager.dart';

/// **Validates: Requirements 1.7**
///
/// Property 2: API Key Configuration Round-Trip
///
/// This property test verifies that API keys can be saved to and retrieved
/// from secure storage without data loss. It ensures that the storage layer
/// correctly preserves the exact API key value through save and retrieve
/// operations, maintaining data integrity for all valid key formats.
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

  group('Property 2: API Key Configuration Round-Trip', () {
    test('Valid API keys persist and retrieve without data loss', () async {
      const iterations = 100;
      final random = Random(42); // Seed for reproducibility

      for (int i = 0; i < iterations; i++) {
        // Generate valid API key: "sk-" + at least 17 more characters
        final suffixLength = 17 + random.nextInt(100); // 17 to 116 chars
        final originalKey = 'sk-${_generateRandomString(random, suffixLength)}';

        // Verify it's a valid key
        expect(
          apiKeyManager.validateKeyFormat(originalKey),
          isTrue,
          reason: 'Generated key should be valid',
        );

        // Save the key
        await apiKeyManager.saveApiKey(originalKey);

        // Retrieve the key
        final retrievedKey = await apiKeyManager.getApiKey();

        // Verify the key is preserved exactly
        expect(
          retrievedKey,
          isNotNull,
          reason: 'Retrieved key should not be null',
        );
        expect(
          retrievedKey,
          equals(originalKey),
          reason: 'Retrieved key should match original exactly',
        );

        // Verify character-by-character equality
        expect(
          retrievedKey!.length,
          equals(originalKey.length),
          reason: 'Retrieved key length should match original',
        );
        for (int j = 0; j < originalKey.length; j++) {
          expect(
            retrievedKey[j],
            equals(originalKey[j]),
            reason: 'Character at position $j should match',
          );
        }

        // Clean up for next iteration
        await apiKeyManager.deleteApiKey();
      }
    });

    test('API keys with special characters persist correctly', () async {
      const iterations = 50;
      final random = Random(123);

      for (int i = 0; i < iterations; i++) {
        // Generate key with special characters
        final suffixLength = 17 + random.nextInt(50);
        final suffix = _generateRandomStringWithSpecialChars(
          random,
          suffixLength,
        );
        final originalKey = 'sk-$suffix';

        // Save and retrieve
        await apiKeyManager.saveApiKey(originalKey);
        final retrievedKey = await apiKeyManager.getApiKey();

        // Verify exact match
        expect(
          retrievedKey,
          equals(originalKey),
          reason: 'Key with special characters should be preserved exactly',
        );

        // Clean up
        await apiKeyManager.deleteApiKey();
      }
    });

    test(
      'Multiple save operations overwrite previous value correctly',
      () async {
        const iterations = 50;
        final random = Random(456);

        for (int i = 0; i < iterations; i++) {
          // Save first key
          final key1 = 'sk-${_generateRandomString(random, 20)}';
          await apiKeyManager.saveApiKey(key1);

          // Save second key (should overwrite)
          final key2 = 'sk-${_generateRandomString(random, 25)}';
          await apiKeyManager.saveApiKey(key2);

          // Retrieve should return the second key
          final retrieved = await apiKeyManager.getApiKey();
          expect(
            retrieved,
            equals(key2),
            reason: 'Second save should overwrite first value',
          );
          expect(
            retrieved,
            isNot(equals(key1)),
            reason: 'Retrieved key should not be the first key',
          );
        }
      },
    );

    test('Delete operation removes key completely', () async {
      const iterations = 50;
      final random = Random(789);

      for (int i = 0; i < iterations; i++) {
        // Save a key
        final key = 'sk-${_generateRandomString(random, 20)}';
        await apiKeyManager.saveApiKey(key);

        // Verify it's saved
        final beforeDelete = await apiKeyManager.getApiKey();
        expect(
          beforeDelete,
          equals(key),
          reason: 'Key should be retrievable before delete',
        );

        // Delete the key
        await apiKeyManager.deleteApiKey();

        // Verify it's gone
        final afterDelete = await apiKeyManager.getApiKey();
        expect(afterDelete, isNull, reason: 'Key should be null after delete');
      }
    });

    test(
      'Edge case: Minimum valid key length (20 chars) persists correctly',
      () async {
        // "sk-" (3 chars) + 17 more chars = exactly 20
        final minKey = 'sk-${_generateRandomString(Random(101), 17)}';

        expect(
          minKey.length,
          equals(20),
          reason: 'Key should be exactly 20 characters',
        );

        await apiKeyManager.saveApiKey(minKey);
        final retrieved = await apiKeyManager.getApiKey();

        expect(
          retrieved,
          equals(minKey),
          reason: 'Minimum length key should persist correctly',
        );
      },
    );

    test('Edge case: Very long key (200+ chars) persists correctly', () async {
      final longKey = 'sk-${_generateRandomString(Random(202), 200)}';

      expect(
        longKey.length,
        greaterThan(200),
        reason: 'Key should be longer than 200 characters',
      );

      await apiKeyManager.saveApiKey(longKey);
      final retrieved = await apiKeyManager.getApiKey();

      expect(
        retrieved,
        equals(longKey),
        reason: 'Very long key should persist correctly',
      );
    });

    test('Edge case: Keys with whitespace persist correctly', () async {
      final keysWithWhitespace = [
        'sk-abc def ghi jklmn',
        'sk-\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t',
        'sk-   spaces   here   ',
        'sk-newline\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n',
      ];

      for (final key in keysWithWhitespace) {
        await apiKeyManager.saveApiKey(key);
        final retrieved = await apiKeyManager.getApiKey();

        expect(
          retrieved,
          equals(key),
          reason: 'Key with whitespace should persist exactly: "$key"',
        );

        await apiKeyManager.deleteApiKey();
      }
    });

    test('Edge case: Keys with unicode and emoji persist correctly', () async {
      final unicodeKeys = [
        'sk-你好世界1234567890',
        'sk-مرحبا123456789012',
        'sk-🎉🚀💻🔥⚡️✨🌟💡🎯🏆',
        'sk-Привет12345678901',
      ];

      for (final key in unicodeKeys) {
        await apiKeyManager.saveApiKey(key);
        final retrieved = await apiKeyManager.getApiKey();

        expect(
          retrieved,
          equals(key),
          reason: 'Key with unicode/emoji should persist exactly',
        );

        await apiKeyManager.deleteApiKey();
      }
    });

    test('Retrieve without save returns null', () async {
      // Ensure no key is stored
      await apiKeyManager.deleteApiKey();

      final retrieved = await apiKeyManager.getApiKey();
      expect(
        retrieved,
        isNull,
        reason: 'Retrieving without saving should return null',
      );
    });

    test(
      'Empty string can be saved and retrieved (even if invalid format)',
      () async {
        // Note: This tests storage behavior, not validation
        const emptyKey = '';

        await apiKeyManager.saveApiKey(emptyKey);
        final retrieved = await apiKeyManager.getApiKey();

        expect(
          retrieved,
          equals(emptyKey),
          reason: 'Empty string should be stored and retrieved',
        );
      },
    );
  });
}

/// Generates a random string with alphanumeric characters
String _generateRandomString(Random random, int length) {
  const chars =
      'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  return String.fromCharCodes(
    Iterable.generate(
      length,
      (_) => chars.codeUnitAt(random.nextInt(chars.length)),
    ),
  );
}

/// Generates a random string with special characters
String _generateRandomStringWithSpecialChars(Random random, int length) {
  const chars =
      'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-_+=!@#\$%^&*()[]{}|;:,.<>?/~`';
  return String.fromCharCodes(
    Iterable.generate(
      length,
      (_) => chars.codeUnitAt(random.nextInt(chars.length)),
    ),
  );
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

  // Use noSuchMethod to handle all other methods
  @override
  dynamic noSuchMethod(Invocation invocation) {
    return super.noSuchMethod(invocation);
  }
}
