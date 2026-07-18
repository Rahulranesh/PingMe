import 'package:uuid/uuid.dart';

enum ChatRequestStatus {
  pending,
  accepted,
  rejected,
  expired,
}

class ChatRequest {
  final String id;
  final String fromUserId;
  final String fromUserName;
  final String fromDeviceId;
  final String toUserId;
  final String toDeviceId;
  final String message;
  final DateTime timestamp;
  final DateTime expiresAt;
  ChatRequestStatus status;
  final Map<String, dynamic> metadata;

  ChatRequest({
    String? id,
    required this.fromUserId,
    required this.fromUserName,
    required this.fromDeviceId,
    required this.toUserId,
    required this.toDeviceId,
    this.message = '',
    DateTime? timestamp,
    DateTime? expiresAt,
    this.status = ChatRequestStatus.pending,
    this.metadata = const {},
  }) : id = id ?? const Uuid().v4(),
       timestamp = timestamp ?? DateTime.now(),
       expiresAt = expiresAt ?? DateTime.now().add(const Duration(minutes: 5));

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fromUserId': fromUserId,
      'fromUserName': fromUserName,
      'fromDeviceId': fromDeviceId,
      'toUserId': toUserId,
      'toDeviceId': toDeviceId,
      'message': message,
      'timestamp': timestamp.toIso8601String(),
      'expiresAt': expiresAt.toIso8601String(),
      'status': status.name,
      'metadata': metadata,
    };
  }

  factory ChatRequest.fromJson(Map<String, dynamic> json) {
    return ChatRequest(
      id: json['id'],
      fromUserId: json['fromUserId'],
      fromUserName: json['fromUserName'],
      fromDeviceId: json['fromDeviceId'],
      toUserId: json['toUserId'],
      toDeviceId: json['toDeviceId'],
      message: json['message'] ?? '',
      timestamp: DateTime.parse(json['timestamp']),
      expiresAt: DateTime.parse(json['expiresAt']),
      status: ChatRequestStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => ChatRequestStatus.pending,
      ),
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
    );
  }

  bool get isExpired => DateTime.now().isAfter(expiresAt);
  bool get isPending => status == ChatRequestStatus.pending && !isExpired;
  bool get isAccepted => status == ChatRequestStatus.accepted;
  bool get isRejected => status == ChatRequestStatus.rejected;

  ChatRequest copyWith({
    ChatRequestStatus? status,
    String? message,
    Map<String, dynamic>? metadata,
  }) {
    return ChatRequest(
      id: id,
      fromUserId: fromUserId,
      fromUserName: fromUserName,
      fromDeviceId: fromDeviceId,
      toUserId: toUserId,
      toDeviceId: toDeviceId,
      message: message ?? this.message,
      timestamp: timestamp,
      expiresAt: expiresAt,
      status: status ?? this.status,
      metadata: metadata ?? this.metadata,
    );
  }
}
