import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/chat_request.dart';
import '../services/chat_request_service.dart';
import '../services/mdns_discovery_service.dart';
import '../theme/app_theme.dart';
import '../ui/screens/chat_screen.dart';
import '../models/device.dart';

class ChatRequestDialog extends StatelessWidget {
  final ChatRequest request;

  const ChatRequestDialog({
    super.key,
    required this.request,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.primaryColor.withOpacity(0.8),
                        AppTheme.accentColor.withOpacity(0.8),
                      ],
                    ),
                  ),
                  child: Center(
                    child: Text(
                      request.fromUserName.isNotEmpty 
                          ? request.fromUserName[0].toUpperCase() 
                          : '?',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Chat Request',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'From ${request.fromUserName}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chat_bubble,
                  color: AppTheme.primaryColor,
                  size: 28,
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Message
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                request.message.isNotEmpty 
                    ? request.message 
                    : 'Hi! Would you like to chat?',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Expiry info
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.timer,
                  size: 16,
                  color: Colors.grey,
                ),
                const SizedBox(width: 4),
                Text(
                  'Expires in ${_getTimeRemaining()}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _rejectRequest(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: BorderSide(color: AppTheme.errorColor),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.close,
                          size: 18,
                          color: AppTheme.errorColor,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Decline',
                          style: TextStyle(color: AppTheme.errorColor),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _acceptRequest(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.successColor,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.check,
                          size: 18,
                          color: Colors.white,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Accept',
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ).animate()
      .scale(begin: const Offset(0.8, 0.8), duration: 300.ms)
      .fadeIn(duration: 300.ms);
  }

  String _getTimeRemaining() {
    final remaining = request.expiresAt.difference(DateTime.now());
    if (remaining.isNegative) return 'Expired';
    
    final minutes = remaining.inMinutes;
    final seconds = remaining.inSeconds % 60;
    
    if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }

  void _acceptRequest(BuildContext context) async {
    try {
      debugPrint('User clicked Accept button for request: ${request.id}');
      
      // Show loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
              SizedBox(width: 16),
              Text('Accepting chat request...'),
            ],
          ),
          duration: Duration(seconds: 5),
        ),
      );
      
      final chatRequestService = context.read<ChatRequestService>();
      final mdnsService = context.read<MDNSDiscoveryService>();
      
      debugPrint('Calling acceptRequest method...');
      final success = await chatRequestService.acceptRequest(
        request.id,
        mdnsService,
      );

      debugPrint('Accept request result: $success');

      if (success && context.mounted) {
        Navigator.pop(context);
        
        // Navigate to chat screen
        final device = Device(
          id: request.fromDeviceId,
          name: request.fromUserName,
          ipAddress: '', // Will be resolved by mDNS
          port: 8889,
          userId: request.fromUserId,
          type: DeviceType.mobile,
        );
        
        debugPrint('Navigating to chat screen with device: ${device.name}');
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(device: device),
          ),
        );
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Chat request accepted! Starting conversation with ${request.fromUserName}...'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      } else if (context.mounted) {
        Navigator.pop(context); // Close loading snackbar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to accept chat request from ${request.fromUserName}'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error accepting chat request: $e');
      debugPrint('Stack trace: ${StackTrace.current}');
      if (context.mounted) {
        Navigator.pop(context); // Close any existing snackbar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error accepting request: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  void _rejectRequest(BuildContext context) async {
    try {
      final chatRequestService = context.read<ChatRequestService>();
      final mdnsService = context.read<MDNSDiscoveryService>();
      
      final success = await chatRequestService.rejectRequest(
        request.id,
        mdnsService,
      );
      
      if (success && context.mounted) {
        Navigator.pop(context);
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Chat request declined'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error rejecting chat request: $e');
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to decline request: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }
}
