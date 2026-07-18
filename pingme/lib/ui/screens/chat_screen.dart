import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../services/chat_service.dart';
import '../../services/mdns_discovery_service.dart';
import '../../models/device.dart';
import '../../models/message.dart';
import '../../theme/app_theme.dart';
import '../../widgets/neumorphic_container.dart';
import '../../utils/localization_helper.dart';

class ChatScreen extends StatefulWidget {
  final Device device;

  const ChatScreen({super.key, required this.device});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  late ChatService _chatService;
  late StreamSubscription<Message> _messageSubscription;

  List<Message> _messages = [];
  bool _isTyping = false;
  Timer? _typingTimer;

  @override
  void initState() {
    super.initState();
    _chatService = context.read<ChatService>();
    _loadMessages();
    _listenToMessages();
    // Only try to connect if not already connected
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ensureConnection();
    });
  }

  Future<void> _ensureConnection() async {
    final mdnsService = context.read<MDNSDiscoveryService>();

    // First check if device exists in discovered devices
    final discoveredDevice = mdnsService.discoveredDevices[widget.device.id];
    final deviceToConnect = discoveredDevice ?? widget.device;

    // Check if device is already connected
    if (!mdnsService.hasActiveConnection(deviceToConnect.id)) {
      debugPrint(
          '📱 Device not connected, attempting to establish connection...');
      try {
        // Try to restore connection
        await mdnsService.connectToDevice(deviceToConnect);
        debugPrint('✅ Connection established with ${widget.device.name}');
      } catch (e) {
        debugPrint('⚠️ Failed to establish connection: $e');
        // Connection failure is not critical - messages might still work through discovery
      }
    } else {
      debugPrint('✅ Device already connected: ${widget.device.name}');
    }
  }

  void _loadMessages() {
    setState(() {
      _messages = _chatService.getConversationForDevice(widget.device);
      // Remove duplicates based on message ID
      final uniqueMessages = <String, Message>{};
      for (var message in _messages) {
        uniqueMessages[message.id] = message;
        // Mark messages as read
        if (message.receiverId == _chatService.currentUser?.id &&
            message.status != MessageStatus.read) {
          _chatService.markMessageAsRead(message.id);
        }
      }
      _messages = uniqueMessages.values.toList()
        ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    });
    _scrollToBottom();
  }

  void _listenToMessages() {
    final chatId = _chatService.currentUser != null
        ? '${[
            _chatService.currentUser!.id,
            widget.device.userId ?? widget.device.id
          ]..sort()}'
            .replaceAll('[', '')
            .replaceAll(']', '')
            .replaceAll(', ', '_')
        : widget.device.userId ?? widget.device.id;

    _messageSubscription =
        _chatService.getMessageStream(chatId).listen((message) {
      setState(() {
        if (message.type == MessageType.typing) {
          // Handle typing indicator
          _isTyping = message.metadata['isTyping'] == true;
        } else {
          // Check if message already exists to avoid duplicates
          if (!_messages.any((m) => m.id == message.id)) {
            _messages.add(message);
            // Mark as read if we're the receiver
            if (message.receiverId == _chatService.currentUser?.id) {
              _chatService.markMessageAsRead(message.id);
            }
          }
        }
      });
      _scrollToBottom();
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    _messageSubscription.cancel();
    _typingTimer?.cancel();
    // Don't disconnect - keep connection alive for chat list
    // The connection will be managed by MDNSDiscoveryService
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? AppTheme.darkBackground
          : AppTheme.lightBackground,
      appBar: _buildAppBar(context),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).scaffoldBackgroundColor,
              Theme.of(context).brightness == Brightness.dark
                  ? AppTheme.darkSurface.withOpacity(0.3)
                  : AppTheme.lightSurface.withOpacity(0.3),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: _buildMessagesList(),
              ),
              _buildInputArea(context),
            ],
          ),
        ),
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    final isConnected = widget.device.status == ConnectionStatus.connected;
    final avatarUrl = widget.device.metadata['avatarUrl'];
    final status = widget.device.metadata['status'];

    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => Navigator.pop(context),
      ),
      title: Row(
        children: [
          Stack(
            children: [
              if (avatarUrl != null && avatarUrl.toString().isNotEmpty)
                CircleAvatar(
                  radius: 18,
                  backgroundImage: NetworkImage(avatarUrl.toString()),
                  onBackgroundImageError: (_, __) {},
                )
              else
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.primaryColor.withOpacity(0.8),
                        AppTheme.secondaryColor.withOpacity(0.8),
                      ],
                    ),
                  ),
                  child: Center(
                    child: Text(
                      widget.device.name.isNotEmpty
                          ? widget.device.name[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: isConnected ? Colors.green : Colors.grey,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      width: 2,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.device.name,
                  style: const TextStyle(fontSize: 16),
                ),
                Text(
                  status?.toString() ??
                      (isConnected
                          ? context.l10n.online
                          : context.l10n.offline),
                  style: TextStyle(
                    fontSize: 12,
                    color: isConnected ? Colors.green : Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.info_outline),
          onPressed: () => _showDeviceInfo(context),
        ),
      ],
    );
  }

  Widget _buildMessagesList() {
    if (_messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.waving_hand,
              size: 60,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              context.l10n.sayHiTo(widget.device.name),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.grey.shade600,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              context.l10n.startConversation,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade500,
                  ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
        final isMe = message.senderId == _chatService.currentUser?.id;

        return _buildMessageBubble(message, isMe)
            .animate()
            .fadeIn(duration: 200.ms)
            .slideY(begin: 0.1, end: 0);
      },
    );
  }

  Widget _buildMessageBubble(Message message, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
          bottom: 12,
          left: isMe ? 60 : 16,
          right: isMe ? 16 : 60,
        ),
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            // Show sender name for received messages
            if (!isMe)
              Padding(
                padding: const EdgeInsets.only(bottom: 4, left: 16),
                child: Text(
                  message.senderName,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                ),
              ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: isMe
                    ? LinearGradient(
                        colors: [
                          AppTheme.primaryColor,
                          AppTheme.primaryColor.withOpacity(0.85),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : LinearGradient(
                        colors: [
                          Theme.of(context).brightness == Brightness.dark
                              ? Colors.grey.shade800
                              : Colors.white,
                          Theme.of(context).brightness == Brightness.dark
                              ? Colors.grey.shade700
                              : Colors.grey.shade50,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(isMe ? 20 : 5),
                  bottomRight: Radius.circular(isMe ? 5 : 20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: isMe
                        ? AppTheme.primaryColor.withOpacity(0.2)
                        : Colors.black.withOpacity(0.08),
                    offset: const Offset(0, 4),
                    blurRadius: 10,
                    spreadRadius: isMe ? 1 : 0,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.content,
                    style: TextStyle(
                      color: isMe
                          ? Colors.white
                          : Theme.of(context).textTheme.bodyLarge?.color,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _formatTime(message.timestamp),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontSize: 11,
                      ),
                ),
                if (isMe) ...[
                  const SizedBox(width: 4),
                  Icon(
                    _getStatusIcon(message.status),
                    size: 14,
                    color: message.status == MessageStatus.read
                        ? AppTheme.primaryColor
                        : Colors.grey,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, -2),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.attach_file),
            onPressed: () => _showAttachmentOptions(context),
            color: Colors.grey,
          ),
          Expanded(
            child: NeumorphicTextField(
              controller: _messageController,
              focusNode: _focusNode,
              hintText: context.l10n.typeMessage,
              maxLines: 3,
              onChanged: (text) => _handleTyping(),
            ),
          ),
          const SizedBox(width: 8),
          NeumorphicButton(
            onPressed: _sendMessage,
            padding: const EdgeInsets.all(12),
            borderRadius: BorderRadius.circular(50),
            child: const Icon(
              Icons.send,
              color: Colors.white,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  void _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final mdnsService = context.read<MDNSDiscoveryService>();

    // Ensure connection is established first
    if (widget.device.status != ConnectionStatus.connected) {
      debugPrint('Device not connected, attempting connection...');
      try {
        await mdnsService.connectToDevice(widget.device);
        // Wait a moment for connection to stabilize
        await Future.delayed(const Duration(milliseconds: 500));
      } catch (e) {
        debugPrint('Failed to connect to device: $e');
        // Show error to user
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.l10n.failedToConnect),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
    }

    final message = Message(
      chatId: '', // Will be generated by chat service
      senderId: _chatService.currentUser?.id ?? '',
      senderName: _chatService.currentUser?.name ?? 'You',
      receiverId:
          widget.device.userId ?? widget.device.id, // Use device.id as fallback
      content: text,
      type: MessageType.text,
      timestamp: DateTime.now(),
    );

    // Add message to local list immediately for instant feedback
    setState(() {
      _messages.add(message);
    });
    _messageController.clear();
    _scrollToBottom();

    try {
      await _chatService.sendMessage(message, widget.device, mdnsService);
    } catch (e) {
      // Remove the message if sending failed
      setState(() {
        _messages.removeWhere((m) => m.id == message.id);
      });
      debugPrint('Failed to send message: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.failedToSendMessage),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _handleTyping() {
    if (!_isTyping) {
      _isTyping = true;
      _chatService.sendTypingIndicator(
        widget.device.userId ?? widget.device.id,
        widget.device,
        true,
      );
    }

    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 3), () {
      _isTyping = false;
      _chatService.sendTypingIndicator(
        widget.device.userId ?? widget.device.id,
        widget.device,
        false,
      );
    });
  }

  void _showAttachmentOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.image, color: AppTheme.primaryColor),
              title: Text(context.l10n.photo),
              onTap: () {
                Navigator.pop(context);
                // Implement photo picker
              },
            ),
            ListTile(
              leading: const Icon(Icons.videocam, color: AppTheme.primaryColor),
              title: Text(context.l10n.video),
              onTap: () {
                Navigator.pop(context);
                // Implement video picker
              },
            ),
            ListTile(
              leading:
                  const Icon(Icons.attach_file, color: AppTheme.primaryColor),
              title: Text(context.l10n.file),
              onTap: () {
                Navigator.pop(context);
                // Implement file picker
              },
            ),
            ListTile(
              leading:
                  const Icon(Icons.location_on, color: AppTheme.primaryColor),
              title: Text(context.l10n.location),
              onTap: () {
                Navigator.pop(context);
                // Implement location sharing
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showDeviceInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(widget.device.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('Device Type', widget.device.type.name),
            _buildInfoRow('IP Address', widget.device.ipAddress),
            _buildInfoRow('Port', widget.device.port.toString()),
            if (widget.device.platform != null)
              _buildInfoRow('Platform', widget.device.platform!),
            if (widget.device.model != null)
              _buildInfoRow('Model', widget.device.model!),
            _buildInfoRow('Signal', '${widget.device.signalStrength}%'),
            _buildInfoRow(
              'Last Connected',
              _formatDateTime(widget.device.lastConnected),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime timestamp) {
    final hour = timestamp.hour.toString().padLeft(2, '0');
    final minute = timestamp.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${_formatTime(dateTime)}';
  }

  IconData _getStatusIcon(MessageStatus status) {
    switch (status) {
      case MessageStatus.pending:
      case MessageStatus.sending:
        return Icons.access_time;
      case MessageStatus.sent:
        return Icons.check;
      case MessageStatus.delivered:
        return Icons.done_all;
      case MessageStatus.read:
        return Icons.done_all;
      case MessageStatus.failed:
        return Icons.error_outline;
    }
  }
}
