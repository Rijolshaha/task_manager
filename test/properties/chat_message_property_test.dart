import 'dart:io';
import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:task_manager/models/chat_message.dart';
import 'package:task_manager/models/message_status.dart';

/// **Validates: Requirements 6.1, 6.2, 6.3**
///
/// Property 19: Message Persistence Round-Trip
///
/// This property test verifies that ChatMessage objects can be serialized
/// and deserialized through Hive storage without data loss. It ensures that
/// all fields (id, content, isUser, timestamp, status) are correctly preserved
/// through the persistence layer.
void main() {
  late Box<ChatMessage> testBox;
  late String testPath;

  setUp(() async {
    // Create a unique test directory for each test run
    testPath =
        'test/.hive_test/chat_message_${DateTime.now().millisecondsSinceEpoch}';
    final directory = Directory(testPath);
    if (await directory.exists()) {
      await directory.delete(recursive: true);
    }
    await directory.create(recursive: true);

    // Initialize Hive with test path
    Hive.init(testPath);

    // Register adapters if not already registered
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(MessageStatusAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(ChatMessageAdapter());
    }

    // Open test box
    testBox = await Hive.openBox<ChatMessage>('test_chat_messages');
  });

  tearDown(() async {
    // Clean up
    if (testBox.isOpen) {
      await testBox.clear();
      await testBox.close();
    }
    await Hive.close();

    // Delete test directory
    final directory = Directory(testPath);
    if (await directory.exists()) {
      await directory.delete(recursive: true);
    }
  });

  group('Property 19: Message Persistence Round-Trip', () {
    test('ChatMessage round-trip through Hive preserves all fields', () async {
      const iterations = 100;
      final random = Random(42); // Seed for reproducibility

      for (int i = 0; i < iterations; i++) {
        // Generate random ChatMessage
        final message = _generateRandomChatMessage(random);

        // Save to Hive
        await testBox.put(message.id, message);

        // Retrieve from Hive
        final retrieved = testBox.get(message.id);

        // Verify all fields are preserved
        expect(retrieved, isNotNull, reason: 'Message should be retrievable');
        expect(
          retrieved!.id,
          equals(message.id),
          reason: 'ID should be preserved',
        );
        expect(
          retrieved.content,
          equals(message.content),
          reason: 'Content should be preserved',
        );
        expect(
          retrieved.isUser,
          equals(message.isUser),
          reason: 'isUser flag should be preserved',
        );
        expect(
          retrieved.timestamp,
          equals(message.timestamp),
          reason: 'Timestamp should be preserved',
        );
        expect(
          retrieved.status,
          equals(message.status),
          reason: 'Status should be preserved',
        );

        // Verify using equality operator
        expect(
          retrieved,
          equals(message),
          reason: 'Retrieved message should equal original',
        );

        // Clean up for next iteration
        await testBox.delete(message.id);
      }
    });

    test(
      'Multiple ChatMessages can be persisted and retrieved independently',
      () async {
        const iterations = 50;
        final random = Random(123);
        final messages = <ChatMessage>[];

        // Generate and save multiple messages
        for (int i = 0; i < iterations; i++) {
          final message = _generateRandomChatMessage(random);
          messages.add(message);
          await testBox.put(message.id, message);
        }

        // Verify all messages can be retrieved correctly
        for (final message in messages) {
          final retrieved = testBox.get(message.id);
          expect(
            retrieved,
            equals(message),
            reason: 'Each message should be independently retrievable',
          );
        }

        // Verify count
        expect(
          testBox.length,
          equals(iterations),
          reason: 'All messages should be stored',
        );
      },
    );

    test('ChatMessage with edge case values persists correctly', () async {
      final edgeCases = [
        // Empty content
        ChatMessage(
          id: 'edge-1',
          content: '',
          isUser: true,
          timestamp: DateTime.now(),
          status: MessageStatus.sent,
        ),
        // Very long content
        ChatMessage(
          id: 'edge-2',
          content: 'a' * 10000,
          isUser: false,
          timestamp: DateTime.now(),
          status: MessageStatus.sending,
        ),
        // Special characters in content
        ChatMessage(
          id: 'edge-3',
          content: '!@#\$%^&*()_+-=[]{}|;:\'",.<>?/~`\n\t\r',
          isUser: true,
          timestamp: DateTime.now(),
          status: MessageStatus.error,
        ),
        // Unicode and emoji
        ChatMessage(
          id: 'edge-4',
          content: '你好 مرحبا 🎉🚀💻',
          isUser: false,
          timestamp: DateTime.now(),
          status: MessageStatus.sent,
        ),
        // Very old timestamp
        ChatMessage(
          id: 'edge-5',
          content: 'Old message',
          isUser: true,
          timestamp: DateTime(1970, 1, 1),
          status: MessageStatus.sent,
        ),
        // Future timestamp
        ChatMessage(
          id: 'edge-6',
          content: 'Future message',
          isUser: false,
          timestamp: DateTime(2099, 12, 31),
          status: MessageStatus.sent,
        ),
      ];

      for (final message in edgeCases) {
        await testBox.put(message.id, message);
        final retrieved = testBox.get(message.id);
        expect(
          retrieved,
          equals(message),
          reason: 'Edge case message should persist correctly: ${message.id}',
        );
      }
    });
  });
}

/// Generates a random ChatMessage for property testing
ChatMessage _generateRandomChatMessage(Random random) {
  // Generate random ID
  final id = 'msg-${random.nextInt(1000000)}';

  // Generate random content (varying lengths)
  final contentLength = random.nextInt(500) + 1;
  final content = _generateRandomString(random, contentLength);

  // Random isUser flag
  final isUser = random.nextBool();

  // Random timestamp within a reasonable range (last 10 years)
  final now = DateTime.now();
  final daysAgo = random.nextInt(3650); // 10 years
  final timestamp = now.subtract(Duration(days: daysAgo));

  // Random status
  final statusValues = MessageStatus.values;
  final status = statusValues[random.nextInt(statusValues.length)];

  return ChatMessage(
    id: id,
    content: content,
    isUser: isUser,
    timestamp: timestamp,
    status: status,
  );
}

/// Generates a random string with various characters
String _generateRandomString(Random random, int length) {
  const chars =
      'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789 .,!?-_\n';
  return String.fromCharCodes(
    Iterable.generate(
      length,
      (_) => chars.codeUnitAt(random.nextInt(chars.length)),
    ),
  );
}
