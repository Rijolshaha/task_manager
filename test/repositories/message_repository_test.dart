import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:task_manager/models/chat_message.dart';
import 'package:task_manager/models/message_status.dart';
import 'package:task_manager/repositories/message_repository.dart';

/// Unit tests for MessageRepository
///
/// **Validates: Requirements 6.1, 6.2, 6.6, 6.7**
///
/// These tests verify:
/// - Message save and load operations (Requirements 6.1, 6.2)
/// - Clear history functionality (Requirement 6.6)
/// - 100-message limit enforcement (Requirement 6.7)
/// - Chronological ordering (Requirement 6.2)
void main() {
  late MessageRepository repository;

  setUpAll(() async {
    // Initialize Hive for testing
    Hive.init('test/.hive_test');
    Hive.registerAdapter(MessageStatusAdapter());
    Hive.registerAdapter(ChatMessageAdapter());
  });

  setUp(() async {
    repository = MessageRepository();
    await repository.init();
    await repository.clearMessages();
  });

  tearDown(() async {
    await repository.clearMessages();
  });

  tearDownAll(() async {
    await Hive.close();
  });

  group('Message Save and Load Operations', () {
    test('saves and loads a single message correctly', () async {
      final message = ChatMessage(
        id: 'msg-1',
        content: 'Hello, world!',
        isUser: true,
        timestamp: DateTime(2024, 1, 1, 12, 0),
        status: MessageStatus.sent,
      );

      await repository.saveMessage(message);
      final loaded = await repository.loadMessages();

      expect(loaded.length, equals(1));
      expect(loaded.first, equals(message));
    });

    test('saves and loads multiple messages correctly', () async {
      final messages = [
        ChatMessage(
          id: 'msg-1',
          content: 'First message',
          isUser: true,
          timestamp: DateTime(2024, 1, 1, 12, 0),
          status: MessageStatus.sent,
        ),
        ChatMessage(
          id: 'msg-2',
          content: 'Second message',
          isUser: false,
          timestamp: DateTime(2024, 1, 1, 12, 1),
          status: MessageStatus.sent,
        ),
        ChatMessage(
          id: 'msg-3',
          content: 'Third message',
          isUser: true,
          timestamp: DateTime(2024, 1, 1, 12, 2),
          status: MessageStatus.sent,
        ),
      ];

      for (final message in messages) {
        await repository.saveMessage(message);
      }

      final loaded = await repository.loadMessages();

      expect(loaded.length, equals(3));
      expect(loaded, equals(messages));
    });

    test('overwrites message with same id', () async {
      final message1 = ChatMessage(
        id: 'msg-1',
        content: 'Original content',
        isUser: true,
        timestamp: DateTime(2024, 1, 1, 12, 0),
        status: MessageStatus.sending,
      );

      final message2 = ChatMessage(
        id: 'msg-1',
        content: 'Updated content',
        isUser: true,
        timestamp: DateTime(2024, 1, 1, 12, 0),
        status: MessageStatus.sent,
      );

      await repository.saveMessage(message1);
      await repository.saveMessage(message2);
      final loaded = await repository.loadMessages();

      expect(loaded.length, equals(1));
      expect(loaded.first.content, equals('Updated content'));
      expect(loaded.first.status, equals(MessageStatus.sent));
    });

    test('returns empty list when no messages stored', () async {
      final loaded = await repository.loadMessages();
      expect(loaded, isEmpty);
    });
  });

  group('Chronological Ordering', () {
    test('loads messages in chronological order (oldest first)', () async {
      // Add messages in random order
      final messages = [
        ChatMessage(
          id: 'msg-3',
          content: 'Third',
          isUser: true,
          timestamp: DateTime(2024, 1, 1, 12, 2),
          status: MessageStatus.sent,
        ),
        ChatMessage(
          id: 'msg-1',
          content: 'First',
          isUser: true,
          timestamp: DateTime(2024, 1, 1, 12, 0),
          status: MessageStatus.sent,
        ),
        ChatMessage(
          id: 'msg-2',
          content: 'Second',
          isUser: false,
          timestamp: DateTime(2024, 1, 1, 12, 1),
          status: MessageStatus.sent,
        ),
      ];

      for (final message in messages) {
        await repository.saveMessage(message);
      }

      final loaded = await repository.loadMessages();

      expect(loaded.length, equals(3));
      expect(loaded[0].content, equals('First'));
      expect(loaded[1].content, equals('Second'));
      expect(loaded[2].content, equals('Third'));
    });

    test('handles messages with same timestamp', () async {
      final timestamp = DateTime(2024, 1, 1, 12, 0);
      final messages = [
        ChatMessage(
          id: 'msg-1',
          content: 'Message 1',
          isUser: true,
          timestamp: timestamp,
          status: MessageStatus.sent,
        ),
        ChatMessage(
          id: 'msg-2',
          content: 'Message 2',
          isUser: false,
          timestamp: timestamp,
          status: MessageStatus.sent,
        ),
      ];

      for (final message in messages) {
        await repository.saveMessage(message);
      }

      final loaded = await repository.loadMessages();

      expect(loaded.length, equals(2));
      // Both messages should be present, order may vary for same timestamp
      expect(loaded.map((m) => m.id).toSet(), equals({'msg-1', 'msg-2'}));
    });
  });

  group('Clear History Functionality', () {
    test('clears all messages successfully', () async {
      final messages = [
        ChatMessage(
          id: 'msg-1',
          content: 'First',
          isUser: true,
          timestamp: DateTime(2024, 1, 1, 12, 0),
          status: MessageStatus.sent,
        ),
        ChatMessage(
          id: 'msg-2',
          content: 'Second',
          isUser: false,
          timestamp: DateTime(2024, 1, 1, 12, 1),
          status: MessageStatus.sent,
        ),
      ];

      for (final message in messages) {
        await repository.saveMessage(message);
      }

      await repository.clearMessages();
      final loaded = await repository.loadMessages();

      expect(loaded, isEmpty);
    });

    test('clear operation is idempotent', () async {
      final message = ChatMessage(
        id: 'msg-1',
        content: 'Test',
        isUser: true,
        timestamp: DateTime(2024, 1, 1, 12, 0),
        status: MessageStatus.sent,
      );

      await repository.saveMessage(message);
      await repository.clearMessages();
      await repository.clearMessages(); // Clear again

      final loaded = await repository.loadMessages();
      expect(loaded, isEmpty);
    });

    test('can save new messages after clearing', () async {
      final message1 = ChatMessage(
        id: 'msg-1',
        content: 'Before clear',
        isUser: true,
        timestamp: DateTime(2024, 1, 1, 12, 0),
        status: MessageStatus.sent,
      );

      final message2 = ChatMessage(
        id: 'msg-2',
        content: 'After clear',
        isUser: true,
        timestamp: DateTime(2024, 1, 1, 12, 1),
        status: MessageStatus.sent,
      );

      await repository.saveMessage(message1);
      await repository.clearMessages();
      await repository.saveMessage(message2);

      final loaded = await repository.loadMessages();

      expect(loaded.length, equals(1));
      expect(loaded.first.content, equals('After clear'));
    });
  });

  group('100-Message Limit Enforcement', () {
    test('enforces 100-message limit by pruning oldest messages', () async {
      // Add 105 messages
      for (int i = 0; i < 105; i++) {
        final message = ChatMessage(
          id: 'msg-$i',
          content: 'Message $i',
          isUser: i % 2 == 0,
          timestamp: DateTime(2024, 1, 1, 12, 0).add(Duration(minutes: i)),
          status: MessageStatus.sent,
        );
        await repository.saveMessage(message);
      }

      final loaded = await repository.loadMessages();

      // Should only have 100 messages
      expect(loaded.length, equals(100));

      // Should have messages 5-104 (oldest 5 removed)
      expect(loaded.first.id, equals('msg-5'));
      expect(loaded.last.id, equals('msg-104'));
    });

    test('does not prune when message count is exactly 100', () async {
      // Add exactly 100 messages
      for (int i = 0; i < 100; i++) {
        final message = ChatMessage(
          id: 'msg-$i',
          content: 'Message $i',
          isUser: true,
          timestamp: DateTime(2024, 1, 1, 12, 0).add(Duration(minutes: i)),
          status: MessageStatus.sent,
        );
        await repository.saveMessage(message);
      }

      final loaded = await repository.loadMessages();

      expect(loaded.length, equals(100));
      expect(loaded.first.id, equals('msg-0'));
      expect(loaded.last.id, equals('msg-99'));
    });

    test('does not prune when message count is less than 100', () async {
      // Add 50 messages
      for (int i = 0; i < 50; i++) {
        final message = ChatMessage(
          id: 'msg-$i',
          content: 'Message $i',
          isUser: true,
          timestamp: DateTime(2024, 1, 1, 12, 0).add(Duration(minutes: i)),
          status: MessageStatus.sent,
        );
        await repository.saveMessage(message);
      }

      final loaded = await repository.loadMessages();

      expect(loaded.length, equals(50));
      expect(loaded.first.id, equals('msg-0'));
      expect(loaded.last.id, equals('msg-49'));
    });

    test(
      'prunes correct number of messages when limit exceeded by multiple',
      () async {
        // Add 110 messages
        for (int i = 0; i < 110; i++) {
          final message = ChatMessage(
            id: 'msg-$i',
            content: 'Message $i',
            isUser: true,
            timestamp: DateTime(2024, 1, 1, 12, 0).add(Duration(minutes: i)),
            status: MessageStatus.sent,
          );
          await repository.saveMessage(message);
        }

        final loaded = await repository.loadMessages();

        // Should only have 100 messages
        expect(loaded.length, equals(100));

        // Should have messages 10-109 (oldest 10 removed)
        expect(loaded.first.id, equals('msg-10'));
        expect(loaded.last.id, equals('msg-109'));
      },
    );

    test('maintains chronological order after pruning', () async {
      // Add 105 messages
      for (int i = 0; i < 105; i++) {
        final message = ChatMessage(
          id: 'msg-$i',
          content: 'Message $i',
          isUser: true,
          timestamp: DateTime(2024, 1, 1, 12, 0).add(Duration(minutes: i)),
          status: MessageStatus.sent,
        );
        await repository.saveMessage(message);
      }

      final loaded = await repository.loadMessages();

      // Verify chronological order is maintained
      for (int i = 0; i < loaded.length - 1; i++) {
        expect(
          loaded[i].timestamp.isBefore(loaded[i + 1].timestamp) ||
              loaded[i].timestamp.isAtSameMomentAs(loaded[i + 1].timestamp),
          isTrue,
          reason: 'Messages should be in chronological order',
        );
      }
    });
  });

  group('Edge Cases', () {
    test('handles message with empty content', () async {
      final message = ChatMessage(
        id: 'msg-1',
        content: '',
        isUser: true,
        timestamp: DateTime(2024, 1, 1, 12, 0),
        status: MessageStatus.sent,
      );

      await repository.saveMessage(message);
      final loaded = await repository.loadMessages();

      expect(loaded.length, equals(1));
      expect(loaded.first.content, equals(''));
    });

    test('handles message with very long content', () async {
      final longContent = 'a' * 10000;
      final message = ChatMessage(
        id: 'msg-1',
        content: longContent,
        isUser: true,
        timestamp: DateTime(2024, 1, 1, 12, 0),
        status: MessageStatus.sent,
      );

      await repository.saveMessage(message);
      final loaded = await repository.loadMessages();

      expect(loaded.length, equals(1));
      expect(loaded.first.content, equals(longContent));
    });

    test('handles different message statuses', () async {
      final messages = [
        ChatMessage(
          id: 'msg-1',
          content: 'Sending',
          isUser: true,
          timestamp: DateTime(2024, 1, 1, 12, 0),
          status: MessageStatus.sending,
        ),
        ChatMessage(
          id: 'msg-2',
          content: 'Sent',
          isUser: true,
          timestamp: DateTime(2024, 1, 1, 12, 1),
          status: MessageStatus.sent,
        ),
        ChatMessage(
          id: 'msg-3',
          content: 'Error',
          isUser: true,
          timestamp: DateTime(2024, 1, 1, 12, 2),
          status: MessageStatus.error,
        ),
      ];

      for (final message in messages) {
        await repository.saveMessage(message);
      }

      final loaded = await repository.loadMessages();

      expect(loaded.length, equals(3));
      expect(loaded[0].status, equals(MessageStatus.sending));
      expect(loaded[1].status, equals(MessageStatus.sent));
      expect(loaded[2].status, equals(MessageStatus.error));
    });
  });
}
