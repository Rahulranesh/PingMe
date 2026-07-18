import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../theme/app_theme.dart';
import '../../widgets/neumorphic_container.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Terms of Service'),
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
                    'PingMe Terms of Service',
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
              '1. Acceptance of Terms',
              'By downloading, installing, or using PingMe, you agree to be bound by these Terms of Service. If you do not agree to these terms, please do not use our service.',
            ).animate().fadeIn(delay: 100.ms, duration: 300.ms),
            
            _buildSection(
              context,
              '2. Description of Service',
              'PingMe is a peer-to-peer messaging application that allows users to communicate directly with nearby devices on the same network without requiring internet connectivity or central servers.',
            ).animate().fadeIn(delay: 200.ms, duration: 300.ms),
            
            _buildSection(
              context,
              '3. User Responsibilities',
              '• You are responsible for maintaining the confidentiality of your account\n'
              '• You agree not to use the service for any unlawful purposes\n'
              '• You will not transmit harmful, offensive, or inappropriate content\n'
              '• You will respect other users\' privacy and consent',
            ).animate().fadeIn(delay: 300.ms, duration: 300.ms),
            
            _buildSection(
              context,
              '4. Privacy and Data',
              'PingMe operates on a peer-to-peer basis. Messages are transmitted directly between devices and are not stored on our servers. However, messages may be stored locally on your device.',
            ).animate().fadeIn(delay: 400.ms, duration: 300.ms),
            
            _buildSection(
              context,
              '5. Network Communication',
              'The app uses local network discovery (mDNS/Bonjour) to find nearby devices. This requires network permissions and may expose your device name and basic information to other PingMe users on the same network.',
            ).animate().fadeIn(delay: 500.ms, duration: 300.ms),
            
            _buildSection(
              context,
              '6. Limitations of Liability',
              'PingMe is provided "as is" without warranties. We are not liable for any damages arising from the use of this application, including but not limited to data loss, privacy breaches, or network security issues.',
            ).animate().fadeIn(delay: 600.ms, duration: 300.ms),
            
            _buildSection(
              context,
              '7. Changes to Terms',
              'We reserve the right to modify these terms at any time. Continued use of the application after changes constitutes acceptance of the new terms.',
            ).animate().fadeIn(delay: 700.ms, duration: 300.ms),
            
            _buildSection(
              context,
              '8. Contact Information',
              'For questions about these Terms of Service, please contact us at:\n'
              'Email: support@pingme.app\n'
              'GitHub: github.com/pingme-app',
            ).animate().fadeIn(delay: 800.ms, duration: 300.ms),
            
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
