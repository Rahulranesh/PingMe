import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/message.dart';
import '../models/device.dart';
import '../models/user.dart';
import 'mdns_discovery_service.dart';
import 'auth_service.dart';
import 'notification_service.dart';
import 'profile_service.dart';

class ChatService extends ChangeNotifier {
  static final ChatService _instance = ChatService._internal();
  factory ChatService() => _instance;
  ChatService._internal();
  static const int chatPort = 8889;
  static const int maxRetries = 3;
  static const Duration messageTimeout = Duration(seconds: 10);

  ServerSocket? _chatServer;
  final Map<String, Socket> _activeConnections = {};
  final Map<String, List<Message>> _conversations = {};
  final Map<String, StreamController<Message>> _messageStreams = {};
  
  Box<Map>? _messagesBox;
  Box<Map>? _conversationsBox;
  User? _currentUser;
  bool _isServerRunning = false;
  final AuthService _authService = AuthService();
  final NotificationService _notificationService = NotificationService();

  Map<String, List<Message>> get conversations => Map.unmodifiable(_conversations);
  bool get isServerRunning => _isServerRunning;
  User? get currentUser => _currentUser;

  Future<void> initialize(User? user) async {
    // Use provided user or get from ProfileService
    _currentUser = user ?? ProfileService().currentUser;
    
    if (_currentUser == null) {
      debugPrint('⚠️ ChatService: No user available for initialization');
    } else {
      debugPrint('✅ ChatService: Initializing with user ${_currentUser!.name} (${_currentUser!.id})');
    }

    try {
      await _initializeStorage().timeout(const Duration(seconds: 5));
      await _loadConversations().timeout(const Duration(seconds: 6));
      await startChatServer().timeout(const Duration(seconds: 3));
      debugPrint('Chat Service initialized successfully');
    } catch (e) {
      debugPrint('Chat Service initialization failed: $e');
      // Continue with partial initialization - core functionality might still work
      rethrow;
    }
  }

  Future<void> _initializeStorage() async {
    try {
      // Open boxes with timeout
      _messagesBox = await Hive.openBox<Map>('messages').timeout(const Duration(seconds: 5));
      _conversationsBox = await Hive.openBox<Map>('conversations').timeout(const Duration(seconds: 5));
    } catch (e) {
      debugPrint('Storage initialization timeout: $e');
      // Continue with null boxes - app can still function
    }
  }

  Future<void> _loadConversations() async {
    if (_messagesBox == null || _currentUser == null) return;
    
    try {
      // Load messages in batches to avoid blocking
      final keys = _messagesBox!.keys.toList();
      const batchSize = 50;
      
      for (int i = 0; i < keys.length; i += batchSize) {
        final batch = keys.skip(i).take(batchSize).toList();
        
        for (var key in batch) {
          final messageData = _messagesBox!.get(key);
          if (messageData != null) {
            final message = Message.fromJson(Map<String, dynamic>.from(messageData));
            final chatId = message.chatId;
            
            _conversations.putIfAbsent(chatId, () => []);
            _conversations[chatId]!.add(message);
          }
        }
        
        // Yield control to UI thread
        await Future.delayed(Duration.zero);
      }
      
      // Sort messages by timestamp
      for (var chatId in _conversations.keys) {
        _conversations[chatId]!.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      }
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading conversations: $e');
    }
  }

  String _generateChatId(String userId1, String userId2) {
    // Generate consistent chat ID regardless of who initiates
    final ids = [userId1, userId2];
    ids.sort();
    return '${ids[0]}_${ids[1]}';
  }

  Future<void> _saveMessage(Message message) async {
    if (_messagesBox == null) return;
    
    try {
      await _messagesBox!.put(message.id, message.toJson());
    } catch (e) {
      debugPrint('Error saving message: $e');
    }
  }

