import 'package:uuid/uuid.dart';

// TODO: Generate Hive adapters with flutter packages pub run build_runner build
// part 'message.g.dart';

enum MessageType {
  text,
  image,
  video,
  audio,
  file,
  location,
  contact,
  typing,
  system,
}

enum MessageStatus {
  pending,
  sending,
  sent,
  delivered,
  read,
  failed,
}

class Message {
  final String id;
  final String chatId;
  final String senderId;
  final String senderName;
  final String? receiverId;
  String content;
  final MessageType type;
  MessageStatus status;
  final DateTime timestamp;
  DateTime? editedAt;
  DateTime? deletedAt;
  DateTime? readAt;
  String? replyToId;
  List<String> attachments;
  Map<String, dynamic> metadata;
  bool isEncrypted;

  Message({
    String? id,
    required this.chatId,
    required this.senderId,
    required this.senderName,
    this.receiverId,
    required this.content,
    this.type = MessageType.text,
    this.status = MessageStatus.pending,
    DateTime? timestamp,
    this.editedAt,
    this.deletedAt,
    this.readAt,
    this.replyToId,
    List<String>? attachments,
    Map<String, dynamic>? metadata,
    this.isEncrypted = false,
  })  : id = id ?? const Uuid().v4(),
        timestamp = timestamp ?? DateTime.now(),
        attachments = attachments ?? [],
        metadata = metadata ?? {};

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'] as String,
      chatId: json['chatId'] as String,
      senderId: json['senderId'] as String,
      senderName: json['senderName'] as String,
      receiverId: json['receiverId'] as String?,
      content: json['content'] as String,
      type: MessageType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => MessageType.text,
      ),
      status: MessageStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => MessageStatus.pending,
      ),
      timestamp: DateTime.parse(json['timestamp'] as String),
      editedAt: json['editedAt'] != null
          ? DateTime.parse(json['editedAt'] as String)
          : null,
      deletedAt: json['deletedAt'] != null
          ? DateTime.parse(json['deletedAt'] as String)
          : null,
      readAt: json['readAt'] != null
          ? DateTime.parse(json['readAt'] as String)
          : null,
      replyToId: json['replyToId'] as String?,
      attachments: List<String>.from(json['attachments'] ?? []),
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
      isEncrypted: json['isEncrypted'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'chatId': chatId,
      'senderId': senderId,
      'senderName': senderName,
      'receiverId': receiverId,
      'content': content,
      'type': type.name,
      'status': status.name,
      'timestamp': timestamp.toIso8601String(),
      'editedAt': editedAt?.toIso8601String(),
      'deletedAt': deletedAt?.toIso8601String(),
      'readAt': readAt?.toIso8601String(),
      'replyToId': replyToId,
      'attachments': attachments,
      'metadata': metadata,
      'isEncrypted': isEncrypted,
    };
  }

  Message copyWith({
    String? id,
    String? chatId,
    String? senderId,
    String? senderName,
    String? receiverId,
    String? content,
    MessageType? type,
    MessageStatus? status,
    DateTime? timestamp,
    DateTime? editedAt,
    DateTime? deletedAt,
    DateTime? readAt,
    String? replyToId,
    List<String>? attachments,
    Map<String, dynamic>? metadata,
    bool? isEncrypted,
  }) {
    return Message(
      id: id ?? this.id,
      chatId: chatId ?? this.chatId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      receiverId: receiverId ?? this.receiverId,
      content: content ?? this.content,
      type: type ?? this.type,
      status: status ?? this.status,
      timestamp: timestamp ?? this.timestamp,
      editedAt: editedAt ?? this.editedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      readAt: readAt ?? this.readAt,
      replyToId: replyToId ?? this.replyToId,
      attachments: attachments ?? this.attachments,
      metadata: metadata ?? this.metadata,
      isEncrypted: isEncrypted ?? this.isEncrypted,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Message &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
