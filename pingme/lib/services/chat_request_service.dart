import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/chat_request.dart';
import '../models/device.dart';
import '../models/user.dart';
import 'mdns_discovery_service.dart';

class ChatRequestService extends ChangeNotifier {
  static final ChatRequestService _instance = ChatRequestService._internal();
  factory ChatRequestService() => _instance;
  ChatRequestService._internal();

  Box<Map>? _requestsBox;
  final Map<String, ChatRequest> _pendingRequests = {};
  final Map<String, ChatRequest> _sentRequests = {};
  final StreamController<ChatRequest> _requestStream = StreamController.broadcast();
  
  User? _currentUser;

  Stream<ChatRequest> get requestStream => _requestStream.stream;
  Map<String, ChatRequest> get pendingRequests => Map.unmodifiable(_pendingRequests);
  Map<String, ChatRequest> get sentRequests => Map.unmodifiable(_sentRequests);

  Future<void> initialize(User user) async {
    _currentUser = user;
    
    try {
      _requestsBox = await Hive.openBox<Map>('chat_requests_${user.id}');
      await _loadRequests();
      _cleanupExpiredRequests();
      debugPrint('Chat Request Service initialized successfully');
    } catch (e) {
      debugPrint('Chat Request Service initialization failed: $e');
    }
  }

  Future<void> _loadRequests() async {
    if (_requestsBox == null) return;

    _pendingRequests.clear();
    _sentRequests.clear();

    for (final key in _requestsBox!.keys) {
      try {
        final data = _requestsBox!.get(key);
        if (data != null) {
          final request = ChatRequest.fromJson(Map<String, dynamic>.from(data));
          
          if (request.toUserId == _currentUser?.id) {
            _pendingRequests[request.id] = request;
          } else if (request.fromUserId == _currentUser?.id) {
            _sentRequests[request.id] = request;
          }
        }
      } catch (e) {
        debugPrint('Error loading chat request $key: $e');
      }
    }
    
    notifyListeners();
  }

  void _cleanupExpiredRequests() {
    final expiredIds = <String>[];

    for (final request in _pendingRequests.values) {
      if (request.isExpired) {
        expiredIds.add(request.id);
      }
    }

    for (final request in _sentRequests.values) {
      if (request.isExpired) {
        expiredIds.add(request.id);
      }
    }

    for (final id in expiredIds) {
      _removeRequest(id);
    }
  }

  Future<bool> sendChatRequest({
    required Device targetDevice,
    required MDNSDiscoveryService mdnsService,
    String message = '',
  }) async {
    if (_currentUser == null) {
      debugPrint('Cannot send chat request: User not authenticated');
      throw Exception('User not authenticated');
    }

    final request = ChatRequest(
      fromUserId: _currentUser!.id,
      fromUserName: _currentUser!.name,
      fromDeviceId: _currentUser!.deviceId,
      toUserId: targetDevice.userId ?? '',
      toDeviceId: targetDevice.id,
      message: message.isEmpty ? 'Hi! Would you like to chat?' : message,
    );

    try {
      debugPrint('Attempting to send chat request to device: ${targetDevice.id}');
      debugPrint('Target device name: ${targetDevice.name}');
      debugPrint('Target device IP: ${targetDevice.ipAddress}');
      
      // Send request via mDNS
      final requestPayload = {
        'type': 'chat_request',
        'request': request.toJson(),
      };

      await mdnsService.sendMessage(targetDevice.id, requestPayload);
      
      // Store sent request
      _sentRequests[request.id] = request;
      await _saveRequest(request);
      
      notifyListeners();
      debugPrint('Chat request sent successfully to ${targetDevice.name}');
      return true;
    } catch (e) {
      debugPrint('Failed to send chat request: $e');
      debugPrint('Error type: ${e.runtimeType}');
      return false;
    }
  }

  Future<void> handleIncomingRequest(Map<String, dynamic> data) async {
    try {
      final request = ChatRequest.fromJson(data['request']);
      
      // Check if request is for current user
      if (request.toUserId != _currentUser?.id) {
        return;
      }

      // Check if request already exists
      if (_pendingRequests.containsKey(request.id)) {
        return;
      }

      // Add to pending requests
      _pendingRequests[request.id] = request;
      await _saveRequest(request);
      
      // Notify UI
      _requestStream.add(request);
      notifyListeners();

      debugPrint('Received chat request from ${request.fromUserName}');
    } catch (e) {
      debugPrint('Error handling incoming chat request: $e');
    }
  }

