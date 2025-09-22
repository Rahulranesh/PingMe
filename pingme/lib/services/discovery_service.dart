// import 'dart:async';
// import 'dart:convert';
// import 'dart:io';
// import 'package:flutter/foundation.dart';
// import 'package:network_info_plus/network_info_plus.dart';
// import 'package:permission_handler/permission_handler.dart';
// import '../models/device.dart';
// import '../models/user.dart';

// class DiscoveryService extends ChangeNotifier {
//   static const int discoveryPort = 8888;
//   static const int chatPort = 8889;
//   static const Duration scanInterval = Duration(seconds: 3);
//   static const Duration heartbeatInterval = Duration(seconds: 10);

//   final NetworkInfo _networkInfo = NetworkInfo();
//   ServerSocket? _discoveryServer;
//   RawDatagramSocket? _broadcastSocket;
//   Timer? _scanTimer;
//   Timer? _heartbeatTimer;

//   final Map<String, Device> _discoveredDevices = {};
//   final Map<String, DateTime> _lastHeartbeat = {};
  
//   User? _currentUser;
//   String? _localIpAddress;
//   bool _isScanning = false;
//   bool _isServerRunning = false;

//   Map<String, Device> get discoveredDevices => Map.unmodifiable(_discoveredDevices);
//   bool get isScanning => _isScanning;
//   bool get isServerRunning => _isServerRunning;
//   User? get currentUser => _currentUser;
//   String? get localIpAddress => _localIpAddress;

//   Future<void> initialize(User user) async {
//     _currentUser = user;
//     await _requestPermissions();
//     await _getLocalIpAddress();
//     await startDiscoveryServer();
//     startHeartbeat();
//   }

//   Future<void> _requestPermissions() async {
//     await Permission.locationWhenInUse.request();
//   }

//   Future<void> _getLocalIpAddress() async {
//     try {
//       final wifiIP = await _networkInfo.getWifiIP();
//       _localIpAddress = wifiIP ?? '192.168.1.1';
//       if (_currentUser != null) {
//         _currentUser!.ipAddress = _localIpAddress!;
//       }
//     } catch (e) {
//       debugPrint('Error getting IP address: $e');
//       _localIpAddress = '192.168.1.1';
//     }
//   }

//   Future<void> startDiscoveryServer() async {
//     if (_isServerRunning) return;

//     try {
//       _discoveryServer = await ServerSocket.bind(
//         InternetAddress.anyIPv4,
//         discoveryPort,
//       );
//       _isServerRunning = true;
//       notifyListeners();

//       _discoveryServer!.listen((Socket socket) {
//         _handleIncomingConnection(socket);
//       });

//       debugPrint('Discovery server started on port $discoveryPort');
//     } catch (e) {
//       debugPrint('Error starting discovery server: $e');
//       _isServerRunning = false;
//     }
//   }

//   void _handleIncomingConnection(Socket socket) {
//     final buffer = StringBuffer();
    
//     socket.listen(
//       (data) {
//         buffer.write(String.fromCharCodes(data));
//         final content = buffer.toString();
        
//         if (content.contains('\n')) {
//           final messages = content.split('\n');
//           for (final message in messages) {
//             if (message.isNotEmpty) {
//               _processDiscoveryMessage(message, socket.remoteAddress.address);
//             }
//           }
//           buffer.clear();
//         }
//       },
//       onError: (error) {
//         debugPrint('Socket error: $error');
//       },
//       onDone: () {
//         socket.close();
//       },
//     );
//   }

//   void _processDiscoveryMessage(String message, String senderIp) {
//     try {
//       final data = json.decode(message);
//       final type = data['type'] as String?;

//       switch (type) {
//         case 'announce':
//           _handleDeviceAnnouncement(data, senderIp);
//           break;
//         case 'response':
//           _handleDiscoveryResponse(data, senderIp);
//           break;
//         case 'heartbeat':
//           _handleHeartbeat(data, senderIp);
//           break;
//         case 'disconnect':
//           _handleDisconnect(data);
//           break;
//       }
//     } catch (e) {
//       debugPrint('Error processing discovery message: $e');
//     }
//   }

//   void _handleDeviceAnnouncement(Map<String, dynamic> data, String senderIp) {
//     final device = Device(
//       id: data['deviceId'] as String,
//       name: data['deviceName'] as String? ?? 'Unknown Device',
//       type: DeviceType.values.firstWhere(
//         (e) => e.name == data['deviceType'],
//         orElse: () => DeviceType.unknown,
//       ),
//       ipAddress: senderIp,
//       port: data['port'] as int? ?? chatPort,
//       platform: data['platform'] as String?,
//       model: data['model'] as String?,
//       osVersion: data['osVersion'] as String?,
//       status: ConnectionStatus.connected,
//       userId: data['userId'] as String?,
//     );

//     _discoveredDevices[device.id] = device;
//     _lastHeartbeat[device.id] = DateTime.now();
//     notifyListeners();

//     // Send response
//     _sendDiscoveryResponse(senderIp, data['port'] as int? ?? discoveryPort);
//   }

//   void _handleDiscoveryResponse(Map<String, dynamic> data, String senderIp) {
//     final device = Device(
//       id: data['deviceId'] as String,
//       name: data['deviceName'] as String? ?? 'Unknown Device',
//       type: DeviceType.values.firstWhere(
//         (e) => e.name == data['deviceType'],
//         orElse: () => DeviceType.unknown,
//       ),
//       ipAddress: senderIp,
//       port: data['port'] as int? ?? chatPort,
//       platform: data['platform'] as String?,
//       model: data['model'] as String?,
//       osVersion: data['osVersion'] as String?,
//       status: ConnectionStatus.connected,
//       userId: data['userId'] as String?,
//     );

