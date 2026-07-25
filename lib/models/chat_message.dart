import 'dart:convert';
import '../services/auth_service.dart';

enum MessageType {
  welcome,
  text,
  question,
  answer,
  asset,
  questioncontinue,
  usercomment,
  end,
  agentcomment,
  progressupdate,
}

class ChatMessage {
  final String? messageId;
  final String? channel;
  String? sectionId;
  String? componentId;
  final String? userId;
  final String? userName;
  final String? message;
  final MessageType? messageType;
  final String? command;
  final String? replyToId;
  final int? createdAt;
  bool? interactive;
  final Map<String, dynamic> rawJson;

  ChatMessage({
    this.messageId,
    this.channel,
    this.sectionId,
    this.componentId,
    this.userId,
    this.userName,
    this.message,
    this.messageType,
    this.command,
    this.replyToId,
    this.createdAt,
    this.interactive = false,
    this.rawJson = const {},
  });

  final Map<String, String> _confidenceOptions = {
    'noidea': 'No Idea',
    'notsure': 'Not sure',
    'mostlysure': 'Mostly Sure',
    'confident': 'Confident',
  };

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    int? parsedCreatedAt;
    final rawCreatedAt = json['createdat'] ?? json['date'];
    if (rawCreatedAt is int) {
      parsedCreatedAt = rawCreatedAt;
    } else if (rawCreatedAt is String) {
      parsedCreatedAt = int.tryParse(rawCreatedAt);
    }

    String mainMessage = json['message']?.toString() ?? '';

    String? sectionId = json['sectionid'];
    String? componentId = json['componentid'];
    String? rawMessageType = json['messagetype']?.toString().toLowerCase();

    try {
      final messageJson = jsonDecode(mainMessage);
      if (rawMessageType == null) {
        if (messageJson['question'] is Map<String, dynamic>) {
          rawMessageType = 'question';
        } else if (messageJson['assetthumbnail'] is String) {
          rawMessageType = 'asset';
        } else {
          rawMessageType = 'text';
        }
      }
      if (sectionId == null && messageJson['sectionid'] is String) {
        sectionId = messageJson['sectionid'];
      }
      if (componentId == null && messageJson['componentid'] is String) {
        componentId = messageJson['componentid'];
      }
      mainMessage = messageJson['content']?.toString() ?? '';
    } catch (_) {}

    final messageType = MessageType.values.firstWhere(
      (element) => element.name.toLowerCase() == rawMessageType,
      orElse: () => MessageType.text,
    );

    bool interactive = false;
    if (messageType == MessageType.question || json['interactive'] == "yes") {
      interactive = true;
    }

    Map<String, dynamic> rawJson = Map<String, dynamic>.from(json);
    if (messageType == MessageType.question ||
        messageType == MessageType.asset) {
      mainMessage = json['message'];
      final jsonStr = json['message']?.toString() ?? "{}";
      try {
        final decoded = jsonDecode(jsonStr);
        if (decoded is Map<String, dynamic>) {
          rawJson.addAll(decoded);
        }
      } catch (_) {}
    }

    return ChatMessage(
      messageId: (json['messageid'] ?? json['id'])?.toString(),
      channel: json['channel']?.toString(),
      sectionId: sectionId,
      componentId: componentId,
      interactive: interactive,
      userId: (json['user'] ?? json['userid'])?.toString(),
      userName: json['name']?.toString(),
      message: mainMessage,
      messageType: messageType,
      command: json['command']?.toString(),
      replyToId: (json['replytoid'] ?? json['replyToId'])?.toString(),
      createdAt: parsedCreatedAt,
      rawJson: rawJson,
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      if (messageId != null) 'messageid': messageId,
      if (channel != null) 'channel': channel,
      if (sectionId != null) 'sectionid': sectionId,
      if (componentId != null) 'componentid': componentId,
      if (userId != null) 'userid': userId,
      if (userName != null) 'name': userName,
      if (message != null) 'message': message,
      if (messageType != null) 'messagetype': messageType!.name,
      if (command != null) 'command': command,
      if (replyToId != null) 'replytoid': replyToId,
      if (createdAt != null) 'createdat': createdAt,
    };
    return map;
  }

  bool get isMessageRemoved => command == 'messageremoved';
  bool get isKeepAlive => command == 'keepalive';

  String get text {
    if (messageType == MessageType.question && message != null) {
      try {
        final decoded = jsonDecode(message!);
        if (decoded is Map<String, dynamic>) {
          return decoded['question']?.toString() ??
              decoded['text']?.toString() ??
              decoded['title']?.toString() ??
              message!;
        }
      } catch (_) {}
    }
    return message ?? '';
  }

  bool get isUser =>
      userId == AuthService.userId ||
      messageType == MessageType.usercomment ||
      messageType == MessageType.answer;

  bool get isAI => !isUser;

  String get sender => isUser ? 'user' : 'ai';

  String? get assetThumbnail {
    final thumb = rawJson['assetthumbnail'];
    return thumb?.toString();
  }

  String? get assetUrl {
    final url = rawJson['asseturl'];
    return url?.toString();
  }

  String? get assetCaption {
    final cap = rawJson['content'];
    if (cap != null && cap.toString().isNotEmpty) {
      return cap.toString();
    }
    if (message != null &&
        message!.isNotEmpty &&
        !message!.trim().startsWith('{')) {
      return message;
    }
    return null;
  }

  bool? get isCorrect {
    if (rawJson['iscorrect'] is bool) return rawJson['iscorrect'] as bool;
    if (rawJson['correct'] is bool) return rawJson['correct'] as bool;
    if (rawJson['success'] is bool) return rawJson['success'] as bool;
    if (rawJson['is_correct'] is bool) return rawJson['is_correct'] as bool;
    return null;
  }

  String get actionButtonLabel {
    if (rawJson['button_text'] != null) {
      return rawJson['button_text'].toString();
    }
    if (rawJson['label'] != null) {
      return rawJson['label'].toString();
    }
    if (messageType == MessageType.welcome) return 'Start';
    if (messageType == MessageType.questioncontinue) return 'Continue';
    return text.isNotEmpty ? text : 'Action';
  }

  int? get selectedOptionIndex {
    if (rawJson['selected_option_index'] is int) {
      return rawJson['selected_option_index'] as int;
    }
    return null;
  }

  (String, String)? get confidence {
    if (rawJson['confidence'] is String) {
      return (rawJson['confidence'], _confidenceOptions[rawJson['confidence']])
          as (String, String);
    }
    return null;
  }

  ChatMessage copyWith({
    String? messageId,
    String? channel,
    String? sectionId,
    String? componentId,
    String? userId,
    String? userName,
    String? message,
    MessageType? messageType,
    String? command,
    String? replyToId,
    int? createdAt,
    bool? interactive,
    Map<String, dynamic>? rawJson,
  }) {
    return ChatMessage(
      messageId: messageId ?? this.messageId,
      channel: channel ?? this.channel,
      sectionId: sectionId ?? this.sectionId,
      componentId: componentId ?? this.componentId,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      message: message ?? this.message,
      messageType: messageType ?? this.messageType,
      command: command ?? this.command,
      replyToId: replyToId ?? this.replyToId,
      createdAt: createdAt ?? this.createdAt,
      interactive: interactive ?? this.interactive,
      rawJson: rawJson ?? this.rawJson,
    );
  }
}
