import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:bonsoir/bonsoir.dart';
import 'package:multicast_dns/multicast_dns.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';
import '../models/device.dart';
import '../models/user.dart';
import 'auth_service.dart';

class MDNSDiscoveryService extends ChangeNotifier {
  static const String serviceType = '_pingme._tcp';
  static const int defaultPort = 8889;
  static const Duration heartbeatInterval = Duration(seconds: 10);
  static const Duration deviceTimeout = Duration(seconds: 30);
  
  BonsoirBroadcast? _broadcast;
  BonsoirDiscovery? _discovery;
  HttpServer? _httpServer;
  final Map<String, Device> _discoveredDevices = {};
  final Map<String, WebSocketChannel> _connections = {};
  final Map<String, DateTime> _lastHeartbeat = {};
  final Map<String, StreamSubscription> _connectionSubscriptions = {};
  
  Timer? _heartbeatTimer;
  bool _isDiscovering = false;
  bool _isBroadcasting = false;
  User? _currentUser;
  
  Map<String, Device> get discoveredDevices => Map.unmodifiable(_discoveredDevices);
  bool get isDiscovering => _isDiscovering;
  bool get isBroadcasting => _isBroadcasting;

  Future<void> initialize() async {
    final authService = AuthService();
    _currentUser = authService.currentUser;
    
    if (_currentUser == null) {
      throw Exception('User not authenticated');
    }
    
    await startBroadcasting();
    startHeartbeat();
  }

  Future<void> startBroadcasting() async {
    if (_isBroadcasting) return;
    
    try {
      // Start HTTP server for WebSocket connections
      _httpServer = await HttpServer.bind(InternetAddress.anyIPv4, defaultPort);
      _httpServer!.listen(_handleHttpRequest);
      
      // Get device IP
      final interfaces = await NetworkInterface.list();
      String? ipAddress;
      
      for (final interface in interfaces) {
        for (final addr in interface.addresses) {
          if (addr.type == InternetAddressType.IPv4 && !addr.isLoopback) {
            ipAddress = addr.address;
            break;
          }
        }
        if (ipAddress != null) break;
      }
      
      if (ipAddress == null) {
        throw Exception('No network interface found');
      }
      
      // Create mDNS service
      final service = BonsoirService(
        name: 'pingme-device-${_currentUser!.id}',
        type: serviceType,
        port: defaultPort,
        attributes: {
          'userId': _currentUser!.id,
          'userName': _currentUser!.name,
          'deviceId': _currentUser!.deviceId,
          'avatarUrl': _currentUser!.avatarUrl ?? '',
          'status': _currentUser!.status ?? '',
          'ip': ipAddress,
          'platform': Platform.operatingSystem,
        },
      );
      
      _broadcast = BonsoirBroadcast(service: service);
      await _broadcast!.ready;
      await _broadcast!.start();
      
      _isBroadcasting = true;
      _currentUser!.ipAddress = ipAddress;
      notifyListeners();
      
      debugPrint('Broadcasting mDNS service: ${service.name} on $ipAddress:$defaultPort');
    } catch (e) {
      debugPrint('Error starting broadcast: $e');
      _isBroadcasting = false;
      rethrow;
    }
  }

  Future<void> stopBroadcasting() async {
    if (!_isBroadcasting) return;
    
    await _broadcast?.stop();
    _broadcast = null;
    await _httpServer?.close();
    _httpServer = null;
    _isBroadcasting = false;
    notifyListeners();
  }

  Future<void> startDiscovery() async {
    if (_isDiscovering) return;
    
    try {
      _discovery = BonsoirDiscovery(type: serviceType);
      await _discovery!.ready;
      
      _discovery!.eventStream?.listen((event) {
        if (event.type == BonsoirDiscoveryEventType.discoveryServiceFound) {
          event.service?.resolve(_discovery!.serviceResolver);
        } else if (event.type == BonsoirDiscoveryEventType.discoveryServiceResolved) {
          final service = event.service;
          if (service != null) {
            _handleServiceDiscovered(service);
          }
        } else if (event.type == BonsoirDiscoveryEventType.discoveryServiceLost) {
          final service = event.service;
          if (service != null) {
            _handleServiceLost(service);
          }
        }
      });
      
      await _discovery!.start();
      _isDiscovering = true;
      notifyListeners();
      
      debugPrint('Started mDNS discovery for $serviceType');
    } catch (e) {
      debugPrint('Error starting discovery: $e');
      _isDiscovering = false;
      rethrow;
    }
  }

  Future<void> stopDiscovery() async {
    if (!_isDiscovering) return;
    
    await _discovery?.stop();
    _discovery = null;
    _isDiscovering = false;
    notifyListeners();
  }