  Future<bool> acceptRequest(String requestId, MDNSDiscoveryService mdnsService) async {
    final request = _pendingRequests[requestId];
    if (request == null) {
      debugPrint('Cannot accept request: Request not found for ID $requestId');
      return false;
    }

    try {
      debugPrint('🔄 ACCEPTING CHAT REQUEST: ${request.fromUserName} (${request.fromDeviceId})');

      // Update request status locally first
      final updatedRequest = request.copyWith(status: ChatRequestStatus.accepted);
      _pendingRequests[requestId] = updatedRequest;
      await _saveRequest(updatedRequest);
      notifyListeners();

      debugPrint('✅ Request status updated locally to ACCEPTED');

      // Find the requesting device
      final devices = mdnsService.discoveredDevices;
      Device? senderDevice;

      for (final device in devices.values) {
        if (device.id == request.fromDeviceId ||
            device.userId == request.fromUserId ||
            device.name == request.fromUserName) {
          senderDevice = device;
          debugPrint('📱 Found sender device: ${device.name} (${device.id}) at ${device.ipAddress}:${device.port}');
          break;
        }
      }

      // If device not found, try to create a connection
      if (senderDevice == null) {
        debugPrint('⚠️ Sender device not found, attempting direct connection...');
        senderDevice = Device(
          id: request.fromDeviceId,
          name: request.fromUserName,
          ipAddress: '192.168.1.100', // Will be resolved
          port: 8889,
          userId: request.fromUserId,
          type: DeviceType.mobile,
          status: ConnectionStatus.disconnected,
        );
        // Use the public method to add the device
        mdnsService.addOrUpdateDevice(senderDevice);
      }

      // Ensure connection is established
      bool connectionEstablished = senderDevice.status == ConnectionStatus.connected;
      if (!connectionEstablished) {
        debugPrint('🔌 Establishing connection to sender device...');
        try {
          await mdnsService.connectToDevice(senderDevice);

          // Wait for connection with timeout
          int attempts = 0;
          const maxAttempts = 10;

          while (senderDevice.status != ConnectionStatus.connected && attempts < maxAttempts) {
            await Future.delayed(const Duration(milliseconds: 500));
            attempts++;
            debugPrint('⏳ Connection attempt $attempts/$maxAttempts, status: ${senderDevice.status}');
          }

          connectionEstablished = senderDevice.status == ConnectionStatus.connected;
          debugPrint('🔌 Connection established: $connectionEstablished');
        } catch (e) {
          debugPrint('❌ Connection error: $e');
          connectionEstablished = false;
        }
      }

      // Send acceptance response with multiple retry attempts
      bool responseSent = false;
      int sendAttempts = 0;
      const maxSendAttempts = 5;

      // The senderDevice should already be found and connected from above
      // If not connected, make one more attempt
      if (senderDevice != null && senderDevice.status != ConnectionStatus.connected) {
        debugPrint('🔄 Re-attempting connection to sender device before sending response...');
        try {
          await mdnsService.connectToDevice(senderDevice);
          await Future.delayed(const Duration(milliseconds: 500)); // Wait for connection to stabilize
          debugPrint('✅ Connected to sender device for response');
        } catch (e) {
          debugPrint('❌ Failed to re-connect to sender device: $e');
        }
      }

      while (!responseSent && sendAttempts < maxSendAttempts) {
        try {
          sendAttempts++;
          debugPrint('📤 Sending acceptance response (attempt $sendAttempts/$maxSendAttempts)');

          final responsePayload = {
            'type': 'chat_request_response',
            'requestId': requestId,
            'status': 'accepted',
            'fromUserId': _currentUser?.id,
            'fromUserName': _currentUser?.name,
            'timestamp': DateTime.now().toIso8601String(),
            'acceptedAt': DateTime.now().toIso8601String(),
          };

          await mdnsService.sendMessage(request.fromDeviceId, responsePayload);
          responseSent = true;

          debugPrint('✅ Acceptance response sent successfully to ${request.fromDeviceId}');
          debugPrint('📋 Response payload: $responsePayload');

        } catch (sendError) {
          debugPrint('❌ Failed to send acceptance response (attempt $sendAttempts): $sendError');

          if (sendAttempts < maxSendAttempts) {
            debugPrint('⏳ Retrying in ${sendAttempts * 2} seconds...');
            await Future.delayed(Duration(seconds: sendAttempts * 2));
          }
        }
      }

      if (responseSent) {
        debugPrint('🎉 Chat request acceptance completed successfully!');
        debugPrint('📱 Both devices should now be able to chat');
      } else {
        debugPrint('🚨 CRITICAL: Failed to send acceptance response after $maxSendAttempts attempts');
        debugPrint('⚠️ The requesting device will not know the request was accepted');
        debugPrint('🔧 This may cause the chat to appear "offline" on the requesting device');
      }

      // Remove from pending requests since it's accepted
      _removeRequest(requestId);

      notifyListeners();
      debugPrint('✅ Chat request accepted: $requestId (response sent: $responseSent)');
      return true;

    } catch (e) {
      debugPrint('💥 Failed to accept chat request: $e');
      debugPrint('🔍 Error type: ${e.runtimeType}');
      debugPrint('📋 Stack trace: ${StackTrace.current}');
      return false;
    }
  }

