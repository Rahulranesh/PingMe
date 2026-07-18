import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../services/chat_service.dart';
import '../../services/discovery_service.dart';
import '../../services/mdns_discovery_service.dart';
import '../../models/message.dart';
import '../../models/device.dart';
import '../../theme/app_theme.dart';
import '../../widgets/neumorphic_container.dart';
import '../../utils/localization_helper.dart';
import 'chat_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  @override
  Widget build(BuildContext context) {
    final chatService = context.watch<ChatService>();
    final conversations = chatService.conversations;

    if (conversations.isEmpty) {
      return _buildEmptyState(context);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: conversations.length,
      itemBuilder: (context, index) {
        final chatId = conversations.keys.elementAt(index);
        final messages = conversations[chatId]!;
        final lastMessage = messages.isNotEmpty ? messages.last : null;
        
        // Find device for this chat
        // Create temporary device from message
        final device = Device(
          id: chatId,
          name: lastMessage?.senderName ?? 'Unknown',
          type: DeviceType.mobile,
          ipAddress: '0.0.0.0',
          port: 0,
          status: ConnectionStatus.disconnected,
        );

        if (true) {
          return _buildChatItem(context, device, lastMessage, messages)
              .animate()
              .fadeIn(duration: 200.ms, delay: (index * 50).ms)
              .slideY(begin: 0.1, end: 0, duration: 200.ms);
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            context.l10n.noConversationsYet,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            context.l10n.discoverNearbyToChat,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatItem(
    BuildContext context,
    Device device,
    Message? lastMessage,
    List<Message> messages,
  ) {
    final unreadCount = messages.where((m) => 
      m.senderId != context.read<ChatService>().currentUser?.id &&
      m.status != MessageStatus.read
    ).length;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: NeumorphicContainer(
        onTap: () {
          // Ensure we pass the latest device state from discovery service
          final mdnsService = context.read<MDNSDiscoveryService>();
          final latestDevice = mdnsService.discoveredDevices[device.id] ?? device;
          
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatScreen(device: latestDevice),
            ),
          ).then((_) {
            // Refresh messages when returning from chat
            setState(() {});
          });
        },
        child: Row(
          children: [
            _buildAvatar(device),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          device.name,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (lastMessage != null)
                        Text(
                          _formatTime(lastMessage.timestamp),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (lastMessage != null) ...[
                        if (lastMessage.senderId == context.read<ChatService>().currentUser?.id)
                          Icon(
                            _getStatusIcon(lastMessage.status),
                            size: 16,
                            color: AppTheme.primaryColor,
                          ),
                        const SizedBox(width: 4),
                      ],
                      Expanded(
                        child: Text(
                          _getLastMessageText(lastMessage),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey.shade600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (unreadCount > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            unreadCount.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(Device device) {
    final isOnline = device.status == ConnectionStatus.connected;
    
    return Stack(
      children: [
        Container(
          width: 50,
          height: 50,
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
              device.name.isNotEmpty ? device.name[0].toUpperCase() : '?',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        Positioned(
          right: 0,
          bottom: 0,
          child: Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              color: isOnline ? Colors.green : Colors.grey,
              shape: BoxShape.circle,
              border: Border.all(
                color: Theme.of(context).scaffoldBackgroundColor,
                width: 2,
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'now';
    }
  }

  String _getLastMessageText(Message? message) {
    if (message == null) return 'No messages yet';

    switch (message.type) {
      case MessageType.text:
        return message.content;
      case MessageType.image:
        return '📷 Photo';
      case MessageType.video:
        return '🎥 Video';
      case MessageType.audio:
        return '🎵 Audio';
      case MessageType.file:
        return '📎 File';
      case MessageType.location:
        return '📍 Location';
      case MessageType.contact:
        return '👤 Contact';
      default:
        return message.content;
    }
  }

  IconData _getStatusIcon(MessageStatus status) {
    switch (status) {
      case MessageStatus.pending:
        return Icons.access_time;
      case MessageStatus.sent:
        return Icons.check;
      case MessageStatus.delivered:
        return Icons.done_all;
      case MessageStatus.read:
        return Icons.done_all;
      case MessageStatus.failed:
        return Icons.error_outline;
      default:
        return Icons.check;
    }
  }
}
