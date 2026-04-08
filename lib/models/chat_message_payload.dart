class ChatMessagePayload {
  final String role;
  final String content;

  ChatMessagePayload({required this.role, required this.content});

  Map<String, dynamic> toJson() {
    return {'role': role, 'content': content};
  }

  factory ChatMessagePayload.fromJson(Map<String, dynamic> json) {
    return ChatMessagePayload(
      role: json['role'] as String,
      content: json['content'] as String,
    );
  }
}