  Future<void> _updateMessageStatus(String messageId, MessageStatus status) async {
    try {
      // Update in memory
      for (var conversation in _conversations.values) {
        for (var message in conversation) {
          if (message.id == messageId) {
            message.status = status;
            if (status == MessageStatus.read) {
              message.readAt = DateTime.now();
            }
            // Update in storage
            await _saveMessage(message);
            notifyListeners();
            return;
          }
        }
      }
    } catch (e) {
      debugPrint('Error updating message status: $e');
    }
  }

  Future<void> startChatServer() async {
    if (_isServerRunning) return;

    try {
      _chatServer = await ServerSocket.bind(
        InternetAddress.anyIPv4,
        chatPort,
      ).timeout(const Duration(seconds: 5));
      _isServerRunning = true;
      notifyListeners();

      _chatServer!.listen((Socket socket) {
        _handleIncomingConnection(socket);
      });

      debugPrint('Chat server started on port $chatPort');
    } catch (e) {
      debugPrint('Error starting chat server: $e');
      _isServerRunning = false;
    }
  }

  void _handleIncomingConnection(Socket socket) {
    final remoteAddress = socket.remoteAddress.address;
    final buffer = StringBuffer();

    socket.listen(
      (data) {
        buffer.write(String.fromCharCodes(data));
        final content = buffer.toString();

        if (content.contains('\n')) {
          final messages = content.split('\n');
          for (final message in messages) {
            if (message.isNotEmpty) {
              _processIncomingMessage(message, remoteAddress, socket);
            }
          }
          buffer.clear();
        }
      },
      onError: (error) {
        debugPrint('Socket error from $remoteAddress: $error');
        _activeConnections.remove(remoteAddress);
      },
      onDone: () {
        debugPrint('Connection closed from $remoteAddress');
        _activeConnections.remove(remoteAddress);
        socket.close();
      },
    );

    // Store active connection
    _activeConnections[remoteAddress] = socket;
  }

  void _processIncomingMessage(String data, String senderIp, Socket socket) {
    try {
      final json = jsonDecode(data);
      final type = json['type'] as String?;

      switch (type) {
        case 'message':
          _handleTextMessage(json, senderIp);
          break;
        case 'typing':
          _handleTypingIndicator(json, senderIp);
          break;
        case 'receipt':
          _handleMessageReceipt(json);
          break;
        case 'file':
          _handleFileTransfer(json, senderIp);
          break;
        case 'connection':
          _handleConnectionRequest(json, senderIp, socket);
          break;
      }
    } catch (e) {
      debugPrint('Error processing message: $e');
    }
  }

  // Public method to handle incoming WebSocket messages from MDNSDiscoveryService
  void handleIncomingWebSocketMessage(Map<String, dynamic> data, String senderIp) {
    debugPrint('📨 ChatService handling incoming WebSocket message');
    debugPrint('📋 Data: $data');
    debugPrint('📍 From IP: $senderIp');
    
    try {
      final type = data['type'] as String?;
      
      if (type == 'message' && data['message'] != null) {
        _handleTextMessage(data, senderIp);
      } else if (type == 'typing') {
        _handleTypingIndicator(data, senderIp);
      } else if (type == 'receipt') {
        _handleMessageReceipt(data);
      }
    } catch (e) {
      debugPrint('❌ Error in handleIncomingWebSocketMessage: $e');
    }
  }

