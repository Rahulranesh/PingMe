import 'package:uuid/uuid.dart';

// TODO: Generate Hive adapters with flutter packages pub run build_runner build
// part 'user.g.dart';

class User {
  final String id;
  String name;
  String? bio;
  String? avatarUrl;
  String deviceId;
  String ipAddress;
  int port;
  bool isOnline;
  DateTime lastSeen;
  String? status;
  Map<String, dynamic> metadata;

  User({
    String? id,
    required this.name,
    this.bio,
    this.avatarUrl,
    required this.deviceId,
    required this.ipAddress,
    required this.port,
    this.isOnline = true,
    DateTime? lastSeen,
    this.status,
    Map<String, dynamic>? metadata,
  })  : id = id ?? const Uuid().v4(),
        lastSeen = lastSeen ?? DateTime.now(),
        metadata = metadata ?? {};

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      name: json['name'] as String,
      bio: json['bio'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      deviceId: json['deviceId'] as String,
      ipAddress: json['ipAddress'] as String,
      port: json['port'] as int,
      isOnline: json['isOnline'] as bool? ?? true,
      lastSeen: json['lastSeen'] != null
          ? DateTime.parse(json['lastSeen'] as String)
          : DateTime.now(),
      status: json['status'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'bio': bio,
      'avatarUrl': avatarUrl,
      'deviceId': deviceId,
      'ipAddress': ipAddress,
      'port': port,
      'isOnline': isOnline,
      'lastSeen': lastSeen.toIso8601String(),
      'status': status,
      'metadata': metadata,
    };
  }

  User copyWith({
    String? id,
    String? name,
    String? bio,
    String? avatarUrl,
    String? deviceId,
    String? ipAddress,
    int? port,
    bool? isOnline,
    DateTime? lastSeen,
    String? status,
    Map<String, dynamic>? metadata,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      bio: bio ?? this.bio,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      deviceId: deviceId ?? this.deviceId,
      ipAddress: ipAddress ?? this.ipAddress,
      port: port ?? this.port,
      isOnline: isOnline ?? this.isOnline,
      lastSeen: lastSeen ?? this.lastSeen,
      status: status ?? this.status,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is User && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
