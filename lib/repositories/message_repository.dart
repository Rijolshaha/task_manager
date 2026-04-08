import 'package:hive/hive.dart';
import '../models/chat_message.dart';

class MessageRepository {
  static const String _boxName = 'chat_messages';
  static const int _maxMessages = 100;

  Box<ChatMessage>? _box;

  /// Initialize the Hive box for chat messages
  Future<void> init() async {
    if (_box == null || !_box!.isOpen) {
      _box = await Hive.openBox<ChatMessage>(_boxName);
    }
  }

  /// Saves a message to the repository
  Future<void> saveMessage(ChatMessage message) async {
    await init();
    await _box!.put(message.id, message);
    await enforceMessageLimit();
  }

  /// Loads all messages in chronological order (oldest to newest)
  Future<List<ChatMessage>> loadMessages() async {
    await init();
    final messages = _box!.values.toList();

    // Sort by timestamp in chronological order (oldest first)
    messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    return messages;
  }

  /// Clears all messages from the repository
  Future<void> clearMessages() async {
    await init();
    await _box!.clear();
  }

  /// Enforces the maximum message limit by pruning oldest messages
  /// Keeps only the most recent 100 messages
  Future<void> enforceMessageLimit() async {
    await init();

    if (_box!.length <= _maxMessages) {
      return;
    }

    // Get all messages sorted by timestamp
    final messages = _box!.values.toList();
    messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    // Calculate how many messages to remove
    final messagesToRemove = messages.length - _maxMessages;

    // Remove the oldest messages
    for (int i = 0; i < messagesToRemove; i++) {
      await _box!.delete(messages[i].id);
    }
  }
}