  void _handleTextMessage(Map<String, dynamic> data, String senderIp) async {
    // Get current user from ProfileService if not already set
    if (_currentUser == null) {
      _currentUser = ProfileService().currentUser;
    }
    
    // Check authentication
    if (!_authService.isAuthenticated || _currentUser == null) {
      debugPrint('Unauthenticated user cannot receive messages');
      return;
    }
    
    var message = Message.fromJson(data['message'] as Map<String, dynamic>);
    
    debugPrint('📨 Handling text message from ${message.senderName} (${message.senderId})');
    debugPrint('📋 Message content: ${message.content}');
    debugPrint('👤 Receiver ID: ${message.receiverId}');
    debugPrint('🆔 Current User ID: ${_currentUser!.id}');
    
    // Only process messages meant for this user
    if (message.receiverId != _currentUser!.id && message.receiverId != _currentUser!.deviceId) {
      debugPrint('⚠️ Message not for this user, ignoring');
      return;
    }
    
    // Generate proper chat ID and create new message with updated fields
    final chatId = _generateChatId(message.senderId, _currentUser!.id);
    message = message.copyWith(
      chatId: chatId,
      status: MessageStatus.delivered,
    );
    
    // Check if message already exists to avoid duplicates
    bool messageExists = false;
    if (_conversations.containsKey(chatId)) {
      messageExists = _conversations[chatId]!.any((m) => m.id == message.id);
    }
    
    if (!messageExists) {
      // Store message in conversation and persist
      _conversations.putIfAbsent(chatId, () => []);
      _conversations[chatId]!.add(message);
      await _saveMessage(message);
      
      // Notify stream listeners
      if (_messageStreams.containsKey(chatId)) {
        _messageStreams[chatId]!.add(message);
      }
      
      debugPrint('✅ Message stored in chat: $chatId');
    } else {
      debugPrint('⚠️ Message already exists, skipping');
    }
    
    // Send delivery receipt
    _sendReceipt(message.id, message.senderId, MessageStatus.delivered, senderIp);
    
    // Show notification if message is from another user
    if (message.senderId != _currentUser!.id) {
      final sender = User(
        id: message.senderId,
        name: message.senderName,
        deviceId: '',
        ipAddress: senderIp,
        port: chatPort,
      );
      await _notificationService.showMessageNotification(
        message: message,
        sender: sender,
        conversationId: chatId,
      );
    }
    
    notifyListeners();
  }

  void _handleTypingIndicator(Map<String, dynamic> data, String senderIp) {
    final userId = data['userId'] as String;
    final chatId = data['chatId'] as String;
    final isTyping = data['isTyping'] as bool;
    
    // Create typing indicator message
    final typingMessage = Message(
      chatId: chatId,
      senderId: userId,
      senderName: data['userName'] as String? ?? 'User',
      content: '',
      type: MessageType.typing,
      metadata: {'isTyping': isTyping},
    );
    
    // Notify stream listeners
    if (_messageStreams.containsKey(chatId)) {
      _messageStreams[chatId]!.add(typingMessage);
    }
  }

  void _handleMessageReceipt(Map<String, dynamic> data) async {
    final messageId = data['messageId'] as String;
    final status = MessageStatus.values.firstWhere(
      (e) => e.name == data['status'],
      orElse: () => MessageStatus.sent,
    );
    
    await _updateMessageStatus(messageId, status);
  }

  void _handleFileTransfer(Map<String, dynamic> data, String senderIp) {
    // Handle file transfer metadata
    final fileInfo = data['fileInfo'] as Map<String, dynamic>;
    final fileName = fileInfo['name'] as String;
    final fileSize = fileInfo['size'] as int;
    final fileType = fileInfo['type'] as String;
    
    debugPrint('Received file transfer request: $fileName ($fileSize bytes)');
    
    // Create file message
    final message = Message(
      chatId: data['chatId'] as String,
      senderId: data['senderId'] as String,
      senderName: data['senderName'] as String,
      content: fileName,
      type: MessageType.file,
      metadata: fileInfo,
    );
    
    final chatId = message.chatId;
    _conversations.putIfAbsent(chatId, () => []);
    _conversations[chatId]!.add(message);
    
    notifyListeners();
  }

  void _handleConnectionRequest(Map<String, dynamic> data, String senderIp, Socket socket) {
    final userId = data['userId'] as String;
    final userName = data['userName'] as String;
    
    debugPrint('Connection request from $userName ($userId) at $senderIp');
    
    // Get current user from ProfileService if not already set
    if (_currentUser == null) {
      _currentUser = ProfileService().currentUser;
    }
    
    // Send connection acknowledgment
    final response = json.encode({
      'type': 'connection_ack',
      'userId': _currentUser?.id,
      'userName': _currentUser?.name,
      'timestamp': DateTime.now().toIso8601String(),
    });
    
    socket.write('$response\n');
  }

