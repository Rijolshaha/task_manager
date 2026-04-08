int _parseInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

class ChatCompletionResponse {
  final String id;
  final String object;
  final int created;
  final String model;
  final List<Choice> choices;
  final Usage? usage;

  ChatCompletionResponse({
    required this.id,
    required this.object,
    required this.created,
    required this.model,
    required this.choices,
    this.usage,
  });

  factory ChatCompletionResponse.fromJson(Map<String, dynamic> json) {
    return ChatCompletionResponse(
      id: json['id']?.toString() ?? '',
      object: json['object']?.toString() ?? '',
      created: _parseInt(json['created']),
      model: json['model']?.toString() ?? '',
      choices: (json['choices'] as List?)
              ?.map((c) => Choice.fromJson(c as Map<String, dynamic>))
              .toList() ??
          [],
      usage: json['usage'] != null
          ? Usage.fromJson(json['usage'] as Map<String, dynamic>)
          : null,
    );
  }
}

class Choice {
  final int index;
  final Message message;
  final String? finishReason;
  final Delta? delta;

  Choice({
    required this.index,
    required this.message,
    this.finishReason,
    this.delta,
  });

  factory Choice.fromJson(Map<String, dynamic> json) {
    return Choice(
      index: _parseInt(json['index']),
      message: json['message'] != null
          ? Message.fromJson(json['message'] as Map<String, dynamic>)
          : Message(role: '', content: ''),
      finishReason: (json['finish_reason'] ?? json['finishReason'])?.toString(),
      delta: json['delta'] != null
          ? Delta.fromJson(json['delta'] as Map<String, dynamic>)
          : null,
    );
  }
}

class Message {
  final String role;
  final String content;

  Message({required this.role, required this.content});

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      role: json['role'] as String? ?? '',
      content: json['content'] as String? ?? '',
    );
  }
}

class Delta {
  final String? role;
  final String? content;

  Delta({this.role, this.content});

  factory Delta.fromJson(Map<String, dynamic> json) {
    return Delta(
      role: json['role'] as String?,
      content: json['content'] as String?,
    );
  }
}

class Usage {
  final int promptTokens;
  final int completionTokens;
  final int totalTokens;

  Usage({
    required this.promptTokens,
    required this.completionTokens,
    required this.totalTokens,
  });

  factory Usage.fromJson(Map<String, dynamic> json) {
    return Usage(
      promptTokens: _parseInt(json['prompt_tokens'] ?? json['promptTokens']),
      completionTokens: _parseInt(json['completion_tokens'] ?? json['completionTokens']),
      totalTokens: _parseInt(json['total_tokens'] ?? json['totalTokens']),
    );
  }
}
