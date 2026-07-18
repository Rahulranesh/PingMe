import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../theme/app_theme.dart';
import '../../widgets/neumorphic_container.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy'),
        backgroundColor: Colors.transparent,  
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            NeumorphicContainer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'PingMe Privacy Policy',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Last updated: ${DateTime.now().year}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.2),
            
            const SizedBox(height: 20),
            
            _buildSection(
              context,
              '1. Information We Collect',
              'PingMe is designed with privacy in mind. We collect minimal information:\n\n'
              '• Device name and basic device information\n'
              '• User profile information (name, avatar) that you provide\n'
              '• Local network information for device discovery\n'
              '• App usage analytics (anonymous)',
            ).animate().fadeIn(delay: 100.ms, duration: 300.ms),
            
            _buildSection(
              context,
              '2. How We Use Information',
              'The information we collect is used to:\n\n'
              '• Enable peer-to-peer communication between devices\n'
              '• Discover nearby devices on your local network\n'
              '• Provide and improve the messaging experience\n'
              '• Maintain app functionality and performance',
            ).animate().fadeIn(delay: 200.ms, duration: 300.ms),
            
            _buildSection(
              context,
              '3. Data Storage and Transmission',
              'PingMe operates on a peer-to-peer basis:\n\n'
              '• Messages are transmitted directly between devices\n'
              '• No messages are stored on external servers\n'
              '• Messages are stored locally on your device only\n'
              '• You can delete local messages at any time',
            ).animate().fadeIn(delay: 300.ms, duration: 300.ms),
            
            _buildSection(
              context,
              '4. Network Discovery',
              'To find nearby devices, PingMe:\n\n'
              '• Uses mDNS/Bonjour for local network discovery\n'
              '• Broadcasts your device name and basic info on local network\n'
              '• Only works on the same WiFi network\n'
              '• Does not access internet or external networks',
            ).animate().fadeIn(delay: 400.ms, duration: 300.ms),
            
            _buildSection(
              context,
              '5. Permissions',
              'PingMe requests the following permissions:\n\n'
              '• Network access: For local device discovery and communication\n'
              '• Storage: To save messages and media locally\n'
              '• Notifications: To alert you of new messages\n'
              '• Camera/Gallery: To share photos (optional)',
            ).animate().fadeIn(delay: 500.ms, duration: 300.ms),
            
            _buildSection(
              context,
              '6. Data Security',
              'We implement security measures:\n\n'
              '• All communications use secure WebSocket connections\n'
              '• Messages are encrypted during transmission\n'
              '• No data is transmitted to external servers\n'
              '• Local data is protected by device security',
            ).animate().fadeIn(delay: 600.ms, duration: 300.ms),
            
            _buildSection(
              context,
              '7. Third-Party Services',
              'PingMe may use:\n\n'
              '• Google Sign-In for authentication (optional)\n'
              '• Local device services for network discovery\n'
              '• No advertising or tracking services\n'
              '• No data sharing with third parties',
            ).animate().fadeIn(delay: 700.ms, duration: 300.ms),
            
            _buildSection(
              context,
              '8. Your Rights',
              'You have the right to:\n\n'
              '• Delete all local data and messages\n'
              '• Control what information you share\n'
              '• Disable network discovery at any time\n'
              '• Uninstall the app to remove all data',
            ).animate().fadeIn(delay: 800.ms, duration: 300.ms),
            
            _buildSection(
              context,
              '9. Contact Us',
              'For privacy-related questions:\n\n'
              'Email: privacy@pingme.app\n'
              'GitHub: github.com/pingme-app\n'
              'Website: pingme.app',
            ).animate().fadeIn(delay: 900.ms, duration: 300.ms),
            
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: NeumorphicContainer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              content,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
