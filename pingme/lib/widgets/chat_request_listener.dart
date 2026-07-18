import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/chat_request_service.dart';
import '../services/mdns_discovery_service.dart';
import '../services/profile_service.dart';
import '../models/chat_request.dart';
import '../models/device.dart';
import '../ui/screens/chat_screen.dart';
import '../utils/localization_helper.dart';
import 'chat_request_dialog.dart';

class ChatRequestListener extends StatefulWidget {
  final Widget child;

  const ChatRequestListener({
    super.key,
    required this.child,
  });

  @override
  State<ChatRequestListener> createState() => _ChatRequestListenerState();
}

class _ChatRequestListenerState extends State<ChatRequestListener> {
  @override
  void initState() {
    super.initState();
    _listenForChatRequests();
  }

  void _listenForChatRequests() {
    final chatRequestService = context.read<ChatRequestService>();

    chatRequestService.requestStream.listen((request) {
      if (mounted) {
        if (request.isPending) {
          // Incoming request - show dialog
          _showChatRequestDialog(request);
        } else if (request.status == ChatRequestStatus.accepted) {
          // Sent request was accepted - show success notification
          _showRequestAcceptedNotification(request);
        } else if (request.status == ChatRequestStatus.rejected) {
          // Sent request was rejected - show rejection notification
          _showRequestRejectedNotification(request);
        }
      }
    });
  }

  void _showChatRequestDialog(ChatRequest request) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => ChatRequestDialog(request: request),
    );
  }

  void _showRequestAcceptedNotification(ChatRequest request) {
    debugPrint('🎉 Chat request ACCEPTED notification for: ${request.fromUserName}');

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                context.l10n.chatRequestAcceptedBy(request.fromUserName),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'CHAT',
          textColor: Colors.white,
          onPressed: () {
            debugPrint('🔗 User clicked CHAT button for accepted request');
            _navigateToChat(request);
          },
        ),
      ),
    );

    // Also show a dialog to make it more prominent
    _showAcceptanceDialog(request);
  }

  void _showAcceptanceDialog(ChatRequest request) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.green,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.green.withOpacity(0.3),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.check_circle,
                size: 64,
                color: Colors.white,
              ),
              const SizedBox(height: 16),
              Text(
                'Chat Request Accepted!',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${request.fromUserName} accepted your chat request',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withOpacity(0.9),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _navigateToChat(request);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.green,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Start Chat'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showRequestRejectedNotification(ChatRequest request) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.l10n.chatRequestRejectedBy(request.fromUserName)),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _navigateToChat(ChatRequest request) {
    // For accepted requests, we need to navigate to the other person
    // If the request was sent by us and accepted by them, navigate to the "to" user
    final currentUserId = context.read<ProfileService>().currentUser?.id;
    final isOurRequest = request.fromUserId == currentUserId;
    
    // Debug logging to understand the request
    debugPrint('📋 Chat Request Details:');
    debugPrint('  - Request ID: ${request.id}');
    debugPrint('  - From User: ${request.fromUserName} (${request.fromUserId})');
    debugPrint('  - From Device: ${request.fromDeviceId}');
    debugPrint('  - To User ID: ${request.toUserId}');
    debugPrint('  - To Device: ${request.toDeviceId}');
    debugPrint('  - Current User ID: $currentUserId');
    debugPrint('  - Is Our Request: $isOurRequest');
    
    final targetUserId = isOurRequest ? request.toUserId : request.fromUserId;
    final targetDeviceId = isOurRequest ? request.toDeviceId : request.fromDeviceId;
    
    debugPrint('🎯 Target User ID: $targetUserId');
    debugPrint('🎯 Target Device ID: $targetDeviceId');

    try {
      // Find the device in the MDNS service
      final mdnsService = context.read<MDNSDiscoveryService>();
      final devices = mdnsService.discoveredDevices;
      
      debugPrint('📱 Available devices: ${devices.length}');
      for (final entry in devices.entries) {
        debugPrint('  - Device ${entry.key}: ${entry.value.name} (userId: ${entry.value.userId}, deviceId: ${entry.value.id})');
      }

      Device? targetDevice;
      for (final device in devices.values) {
        // Check both device ID and user ID for matching
        if (device.id == targetDeviceId || device.userId == targetUserId) {
          targetDevice = device;
          debugPrint('✅ Found matching device: ${device.name}');
          break;
        }
      }

      if (targetDevice != null) {
        debugPrint('📱 Found target device: ${targetDevice.name} at ${targetDevice.ipAddress}:${targetDevice.port}');
        debugPrint('  - Device ID: ${targetDevice.id}');
        debugPrint('  - User ID: ${targetDevice.userId}');
        debugPrint('  - Status: ${targetDevice.status}');

        // Ensure connection is established
        if (targetDevice.status != ConnectionStatus.connected) {
          debugPrint('🔌 Establishing connection to target device...');
          mdnsService.connectToDevice(targetDevice);
        }

        // Navigate to chat screen with the device
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(device: targetDevice!),
          ),
        );

        debugPrint('✅ Successfully navigated to chat screen');
      } else {
        debugPrint('❌ Target device not found for chat navigation');
        debugPrint('  Looking for device ID: $targetDeviceId');
        debugPrint('  Looking for user ID: $targetUserId');
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error: Could not find chat partner device'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      debugPrint('💥 Error navigating to chat: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error starting chat: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
