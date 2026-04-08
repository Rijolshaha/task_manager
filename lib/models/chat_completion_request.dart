import 'chat_message_payload.dart';

class ChatCompletionRequest {
  final String model;
  final List<ChatMessagePayload> messages;
  final int maxTokens;
  final double temperature;
  final bool stream;

  ChatCompletionRequest({
    required this.model,
    required this.messages,
    required this.maxTokens,
    required this.temperature,
    this.stream = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'model': model,
      'messages': messages.map((m) => m.toJson()).toList(),
      'max_tokens': maxTokens,
      'temperature': temperature,
      'stream': stream,
    };
  }
}
