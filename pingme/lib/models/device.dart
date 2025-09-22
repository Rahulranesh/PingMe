import 'package:uuid/uuid.dart';

// TODO: Generate Hive adapters with flutter packages pub run build_runner build
// part 'device.g.dart';

enum DeviceType {
  mobile,
  tablet,
  desktop,
  watch,
  tv,
  unknown,
}

enum ConnectionStatus {
  connected,
  connecting,
  disconnected,
  failed,
  pairing,
}

class Device {
  final String id;
  String name;
  DeviceType type;
  String ipAddress;
  int port;
  String? macAddress;
  ConnectionStatus status;
  DateTime lastConnected;
  DateTime discoveredAt;
  String? userId;
  String? platform;
  String? model;
  String? osVersion;
  Map<String, dynamic> capabilities;
  Map<String, dynamic> metadata;
  int signalStrength;
  bool isTrusted;
  String? pairingCode;

  Device({
    String? id,
    required this.name,
    this.type = DeviceType.unknown,
    required this.ipAddress,
    required this.port,
    this.macAddress,
    this.status = ConnectionStatus.disconnected,
    DateTime? lastConnected,
    DateTime? discoveredAt,
    this.userId,
    this.platform,
    this.model,
    this.osVersion,
    Map<String, dynamic>? capabilities,
    Map<String, dynamic>? metadata,
    this.signalStrength = 100,
    this.isTrusted = false,
    this.pairingCode,
  })  : id = id ?? const Uuid().v4(),
        lastConnected = lastConnected ?? DateTime.now(),
        discoveredAt = discoveredAt ?? DateTime.now(),
        capabilities = capabilities ?? {},
        metadata = metadata ?? {};

  factory Device.fromJson(Map<String, dynamic> json) {
    return Device(
      id: json['id'] as String,
      name: json['name'] as String,
      type: DeviceType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => DeviceType.unknown,
      ),
      ipAddress: json['ipAddress'] as String,
      port: json['port'] as int,
      macAddress: json['macAddress'] as String?,
      status: ConnectionStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => ConnectionStatus.disconnected,
      ),
      lastConnected: DateTime.parse(json['lastConnected'] as String),
      discoveredAt: DateTime.parse(json['discoveredAt'] as String),
      userId: json['userId'] as String?,
      platform: json['platform'] as String?,
      model: json['model'] as String?,
      osVersion: json['osVersion'] as String?,
      capabilities: json['capabilities'] as Map<String, dynamic>? ?? {},
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
      signalStrength: json['signalStrength'] as int? ?? 100,
      isTrusted: json['isTrusted'] as bool? ?? false,
      pairingCode: json['pairingCode'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type.name,
      'ipAddress': ipAddress,
      'port': port,
      'macAddress': macAddress,
      'status': status.name,
      'lastConnected': lastConnected.toIso8601String(),
      'discoveredAt': discoveredAt.toIso8601String(),
      'userId': userId,
      'platform': platform,
      'model': model,
      'osVersion': osVersion,
      'capabilities': capabilities,
      'metadata': metadata,
      'signalStrength': signalStrength,
      'isTrusted': isTrusted,
      'pairingCode': pairingCode,
    };
  }

  Device copyWith({
    String? id,
    String? name,
    DeviceType? type,
    String? ipAddress,
    int? port,
    String? macAddress,
    ConnectionStatus? status,
    DateTime? lastConnected,
    DateTime? discoveredAt,
    String? userId,
    String? platform,
    String? model,
    String? osVersion,
    Map<String, dynamic>? capabilities,
    Map<String, dynamic>? metadata,
    int? signalStrength,
    bool? isTrusted,
    String? pairingCode,
  }) {
    return Device(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      ipAddress: ipAddress ?? this.ipAddress,
      port: port ?? this.port,
      macAddress: macAddress ?? this.macAddress,
      status: status ?? this.status,
      lastConnected: lastConnected ?? this.lastConnected,
      discoveredAt: discoveredAt ?? this.discoveredAt,
      userId: userId ?? this.userId,
      platform: platform ?? this.platform,
      model: model ?? this.model,
      osVersion: osVersion ?? this.osVersion,
      capabilities: capabilities ?? this.capabilities,
      metadata: metadata ?? this.metadata,
      signalStrength: signalStrength ?? this.signalStrength,
      isTrusted: isTrusted ?? this.isTrusted,
      pairingCode: pairingCode ?? this.pairingCode,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Device && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
