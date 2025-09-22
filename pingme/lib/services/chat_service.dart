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

class ChatService extends ChangeNotifier {
  static const int chatPort = 8889;
  static const int maxRetries = 3;
  static const Duration messageTimeout = Duration(seconds: 10);

  ServerSocket? _chatServer;
  final Map<String, Socket> _activeConnections = {};
  final Map<String, List<Message>> _conversations = {};
  final Map<String, StreamController<Message>> _messageStreams = {};
  final List<Message> _pendingMessages = [];
  
  Box<Map>? _messagesBox;
  Box<Map>? _conversationsBox;
  User? _currentUser;
  bool _isServerRunning = false;
  final AuthService _authService = AuthService();
  final NotificationService _notificationService = NotificationService();

  Map<String, List<Message>> get conversations => Map.unmodifiable(_conversations);
  bool get isServerRunning => _isServerRunning;
  User? get currentUser => _currentUser;

  Future<void> initialize(User user) async {
    _currentUser = user;
    await _initializeStorage();
    await _loadConversations();
    await startChatServer();
  }

  Future<void> _initializeStorage() async {
    try {
      _messagesBox = await Hive.openBox<Map>('messages');
      _conversationsBox = await Hive.openBox<Map>('conversations');
    } catch (e) {
      debugPrint('Error initializing storage: $e');
    }
  }

  Future<void> _loadConversations() async {
    if (_messagesBox == null || _currentUser == null) return;
    
    try {
      // Load all messages from storage
      for (var key in _messagesBox!.keys) {
        final messageData = _messagesBox!.get(key);
        if (messageData != null) {
          final message = Message.fromJson(Map<String, dynamic>.from(messageData));
          final chatId = message.chatId;
          
          _conversations.putIfAbsent(chatId, () => []);
          _conversations[chatId]!.add(message);
        }
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
      );
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

  void _handleTextMessage(Map<String, dynamic> data, String senderIp) async {
    // Check authentication
    if (!_authService.isAuthenticated || _currentUser == null) {
      debugPrint('Unauthenticated user cannot receive messages');
      return;
    }
    
    var message = Message.fromJson(data['message'] as Map<String, dynamic>);
    
    // Generate proper chat ID and create new message with updated fields
    final chatId = _generateChatId(message.senderId, _currentUser!.id);
    message = message.copyWith(
      chatId: chatId,
      status: MessageStatus.delivered,
    );
    
    // Store message in conversation and persist
    _conversations.putIfAbsent(chatId, () => []);
    _conversations[chatId]!.add(message);
    await _saveMessage(message);
    
    // Notify stream listeners
    if (_messageStreams.containsKey(chatId)) {
      _messageStreams[chatId]!.add(message);
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
    // Check authentication
    if (!_authService.isAuthenticated || _currentUser == null) {
      throw Exception('User not authenticated');
    }
    
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
      
      await mdnsService.sendMessage(targetDevice.id, messagePayload);
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
      
      // Try legacy connection if WebSocket fails
      if (!_activeConnections.containsKey(targetDevice.ipAddress)) {
        _pendingMessages.add(updatedMessage);
        await _connectToDevice(targetDevice);
      }
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

  Future<void> _connectToDevice(Device device) async {
    if (_activeConnections.containsKey(device.ipAddress)) return;
    
    try {
      final socket = await Socket.connect(
        device.ipAddress,
        device.port,
        timeout: const Duration(seconds: 5),
      );
      
      _activeConnections[device.ipAddress] = socket;
      
      // Send connection request
      final request = json.encode({
        'type': 'connection',
        'userId': _currentUser?.id,
        'userName': _currentUser?.name,
        'timestamp': DateTime.now().toIso8601String(),
      });
      
      socket.write('$request\n');
      
      // Handle incoming messages from this connection
      _handleIncomingConnection(socket);
      
      // Send pending messages
      _sendPendingMessages(device);
      
    } catch (e) {
      debugPrint('Error connecting to device: $e');
      throw Exception('Failed to connect to device');
    }
  }

  void _sendPendingMessages(Device device) {
    final pending = _pendingMessages.where((m) => m.receiverId == device.userId).toList();
    
    for (final message in pending) {
      // Note: sendMessage now requires MDNSDiscoveryService as third parameter
      // This needs to be passed from the caller
      debugPrint('Pending message needs MDNSDiscoveryService to resend');
      _pendingMessages.remove(message);
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