  void _handleServiceDiscovered(BonsoirService service) {
    final attributes = service.attributes ?? {};
    final userId = attributes['userId'];
    
    // Ignore our own service
    if (userId == _currentUser?.id) return;
    
    final device = Device(
      id: attributes['deviceId'] ?? service.name,
      name: attributes['userName'] ?? 'Unknown User',
      type: _getDeviceType(attributes['platform'] ?? ''),
      ipAddress: attributes['ip'] ?? '0.0.0.0',
      port: service.port ?? defaultPort,
      status: ConnectionStatus.disconnected,
      userId: userId,
      platform: attributes['platform'],
      metadata: {
        'avatarUrl': attributes['avatarUrl'],
        'status': attributes['status'],
        'serviceName': service.name,
      },
    );
    
    _discoveredDevices[device.id] = device;
    _lastHeartbeat[device.id] = DateTime.now();
    notifyListeners();
    
    debugPrint('Discovered device: ${device.name} at ${device.ipAddress}:${device.port}');
  }

  void _handleServiceLost(BonsoirService service) {
    final deviceId = service.attributes?['deviceId'] ?? service.name;
    
    if (_discoveredDevices.containsKey(deviceId)) {
      _discoveredDevices[deviceId]!.status = ConnectionStatus.disconnected;
      _closeConnection(deviceId);
      notifyListeners();
      
      debugPrint('Lost device: $deviceId');
    }
  }

  Future<void> connectToDevice(Device device) async {
    if (_connections.containsKey(device.id)) {
      debugPrint('Already connected to ${device.name}');
      return;
    }
    
    try {
      device.status = ConnectionStatus.connecting;
      notifyListeners();
      
      final uri = Uri.parse('ws://${device.ipAddress}:${device.port}/ws');
      final channel = IOWebSocketChannel.connect(uri);
      
      await channel.ready;
      
      // Send initial handshake
      final handshake = {
        'type': 'handshake',
        'userId': _currentUser!.id,
        'userName': _currentUser!.name,
        'deviceId': _currentUser!.deviceId,
        'timestamp': DateTime.now().toIso8601String(),
      };
      channel.sink.add(json.encode(handshake));
      
      // Listen for messages
      final subscription = channel.stream.listen(
        (message) => _handleWebSocketMessage(device.id, message),
        onError: (error) => _handleConnectionError(device.id, error),
        onDone: () => _handleConnectionClosed(device.id),
      );
      
      _connections[device.id] = channel;
      _connectionSubscriptions[device.id] = subscription;
      device.status = ConnectionStatus.connected;
      _lastHeartbeat[device.id] = DateTime.now();
      notifyListeners();
      
      debugPrint('Connected to ${device.name} via WebSocket');
    } catch (e) {
      device.status = ConnectionStatus.failed;
      notifyListeners();
      debugPrint('Failed to connect to ${device.name}: $e');
      rethrow;
    }
  }

  void _handleHttpRequest(HttpRequest request) async {
    if (request.uri.path == '/ws') {
      // Upgrade to WebSocket
      try {
        final socket = await WebSocketTransformer.upgrade(request);
        _handleWebSocketConnection(socket);
      } catch (e) {
        request.response.statusCode = HttpStatus.badRequest;
        request.response.write('WebSocket upgrade failed');
        request.response.close();
      }
    } else {
      // Regular HTTP request - could be used for file transfers
      request.response.statusCode = HttpStatus.notFound;
      request.response.close();
    }
  }

  void _handleWebSocketConnection(WebSocket socket) {
    String? deviceId;
    
    socket.listen(
      (message) {
        try {
          final data = json.decode(message);
          
          if (data['type'] == 'handshake') {
            deviceId = data['deviceId'];
            
            // Send handshake response
            final response = {
              'type': 'handshake_ack',
              'userId': _currentUser!.id,
              'userName': _currentUser!.name,
              'deviceId': _currentUser!.deviceId,
              'timestamp': DateTime.now().toIso8601String(),
            };
            socket.add(json.encode(response));
            
            // Update device status
            if (deviceId != null && _discoveredDevices.containsKey(deviceId)) {
              _discoveredDevices[deviceId]!.status = ConnectionStatus.connected;
              _lastHeartbeat[deviceId!] = DateTime.now();
              notifyListeners();
            }
          } else if (deviceId != null) {
            _handleWebSocketMessage(deviceId!, message);
          }
        } catch (e) {
          debugPrint('Error handling WebSocket message: $e');
        }
      },
      onError: (error) {
        debugPrint('WebSocket error: $error');
        if (deviceId != null) {
          _handleConnectionError(deviceId!, error);
        }
      },
      onDone: () {
        if (deviceId != null) {
          _handleConnectionClosed(deviceId!);
        }
      },
    );
  }

