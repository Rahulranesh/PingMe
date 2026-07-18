import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:bonsoir/bonsoir.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../models/device.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/chat_service.dart';
import '../services/chat_request_service.dart';
import '../utils/network_utils.dart';

class MDNSDiscoveryService extends ChangeNotifier {
  static const String serviceType = '_pingme._tcp';
  static const int defaultPort = 8889;
  static const Duration heartbeatInterval = Duration(seconds: 5);
  static const Duration deviceTimeout = Duration(seconds: 20);
  
  BonsoirBroadcast? _broadcast;
  BonsoirDiscovery? _discovery;
  HttpServer? _httpServer;
  final Map<String, Device> _discoveredDevices = {};
  final Map<String, WebSocketChannel> _connections = {};
  final Map<String, StreamSubscription> _connectionSubscriptions = {};
  final Map<String, DateTime> _lastHeartbeat = {};
  
  Timer? _heartbeatTimer;
  bool _isDiscovering = false;
  bool _isBroadcasting = false;
  User? _currentUser;
  
  Map<String, Device> get discoveredDevices => Map.unmodifiable(_discoveredDevices);
  bool get isDiscovering => _isDiscovering;
  bool get isBroadcasting => _isBroadcasting;

  // Public method to add or update a device in the discovered devices map
  void addOrUpdateDevice(Device device) {
    _discoveredDevices[device.id] = device;
    _lastHeartbeat[device.id] = DateTime.now();
    notifyListeners();
    debugPrint('Added/Updated device: ${device.name} (${device.id})');
  }
  
  bool hasActiveConnection(String deviceId) {
    return _connections.containsKey(deviceId) && _connections[deviceId] != null;
  }

  Future<void> initialize() async {
    final authService = AuthService();
    _currentUser = authService.currentUser;

    if (_currentUser == null) {
      throw Exception('User not authenticated');
    }

    try {
      await startBroadcasting().timeout(const Duration(seconds: 8));
      startHeartbeat();
      debugPrint('MDNS Discovery Service initialized successfully');
    } catch (e) {
      debugPrint('MDNS Discovery Service initialization failed: $e');
      // Continue without mDNS - app can still function
      _isBroadcasting = false;
      rethrow;
    }
  }

