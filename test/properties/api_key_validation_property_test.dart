import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager/services/api_key_manager.dart';

/// **Validates: Requirements 1.3**
///
/// Property 1: API Key Format Validation
///
/// This property test verifies that the API key validation correctly accepts
/// keys starting with "sk-" and having at least 20 characters, and rejects
/// invalid formats. It ensures consistent validation behavior across all
/// possible input variations.
void main() {
  late ApiKeyManager apiKeyManager;

  setUp(() {
    apiKeyManager = ApiKeyManager();
  });

  group('Property 1: API Key Format Validation', () {
    test('Valid API keys with "sk-" prefix and 20+ chars are accepted', () async {
      const iterations = 100;
      final random = Random(42); // Seed for reproducibility

      for (int i = 0; i < iterations; i++) {
        // Generate valid API key: "sk-" + at least 17 more characters
        final suffixLength = 17 + random.nextInt(100); // 17 to 116 chars
        final validKey = 'sk-${_generateRandomString(random, suffixLength)}';

        // Verify length is at least 20
        expect(
          validKey.length,
          greaterThanOrEqualTo(20),
          reason: 'Generated key should be at least 20 characters',
        );

        // Verify validation accepts it
        final result = apiKeyManager.validateKeyFormat(validKey);
        expect(
          result,
          isTrue,
          reason:
              'Valid key with "sk-" prefix and ${validKey.length} chars should be accepted',
        );
      }
    });

    test('API keys without "sk-" prefix are rejected', () async {
      const iterations = 100;
      final random = Random(123);

      for (int i = 0; i < iterations; i++) {
        // Generate keys with various invalid prefixes
        final prefixes = [
          '',
          'sk',
          'sk_',
          'SK-',
          'api-',
          'key-',
          'pk-',
          'test-',
          'x-',
        ];
        final prefix = prefixes[random.nextInt(prefixes.length)];
        final suffixLength = 20 + random.nextInt(50);
        final invalidKey =
            '$prefix${_generateRandomString(random, suffixLength)}';

        // Skip if accidentally generated valid key
        if (invalidKey.startsWith('sk-') && invalidKey.length >= 20) {
          continue;
        }

        // Verify validation rejects it
        final result = apiKeyManager.validateKeyFormat(invalidKey);
        expect(
          result,
          isFalse,
          reason: 'Key without "sk-" prefix should be rejected: $invalidKey',
        );
      }
    });

    test(
      'API keys with "sk-" prefix but less than 20 chars are rejected',
      () async {
        const iterations = 50;
        final random = Random(456);

        for (int i = 0; i < iterations; i++) {
          // Generate keys with "sk-" but total length < 20
          // "sk-" is 3 chars, so suffix should be 0-16 chars (total 3-19)
          final suffixLength = random.nextInt(17); // 0 to 16 chars
          final shortKey = 'sk-${_generateRandomString(random, suffixLength)}';

          // Verify length is less than 20
          expect(
            shortKey.length,
            lessThan(20),
            reason: 'Generated key should be less than 20 characters',
          );

          // Verify validation rejects it
          final result = apiKeyManager.validateKeyFormat(shortKey);
          expect(
            result,
            isFalse,
            reason:
                'Key with "sk-" prefix but only ${shortKey.length} chars should be rejected',
          );
        }
      },
    );

    test(
      'Edge case: Exactly 20 characters with "sk-" prefix is accepted',
      () async {
        // "sk-" (3 chars) + 17 more chars = exactly 20
        final exactKey = 'sk-${_generateRandomString(Random(789), 17)}';

        expect(
          exactKey.length,
          equals(20),
          reason: 'Key should be exactly 20 characters',
        );

        final result = apiKeyManager.validateKeyFormat(exactKey);
        expect(
          result,
          isTrue,
          reason: 'Key with exactly 20 characters should be accepted',
        );
      },
    );

    test('Edge case: 19 characters with "sk-" prefix is rejected', () async {
      // "sk-" (3 chars) + 16 more chars = exactly 19
      final shortKey = 'sk-${_generateRandomString(Random(101), 16)}';

      expect(
        shortKey.length,
        equals(19),
        reason: 'Key should be exactly 19 characters',
      );

      final result = apiKeyManager.validateKeyFormat(shortKey);
      expect(
        result,
        isFalse,
        reason: 'Key with only 19 characters should be rejected',
      );
    });

    test('Empty string is rejected', () {
      final result = apiKeyManager.validateKeyFormat('');
      expect(result, isFalse, reason: 'Empty string should be rejected');
    });

    test('Whitespace and special characters in valid keys are accepted', () async {
      final random = Random(202);
      const iterations = 50;

      for (int i = 0; i < iterations; i++) {
        // Generate key with special characters
        final suffixLength = 17 + random.nextInt(50);
        final suffix = _generateRandomStringWithSpecialChars(
          random,
          suffixLength,
        );
        final keyWithSpecialChars = 'sk-$suffix';

        // Verify length is at least 20
        expect(
          keyWithSpecialChars.length,
          greaterThanOrEqualTo(20),
          reason: 'Key should be at least 20 characters',
        );

        // Verify validation accepts it (format validation only checks prefix and length)
        final result = apiKeyManager.validateKeyFormat(keyWithSpecialChars);
        expect(
          result,
          isTrue,
          reason:
              'Valid key with special characters should be accepted based on format',
        );
      }
    });

    test('Case sensitivity: "SK-" prefix is rejected', () {
      final invalidKey = 'SK-${'a' * 17}'; // 20 chars total

      expect(
        invalidKey.length,
        equals(20),
        reason: 'Key should be 20 characters',
      );

      final result = apiKeyManager.validateKeyFormat(invalidKey);
      expect(
        result,
        isFalse,
        reason: 'Uppercase "SK-" prefix should be rejected (case-sensitive)',
      );
    });

    test('Prefix variations are rejected', () {
      final invalidPrefixes = [
        'sk_',
        's-k',
        'sk',
        ' sk-',
        'sk- ',
        'xsk-',
        'sk-x',
      ];

      for (final prefix in invalidPrefixes) {
        // Create a key with enough length
        final key = prefix + ('a' * 20);

        // Skip if accidentally valid
        if (key.startsWith('sk-') && key.length >= 20) {
          continue;
        }

        final result = apiKeyManager.validateKeyFormat(key);
        expect(
          result,
          isFalse,
          reason: 'Key with invalid prefix variation should be rejected: $key',
        );
      }
    });
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