  void _handleWebSocketMessage(String deviceId, dynamic message) {
    try {
      final data = json.decode(message);
      final type = data['type'] as String?;
      
      switch (type) {
        case 'heartbeat':
          _lastHeartbeat[deviceId] = DateTime.now();
          // Send heartbeat response
          if (_connections.containsKey(deviceId)) {
            _connections[deviceId]!.sink.add(json.encode({
              'type': 'heartbeat_ack',
              'timestamp': DateTime.now().toIso8601String(),
            }));
          }
          break;
        
        case 'message':
          // Forward to chat service through HTTP connection
          debugPrint('Received message from $deviceId');
          if (data['message'] != null && _discoveredDevices.containsKey(deviceId)) {
            final device = _discoveredDevices[deviceId]!;
            _forwardMessageToChatService(data, device.ipAddress);
          }
          break;
        
        case 'typing':
          // Forward typing indicator to chat service
          if (_discoveredDevices.containsKey(deviceId)) {
            final device = _discoveredDevices[deviceId]!;
            _forwardMessageToChatService(data, device.ipAddress);
          }
          break;
        
        case 'receipt':
          // Forward receipt to chat service
          if (_discoveredDevices.containsKey(deviceId)) {
            final device = _discoveredDevices[deviceId]!;
            _forwardMessageToChatService(data, device.ipAddress);
          }
          break;
        
        case 'status_update':
          if (_discoveredDevices.containsKey(deviceId)) {
            _discoveredDevices[deviceId]!.metadata['status'] = data['status'];
            notifyListeners();
          }
          break;
      }
    } catch (e) {
      debugPrint('Error processing WebSocket message: $e');
    }
  }
  
  void _forwardMessageToChatService(Map<String, dynamic> data, String senderIp) async {
    try {
      // Forward to local chat service port
      final socket = await Socket.connect('127.0.0.1', 8889);
      socket.write(json.encode(data) + '\n');
      socket.close();
    } catch (e) {
      debugPrint('Failed to forward message to chat service: $e');
    }
  }

  void _handleConnectionError(String deviceId, dynamic error) {
    debugPrint('Connection error with $deviceId: $error');
    if (_discoveredDevices.containsKey(deviceId)) {
      _discoveredDevices[deviceId]!.status = ConnectionStatus.failed;
      notifyListeners();
    }
    _closeConnection(deviceId);
  }

  void _handleConnectionClosed(String deviceId) {
    debugPrint('Connection closed with $deviceId');
    if (_discoveredDevices.containsKey(deviceId)) {
      _discoveredDevices[deviceId]!.status = ConnectionStatus.disconnected;
      notifyListeners();
    }
    _closeConnection(deviceId);
  }

  void _closeConnection(String deviceId) {
    _connectionSubscriptions[deviceId]?.cancel();
    _connectionSubscriptions.remove(deviceId);
    _connections[deviceId]?.sink.close();
    _connections.remove(deviceId);
  }

  void startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(heartbeatInterval, (timer) {
      _sendHeartbeats();
      _checkTimeouts();
    });
  }

  void stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  void _sendHeartbeats() {
    final heartbeat = {
      'type': 'heartbeat',
      'timestamp': DateTime.now().toIso8601String(),
    };
    
    for (final entry in _connections.entries) {
      try {
        entry.value.sink.add(json.encode(heartbeat));
      } catch (e) {
        debugPrint('Failed to send heartbeat to ${entry.key}: $e');
      }
    }
  }

  void _checkTimeouts() {
    final now = DateTime.now();
    final toRemove = <String>[];
    
    for (final entry in _lastHeartbeat.entries) {
      if (now.difference(entry.value) > deviceTimeout) {
        toRemove.add(entry.key);
      }
    }
    
    for (final deviceId in toRemove) {
      if (_discoveredDevices.containsKey(deviceId)) {
        _discoveredDevices[deviceId]!.status = ConnectionStatus.disconnected;
        _closeConnection(deviceId);
      }
      _lastHeartbeat.remove(deviceId);
    }
    
    if (toRemove.isNotEmpty) {
      notifyListeners();
    }
  }

  DeviceType _getDeviceType(String platform) {
    switch (platform.toLowerCase()) {
      case 'android':
      case 'ios':
        return DeviceType.mobile;
      case 'macos':
      case 'windows':
      case 'linux':
        return DeviceType.desktop;
      default:
        return DeviceType.unknown;
    }
  }

  Future<void> sendMessage(String deviceId, Map<String, dynamic> message) async {
    if (!_connections.containsKey(deviceId)) {
      throw Exception('Not connected to device');
    }
    
    try {
      _connections[deviceId]!.sink.add(json.encode(message));
    } catch (e) {
      debugPrint('Failed to send message to $deviceId: $e');
      rethrow;
    }
  }

  @override
  void dispose() {
    stopHeartbeat();
    stopBroadcasting();
    stopDiscovery();
    
    for (final sub in _connectionSubscriptions.values) {
      sub.cancel();
    }
    for (final channel in _connections.values) {
      channel.sink.close();
    }
    
    _connections.clear();
    _connectionSubscriptions.clear();
    _discoveredDevices.clear();
    _lastHeartbeat.clear();
    
    super.dispose();
  }
}