  Future<void> sendMessage(Message message, Device targetDevice, MDNSDiscoveryService mdnsService) async {
    // Get current user from ProfileService if not already set
    if (_currentUser == null) {
      _currentUser = ProfileService().currentUser;
    }
    
    // Check authentication
    if (!_authService.isAuthenticated || _currentUser == null) {
      debugPrint('❌ ChatService: Auth check - isAuthenticated: ${_authService.isAuthenticated}, currentUser: ${_currentUser?.name}');
      throw Exception('User not authenticated');
    }
    
    debugPrint('✅ ChatService: Sending message from ${_currentUser!.name} (${_currentUser!.id})');
    
    // Generate proper chat ID
    final chatId = _generateChatId(_currentUser!.id, targetDevice.userId ?? targetDevice.id);
    
    // Create new message with current user info and proper chat ID
    final updatedMessage = message.copyWith(
      chatId: chatId,
      senderId: _currentUser!.id,
      senderName: _currentUser!.name,
      receiverId: targetDevice.userId ?? targetDevice.id,
      status: MessageStatus.sending,
      timestamp: DateTime.now(),
    );
    
    // Store in conversation and persist
    _conversations.putIfAbsent(chatId, () => []);
    _conversations[chatId]!.add(updatedMessage);
    await _saveMessage(updatedMessage);
    
    // Send via mDNS service WebSocket connection
    try {
      final messagePayload = {
        'type': 'message',
        'message': updatedMessage.toJson(),
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      // Use both device ID and user ID to ensure message delivery
      final targetId = targetDevice.userId ?? targetDevice.id;
      debugPrint('📤 Sending message to: ${targetDevice.name} (ID: $targetId)');
      
      await mdnsService.sendMessage(targetId, messagePayload);
      updatedMessage.status = MessageStatus.sent;
      await _saveMessage(updatedMessage);
      
      // Notify stream listeners
      if (_messageStreams.containsKey(chatId)) {
        _messageStreams[chatId]!.add(updatedMessage);
      }
    } catch (e) {
      debugPrint('Error sending message: $e');
      updatedMessage.status = MessageStatus.failed;
      await _saveMessage(updatedMessage);
      rethrow; // Propagate error to caller
    }
    
    notifyListeners();
  }

  Future<void> sendTypingIndicator(String chatId, Device targetDevice, bool isTyping) async {
    if (_currentUser == null) return;
    
    final payload = json.encode({
      'type': 'typing',
      'chatId': chatId,
      'userId': _currentUser!.id,
      'userName': _currentUser!.name,
      'isTyping': isTyping,
      'timestamp': DateTime.now().toIso8601String(),
    });
    
    try {
      await _sendToDevice(targetDevice.ipAddress, targetDevice.port, payload);
    } catch (e) {
      debugPrint('Error sending typing indicator: $e');
    }
  }

  void _sendReceipt(String messageId, String senderId, MessageStatus status, String senderIp) {
    final receipt = json.encode({
      'type': 'receipt',
      'messageId': messageId,
      'status': status.name,
      'timestamp': DateTime.now().toIso8601String(),
    });
    
    if (_activeConnections.containsKey(senderIp)) {
      _activeConnections[senderIp]!.write('$receipt\n');
    }
  }


  Future<void> _sendToDevice(String ipAddress, int port, String data) async {
    if (_activeConnections.containsKey(ipAddress)) {
      _activeConnections[ipAddress]!.write('$data\n');
    } else {
      final socket = await Socket.connect(ipAddress, port);
      socket.write('$data\n');
      socket.close();
    }
  }

  Stream<Message> getMessageStream(String chatId) {
    _messageStreams.putIfAbsent(chatId, () => StreamController<Message>.broadcast());
    return _messageStreams[chatId]!.stream;
  }

  List<Message> getConversation(String chatId) {
    return _conversations[chatId] ?? [];
  }
  
  List<Message> getConversationForDevice(Device device) {
    if (_currentUser == null) return [];
    final chatId = _generateChatId(_currentUser!.id, device.userId ?? device.id);
    return getConversation(chatId);
  }

  void markMessageAsRead(String messageId) async {
    // Get current user from ProfileService if not already set
    if (_currentUser == null) {
      _currentUser = ProfileService().currentUser;
    }
    
    if (!_authService.isAuthenticated || _currentUser == null) return;
    
    for (final conversation in _conversations.values) {
      for (final message in conversation) {
        if (message.id == messageId && message.status != MessageStatus.read) {
          message.status = MessageStatus.read;
          message.readAt = DateTime.now();
          await _saveMessage(message);
          notifyListeners();
          
          // Send read receipt if we're the receiver
          if (message.receiverId == _currentUser?.id) {
            // Find sender's IP and send receipt
            for (final socket in _activeConnections.values) {
              try {
                final receipt = json.encode({
                  'type': 'receipt',
                  'messageId': messageId,
                  'status': MessageStatus.read.name,
                  'timestamp': DateTime.now().toIso8601String(),
                });
                socket.write('$receipt\n');
              } catch (e) {
                debugPrint('Failed to send read receipt: $e');
              }
            }
          }
          return;
        }
      }
    }
  }
  
  Future<Map<String, dynamic>> getChatMetadata(String chatId) async {
    int unreadCount = 0;
    Message? lastMessage;
    
    final messages = getConversation(chatId);
    if (messages.isNotEmpty) {
      lastMessage = messages.last;
      for (var msg in messages) {
        if (msg.receiverId == _currentUser?.id && msg.status != MessageStatus.read) {
          unreadCount++;
        }
      }
    }
    
    return {
      'unreadCount': unreadCount,
      'lastMessage': lastMessage,
      'messageCount': messages.length,
    };
  }

  void clearConversation(String chatId) {
    _conversations.remove(chatId);
    notifyListeners();
  }

  void deleteMessage(String messageId) {
    for (final conversation in _conversations.values) {
      conversation.removeWhere((m) => m.id == messageId);
    }
    notifyListeners();
  }

  Future<void> handleIncomingMessage(Map<String, dynamic> messageData, String senderDeviceId) async {
    try {
      debugPrint('Handling incoming message from $senderDeviceId');
      debugPrint('Message data: $messageData');
      
      // Create message from received data
      final message = Message.fromJson(messageData);
      
      // Generate chat ID
      final chatId = _generateChatId(message.senderId, _currentUser?.id ?? '');
      
      // Update message with proper chat ID and mark as received
      final receivedMessage = message.copyWith(
        chatId: chatId,
        status: MessageStatus.delivered,
        timestamp: DateTime.now(),
      );
      
      // Store in conversation
      _conversations.putIfAbsent(chatId, () => []);
      _conversations[chatId]!.add(receivedMessage);
      await _saveMessage(receivedMessage);
      
      // Notify UI
      notifyListeners();
      
      // Send to message stream if exists
      if (_messageStreams.containsKey(chatId)) {
        _messageStreams[chatId]!.add(receivedMessage);
      }
      
      // Show notification
      try {
        debugPrint('Showing notification for message from ${receivedMessage.senderName}');
      } catch (e) {
        debugPrint('Error showing notification: $e');
      }
      
      // Send delivery receipt
      await _sendDeliveryReceipt(receivedMessage, senderDeviceId);
      
      debugPrint('Message handled successfully: ${receivedMessage.content}');
    } catch (e) {
      debugPrint('Error handling incoming message: $e');
    }
  }

  Future<void> _sendDeliveryReceipt(Message message, String senderDeviceId) async {
    try {
      // This would need MDNSDiscoveryService to send receipt
      debugPrint('Should send delivery receipt for message: ${message.id}');
    } catch (e) {
      debugPrint('Error sending delivery receipt: $e');
    }
  }

  @override
  void dispose() {
    _chatServer?.close();
    for (final socket in _activeConnections.values) {
      socket.close();
    }
    for (final controller in _messageStreams.values) {
      controller.close();
    }
    super.dispose();
  }
}