  Future<void> startBroadcasting() async {
    if (_isBroadcasting) return;
    
    try {
      // Start HTTP server for WebSocket connections
      _httpServer = await HttpServer.bind(InternetAddress.anyIPv4, defaultPort).timeout(const Duration(seconds: 5));
      _httpServer!.listen(_handleHttpRequest);
      
      // Get device IP with improved detection logic
      String? ipAddress = await _getBestIpAddress();
      
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
      await _broadcast!.ready.timeout(const Duration(seconds: 5));
      await _broadcast!.start().timeout(const Duration(seconds: 3));
      
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

    _isDiscovering = true;
    _discoveredDevices.clear(); // Clear old devices
    notifyListeners();

    try {
      // First try standard mDNS
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

      // Start direct discovery in parallel after a short delay
      Future.delayed(const Duration(seconds: 2), () async {
        if (_discoveredDevices.isEmpty && _isDiscovering) {
          debugPrint('No devices found via mDNS, trying direct connection...');
          await _tryDirectDiscovery();
        }
      });
    } catch (e) {
      debugPrint('Error in discovery: $e');
      await _tryDirectDiscovery();
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
      port: service.port,
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
    final deviceId = service.attributes['deviceId'] ?? service.name;
    
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

      // Try multiple connection methods
      WebSocketChannel? channel;
      String? successfulUrl;

      // Method 1: Try direct WebSocket connection to IP with /ws path
      try {
        final uri = Uri.parse('ws://${device.ipAddress}:${device.port}/ws');
        debugPrint('🔌 Trying direct WebSocket connection to: $uri');
        channel = IOWebSocketChannel.connect(uri);
        await channel.ready.timeout(const Duration(seconds: 5));
        successfulUrl = uri.toString();
        debugPrint('✅ Connected via /ws path');
      } catch (e) {
        debugPrint('❌ Direct WebSocket connection failed: $e');
      }

      // Method 2: Try without path
      if (channel == null) {
        try {
          final uri = Uri.parse('ws://${device.ipAddress}:${device.port}/');
          debugPrint('🔌 Trying connection without path to: $uri');
          channel = IOWebSocketChannel.connect(uri);
          await channel.ready.timeout(const Duration(seconds: 5));
          successfulUrl = uri.toString();
          debugPrint('✅ Connected via root path');
        } catch (e) {
          debugPrint('❌ Root path connection failed: $e');
        }
      }
      
      // Method 3: Try without trailing slash
      if (channel == null) {
        try {
          final uri = Uri.parse('ws://${device.ipAddress}:${device.port}');
          debugPrint('🔌 Trying connection without trailing slash: $uri');
          channel = IOWebSocketChannel.connect(uri);
          await channel.ready.timeout(const Duration(seconds: 5));
          successfulUrl = uri.toString();
          debugPrint('✅ Connected without trailing slash');
        } catch (e) {
          debugPrint('❌ No trailing slash connection failed: $e');
        }
      }

      if (channel == null) {
        throw Exception('All connection methods failed for ${device.name}');
      }

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

      debugPrint('Connected to ${device.name} via WebSocket at $successfulUrl');
    } catch (e) {
      device.status = ConnectionStatus.failed;
      notifyListeners();
      debugPrint('Failed to connect to ${device.name}: $e');
      rethrow;
    }
  }

  void _handleHttpRequest(HttpRequest request) async {
    debugPrint('📥 Incoming HTTP request from ${request.connectionInfo?.remoteAddress.address}:${request.connectionInfo?.remotePort}');
    debugPrint('📋 Request path: ${request.uri.path}');
    
    if (request.uri.path == '/ws' || request.uri.path == '/') {
      // Upgrade to WebSocket (accept both /ws and / paths)
      try {
        debugPrint('🔄 Attempting WebSocket upgrade...');
        final socket = await WebSocketTransformer.upgrade(request);
        debugPrint('✅ WebSocket upgrade successful from ${request.connectionInfo?.remoteAddress.address}');
        _handleWebSocketConnection(socket);
      } catch (e) {
        debugPrint('❌ WebSocket upgrade failed: $e');
        request.response.statusCode = HttpStatus.badRequest;
        request.response.write('WebSocket upgrade failed: $e');
        request.response.close();
      }
    } else {
      // Regular HTTP request - could be used for file transfers
      debugPrint('ℹ️ Regular HTTP request to ${request.uri.path}');
      request.response.statusCode = HttpStatus.notFound;
      request.response.close();
    }
  }

  void _handleWebSocketConnection(WebSocket socket) {
    String? deviceId;
    StreamSubscription? subscription;
    debugPrint('🔗 New WebSocket connection established');
    
    // Create a WebSocketChannel from the socket for bidirectional communication
    final channel = IOWebSocketChannel(socket);
    
    subscription = channel.stream.listen(
      (message) {
        try {
          debugPrint('📨 Received WebSocket message: $message');
          final data = json.decode(message);
          
          if (data['type'] == 'handshake') {
            deviceId = data['deviceId'];
            debugPrint('🤝 Handshake from device: $deviceId');
            
            // Store the connection using the device ID
            if (deviceId != null) {
              // Close any existing connection for this device
              if (_connections.containsKey(deviceId!)) {
                debugPrint('🔄 Closing existing connection for device: $deviceId');
                _closeConnection(deviceId!);
              }
              
              // Store the new connection and subscription
              _connections[deviceId!] = channel;
              _connectionSubscriptions[deviceId!] = subscription!;
              debugPrint('💾 Stored incoming connection for device: $deviceId');
              
              // Update device status
              if (_discoveredDevices.containsKey(deviceId)) {
                _discoveredDevices[deviceId]!.status = ConnectionStatus.connected;
                _lastHeartbeat[deviceId!] = DateTime.now();
                notifyListeners();
              }
            }
            
            // Send handshake response
            final response = {
              'type': 'handshake_ack',
              'userId': _currentUser!.id,
              'userName': _currentUser!.name,
              'deviceId': _currentUser!.deviceId,
              'timestamp': DateTime.now().toIso8601String(),
            };
            channel.sink.add(json.encode(response));
            debugPrint('✅ Sent handshake acknowledgment');
          } else if (deviceId != null) {
            _handleWebSocketMessage(deviceId!, message);
          } else {
            debugPrint('⚠️ Received message without device ID');
            _handleWebSocketMessage('unknown', message);
          }
        } catch (e) {
          debugPrint('❌ Error handling WebSocket message: $e');
        }
      },
      onError: (error) {
        debugPrint('WebSocket error: $error');
        if (deviceId != null) {
          _handleConnectionError(deviceId!, error);
          _connections.remove(deviceId!);
          _connectionSubscriptions.remove(deviceId!);
        }
      },
      onDone: () {
        if (deviceId != null) {
          _handleConnectionClosed(deviceId!);
          _connections.remove(deviceId!);
          _connectionSubscriptions.remove(deviceId!);
        }
      },
    );
  }

  void _handleWebSocketMessage(String deviceId, dynamic message) async {
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
          // Handle incoming message directly
          debugPrint('📨 Received message from $deviceId');
          debugPrint('📋 Message data: $data');
          try {
            if (data['message'] != null) {
              final messageData = data['message'] as Map<String, dynamic>;
              debugPrint('💬 Processing message: ${messageData['content']}');
              debugPrint('👤 From: ${messageData['senderName']} (${messageData['senderId']}');
              debugPrint('📬 To: ${messageData['receiverId']}');
              
              // Forward to ChatService directly
              final chatService = ChatService();
              final senderIp = _discoveredDevices[deviceId]?.ipAddress ?? '127.0.0.1';
              chatService.handleIncomingWebSocketMessage(data, senderIp);
              debugPrint('✅ Message forwarded to ChatService');
              
              notifyListeners();
            } else {
              debugPrint('⚠️ Message data is null');
            }
          } catch (e) {
            debugPrint('❌ Error handling incoming message: $e');
            debugPrint('📋 Error details: ${e.toString()}');
          }
          break;
        
        case 'chat_request':
          // Handle incoming chat request
          debugPrint('Received chat request from $deviceId');
          try {
            final chatRequestService = ChatRequestService();
            await chatRequestService.handleIncomingRequest(data);
          } catch (e) {
            debugPrint('Error handling chat request: $e');
          }
          break;
        
        case 'chat_request_response':
          // Handle chat request response (accept/reject)
          debugPrint('📨 Received chat request response from $deviceId');
          try {
            final chatRequestService = ChatRequestService();
            await chatRequestService.handleRequestResponse(data);

            debugPrint('✅ Chat request response processed: ${data['status']} for ${data['requestId']}');
            debugPrint('📋 Response data: $data');

            // Update device status to connected if request was accepted
            if (data['status'] == 'accepted' && _discoveredDevices.containsKey(deviceId)) {
              _discoveredDevices[deviceId]!.status = ConnectionStatus.connected;
              debugPrint('🔗 Updated device status to CONNECTED: $deviceId');
              notifyListeners();
            }
          } catch (e) {
            debugPrint('❌ Error handling chat request response: $e');
            debugPrint('📋 Error details: ${e.toString()}');
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
      debugPrint('🔄 Forwarding message to ChatService at 127.0.0.1:$defaultPort');
      final socket = await Socket.connect('127.0.0.1', defaultPort);
      final messageJson = json.encode(data);
      socket.write('$messageJson\n');
      await socket.flush();
      await socket.close();
      debugPrint('✅ Message forwarded successfully to ChatService');
    } catch (e) {
      debugPrint('❌ Failed to forward message to chat service: $e');
      debugPrint('📋 Error details: ${e.toString()}');
      
      // Try alternative: directly handle via ChatService instance
      try {
        debugPrint('🔄 Attempting direct ChatService handling...');
        final chatService = ChatService();
        if (data['message'] != null) {
          chatService.handleIncomingWebSocketMessage(data, senderIp);
          debugPrint('✅ Message handled directly by ChatService');
        }
      } catch (e2) {
        debugPrint('❌ Direct handling also failed: $e2');
      }
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

  Future<void> _tryDirectDiscovery() async {
    try {
      final localIp = await NetworkUtils.getLocalIP();
      if (localIp == null) {
        debugPrint('Could not get local IP address');
        return;
      }

      debugPrint('Attempting direct discovery on network $localIp');
      final network = NetworkUtils.getNetworkPrefix(localIp);
      final portsToTry = [defaultPort, 8080, 8888]; // Common WebSocket ports

      for (int i = 1; i <= 255; i++) {
        final testIp = '$network.$i';
        if (testIp == localIp) continue; // Skip self

        for (final port in portsToTry) {
          try {
            final socket = await Socket.connect(testIp, port, timeout: const Duration(milliseconds: 500));
            await socket.done;
            debugPrint('Found potential device at $testIp:$port');
            // If connection succeeds, try to handshake
            _handlePotentialDevice(testIp, port);
            await socket.close();
          } catch (e) {
            // Connection failed, try next port/ip
            continue;
          }
        }
      }
    } catch (e) {
      debugPrint('Error in direct discovery: $e');
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

  void _handlePotentialDevice(String ip, int port) {
    // If we can connect, create a device entry
    final device = Device(
      id: 'direct-$ip-$port',
      name: 'Direct Device',
      type: DeviceType.unknown,
      ipAddress: ip,
      port: port,
      status: ConnectionStatus.connected,
    );

    if (!_discoveredDevices.containsKey(device.id)) {
      _discoveredDevices[device.id] = device;
      notifyListeners();
    }
  }

  Future<void> sendMessage(String deviceId, Map<String, dynamic> message) async {
    debugPrint('📤 Attempting to send message to device: $deviceId');
    debugPrint('📋 Message type: ${message['type']}');
    
    // Try to find the device by both deviceId and userId
    Device? targetDevice = _discoveredDevices[deviceId];
    
    // If not found by deviceId, search by userId
    if (targetDevice == null) {
      for (var device in _discoveredDevices.values) {
        if (device.userId == deviceId || device.id == deviceId) {
          targetDevice = device;
          deviceId = device.id; // Use the actual device ID for connection
          debugPrint('🔍 Found device by userId: ${device.name} (${device.id})');
          break;
        }
      }
    }
    
    if (targetDevice == null) {
      debugPrint('❌ Device not found: $deviceId');
      debugPrint('📋 Available devices: ${_discoveredDevices.keys.toList()}');
      throw Exception('Device not found: $deviceId');
    }
    
    // Ensure connection exists
    if (!_connections.containsKey(deviceId)) {
      debugPrint('🔌 No connection found, attempting to connect to: ${targetDevice.name}');
      try {
        await connectToDevice(targetDevice);
        // Wait a bit for connection to stabilize
        await Future.delayed(const Duration(milliseconds: 500));
      } catch (e) {
        debugPrint('❌ Failed to establish connection: $e');
        throw Exception('Failed to connect to device: $deviceId');
      }
    }
    
    final connection = _connections[deviceId];
    if (connection == null) {
      debugPrint('❌ Connection is null for device: $deviceId');
      throw Exception('Connection is null for device: $deviceId');
    }
    
    try {
      final messageJson = json.encode(message);
      debugPrint('📨 Sending message: $messageJson');
      connection.sink.add(messageJson);
      debugPrint('✅ Message sent successfully to ${targetDevice.name} ($deviceId)');
    } catch (e) {
      debugPrint('❌ Failed to send message to $deviceId: $e');
      debugPrint('🔧 Connection state: ${connection.closeCode}');
      rethrow;
    }
  }

  Future<String?> _getBestIpAddress() async {
    try {
      // First try NetworkInfo for WiFi IP
      final wifiIp = await NetworkUtils.getLocalIP();
      if (wifiIp != null && !wifiIp.startsWith('192.0.')) {
        debugPrint('Using WiFi IP: $wifiIp');
        return wifiIp;
      }
      
      // Fallback to manual detection with better filtering
      final interfaces = await NetworkInterface.list();
      String? bestIp;
      String? fallbackIp;
      
      for (final interface in interfaces) {
        // Skip obviously virtual interfaces
        final name = interface.name.toLowerCase();
        if (name.contains('vethernet') || 
            name.contains('docker') || 
            name.contains('vmware') || 
            name.contains('virtualbox') ||
            name.contains('wsl') ||
            name.contains('loopback')) {
          continue;
        }
        
        for (final addr in interface.addresses) {
          if (addr.type == InternetAddressType.IPv4 && !addr.isLoopback) {
            final ip = addr.address;
            
            // Skip obviously wrong IPs
            if (ip.startsWith('127.') || ip.startsWith('169.254.')) {
              continue;
            }
            
            // Prefer common local network ranges
            if (ip.startsWith('192.168.') || 
                ip.startsWith('10.') || 
                (ip.startsWith('172.') && 
                 int.parse(ip.split('.')[1]) >= 16 && 
                 int.parse(ip.split('.')[1]) <= 31)) {
              // Check if it's on the same subnet as discovered devices
              if (_discoveredDevices.isNotEmpty) {
                for (var device in _discoveredDevices.values) {
                  if (await NetworkUtils.isSameNetwork(ip, device.ipAddress)) {
                    debugPrint('Found matching network IP: $ip (same as ${device.name})');
                    return ip;
                  }
                }
              }
              
              // Prefer WiFi/Ethernet interfaces
              if (name.contains('wi-fi') || 
                  name.contains('wifi') || 
                  name.contains('wlan') || 
                  name.contains('ethernet') ||
                  name.contains('eth')) {
                bestIp = ip;
              } else if (fallbackIp == null) {
                fallbackIp = ip;
              }
            }
          }
        }
      }
      
      final result = bestIp ?? fallbackIp ?? wifiIp;
      debugPrint('Selected IP address: $result');
      return result;
    } catch (e) {
      debugPrint('Error getting best IP address: $e');
      return null;
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