  Future<bool> rejectRequest(String requestId, MDNSDiscoveryService mdnsService) async {
    final request = _pendingRequests[requestId];
    if (request == null) {
      debugPrint('Cannot reject request: Request not found for ID $requestId');
      return false;
    }

    try {
      debugPrint('Rejecting chat request from ${request.fromUserName} (${request.fromDeviceId})');
      
      // First, ensure we're connected to the requesting device
      final devices = mdnsService.discoveredDevices;
      final senderDevice = devices.values.firstWhere(
        (device) => device.id == request.fromDeviceId,
        orElse: () => Device(
          id: request.fromDeviceId,
          name: request.fromUserName,
          ipAddress: '', // Will need to be resolved
          port: 8889,
          userId: request.fromUserId,
          type: DeviceType.mobile,
        ),
      );
      
      // Connect to the device if not already connected
      if (senderDevice.status != ConnectionStatus.connected) {
        debugPrint('Connecting to sender device before rejecting request...');
        await mdnsService.connectToDevice(senderDevice);
        
        // Wait for connection to establish
        int attempts = 0;
        while (senderDevice.status != ConnectionStatus.connected && attempts < 10) {
          await Future.delayed(const Duration(milliseconds: 200));
          attempts++;
          debugPrint('Connection attempt $attempts for rejection, status: ${senderDevice.status}');
        }
        
        if (senderDevice.status != ConnectionStatus.connected) {
          debugPrint('Failed to connect to sender device for rejection');
          return false;
        }
      }
      
      // Update request status
      final updatedRequest = request.copyWith(status: ChatRequestStatus.rejected);
      _pendingRequests[requestId] = updatedRequest;
      await _saveRequest(updatedRequest);

      // Send rejection response
      final responsePayload = {
        'type': 'chat_request_response',
        'requestId': requestId,
        'status': 'rejected',
        'fromUserId': _currentUser?.id,
        'fromUserName': _currentUser?.name,
      };

      debugPrint('Sending rejection response to ${request.fromDeviceId}');
      await mdnsService.sendMessage(request.fromDeviceId, responsePayload);
      
      // Remove from pending requests
      _removeRequest(requestId);
      
      notifyListeners();
      debugPrint('Chat request rejected successfully: $requestId');
      return true;
    } catch (e) {
      debugPrint('Failed to reject chat request: $e');
      debugPrint('Error type: ${e.runtimeType}');
      return false;
    }
  }

  Future<void> handleRequestResponse(Map<String, dynamic> data) async {
    final requestId = data['requestId'];
    final status = data['status'];

    final request = _sentRequests[requestId];
    if (request == null) return;

    try {
      final newStatus = status == 'accepted'
          ? ChatRequestStatus.accepted
          : ChatRequestStatus.rejected;

      final updatedRequest = request.copyWith(status: newStatus);
      _sentRequests[requestId] = updatedRequest;
      await _saveRequest(updatedRequest);

      // Emit the updated request to the stream so UI can react
      _requestStream.add(updatedRequest);

      notifyListeners();

      debugPrint('Chat request response received: $status for $requestId');
    } catch (e) {
      debugPrint('Error handling request response: $e');
    }
  }

  Future<void> _saveRequest(ChatRequest request) async {
    if (_requestsBox == null) return;
    
    try {
      await _requestsBox!.put(request.id, request.toJson());
    } catch (e) {
      debugPrint('Error saving chat request: $e');
    }
  }

  Future<void> _removeRequest(String requestId) async {
    _pendingRequests.remove(requestId);
    _sentRequests.remove(requestId);
    
    if (_requestsBox != null) {
      await _requestsBox!.delete(requestId);
    }
    
    notifyListeners();
  }

  Future<bool> acceptRequestSimple(String requestId) async {
    final request = _pendingRequests[requestId];
    if (request == null) {
      debugPrint('Cannot accept request: Request not found for ID $requestId');
      return false;
    }

    try {
      debugPrint('Accepting chat request locally: ${request.fromUserName} (${request.fromDeviceId})');
      
      // Update request status locally
      final updatedRequest = request.copyWith(status: ChatRequestStatus.accepted);
      _pendingRequests[requestId] = updatedRequest;
      await _saveRequest(updatedRequest);
      
      // Remove from pending requests since it's accepted
      _removeRequest(requestId);
      
      notifyListeners();
      debugPrint('Chat request accepted locally: $requestId');
      return true;
    } catch (e) {
      debugPrint('Failed to accept chat request locally: $e');
      return false;
    }
  }

  @override
  void dispose() {
    _requestStream.close();
    _requestsBox?.close();
    super.dispose();
  }
}