//     _discoveredDevices[device.id] = device;
//     _lastHeartbeat[device.id] = DateTime.now();
//     notifyListeners();
//   }

//   void _handleHeartbeat(Map<String, dynamic> data, String senderIp) {
//     final deviceId = data['deviceId'] as String?;
//     if (deviceId != null && _discoveredDevices.containsKey(deviceId)) {
//       _lastHeartbeat[deviceId] = DateTime.now();
//       _discoveredDevices[deviceId]!.status = ConnectionStatus.connected;
//       notifyListeners();
//     }
//   }

//   void _handleDisconnect(Map<String, dynamic> data) {
//     final deviceId = data['deviceId'] as String?;
//     if (deviceId != null && _discoveredDevices.containsKey(deviceId)) {
//       _discoveredDevices[deviceId]!.status = ConnectionStatus.disconnected;
//       _lastHeartbeat.remove(deviceId);
//       notifyListeners();
//     }
//   }

//   Future<void> startScanning() async {
//     if (_isScanning) return;

//     _isScanning = true;
//     notifyListeners();

//     _scanTimer = Timer.periodic(scanInterval, (timer) {
//       _broadcastDiscoveryMessage();
//       _checkDeviceTimeouts();
//     });

//     // Initial broadcast
//     _broadcastDiscoveryMessage();
//   }

//   Future<void> stopScanning() async {
//     _isScanning = false;
//     _scanTimer?.cancel();
//     _scanTimer = null;
//     notifyListeners();
//   }

//   void startHeartbeat() {
//     _heartbeatTimer?.cancel();
//     _heartbeatTimer = Timer.periodic(heartbeatInterval, (timer) {
//       _sendHeartbeat();
//     });
//   }

//   void stopHeartbeat() {
//     _heartbeatTimer?.cancel();
//     _heartbeatTimer = null;
//   }

//   Future<void> _broadcastDiscoveryMessage() async {
//     if (_localIpAddress == null || _currentUser == null) return;

//     try {
//       _broadcastSocket ??= await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
//       _broadcastSocket!.broadcastEnabled = true;

//       final message = json.encode({
//         'type': 'announce',
//         'deviceId': _currentUser!.deviceId,
//         'deviceName': _currentUser!.name,
//         'deviceType': _getDeviceType().name,
//         'userId': _currentUser!.id,
//         'port': chatPort,
//         'platform': Platform.operatingSystem,
//         'timestamp': DateTime.now().toIso8601String(),
//       });

//       final subnet = _localIpAddress!.substring(0, _localIpAddress!.lastIndexOf('.'));
//       final broadcastAddress = '$subnet.255';

//       _broadcastSocket!.send(
//         utf8.encode(message),
//         InternetAddress(broadcastAddress),
//         discoveryPort,
//       );
//     } catch (e) {
//       debugPrint('Error broadcasting discovery message: $e');
//     }
//   }

//   void _sendHeartbeat() {
//     for (final device in _discoveredDevices.values) {
//       if (device.status == ConnectionStatus.connected) {
//         _sendMessageToDevice(device, {
//           'type': 'heartbeat',
//           'deviceId': _currentUser?.deviceId,
//           'timestamp': DateTime.now().toIso8601String(),
//         });
//       }
//     }
//   }

//   void _sendDiscoveryResponse(String targetIp, int targetPort) {
//     if (_currentUser == null) return;

//     final message = json.encode({
//       'type': 'response',
//       'deviceId': _currentUser!.deviceId,
//       'deviceName': _currentUser!.name,
//       'deviceType': _getDeviceType().name,
//       'userId': _currentUser!.id,
//       'port': chatPort,
//       'platform': Platform.operatingSystem,
//       'timestamp': DateTime.now().toIso8601String(),
//     });

//     _sendMessage(targetIp, targetPort, message);
//   }

//   void _sendMessageToDevice(Device device, Map<String, dynamic> data) {
//     final message = json.encode(data);
//     _sendMessage(device.ipAddress, device.port, message);
//   }

//   void _sendMessage(String targetIp, int targetPort, String message) {
//     Socket.connect(targetIp, targetPort).then((socket) {
//       socket.write('$message\n');
//       socket.close();
//     }).catchError((error) {
//       debugPrint('Error sending message to $targetIp:$targetPort - $error');
//     });
//   }

//   void _checkDeviceTimeouts() {
//     final now = DateTime.now();
//     final timeout = const Duration(seconds: 30);

//     _lastHeartbeat.forEach((deviceId, lastSeen) {
//       if (now.difference(lastSeen) > timeout) {
//         if (_discoveredDevices.containsKey(deviceId)) {
//           _discoveredDevices[deviceId]!.status = ConnectionStatus.disconnected;
//           _lastHeartbeat.remove(deviceId);
//         }
//       }
//     });

//     notifyListeners();
//   }

//   DeviceType _getDeviceType() {
//     if (Platform.isAndroid || Platform.isIOS) {
//       return DeviceType.mobile;
//     } else if (Platform.isMacOS || Platform.isWindows || Platform.isLinux) {
//       return DeviceType.desktop;
//     }
//     return DeviceType.unknown;
//   }

//   void removeDevice(String deviceId) {
//     _discoveredDevices.remove(deviceId);
//     _lastHeartbeat.remove(deviceId);
//     notifyListeners();
//   }

//   void clearDevices() {
//     _discoveredDevices.clear();
//     _lastHeartbeat.clear();
//     notifyListeners();
//   }

//   @override
//   void dispose() {
//     stopScanning();
//     stopHeartbeat();
//     _discoveryServer?.close();
//     _broadcastSocket?.close();
//     super.dispose();
//   }
// }
