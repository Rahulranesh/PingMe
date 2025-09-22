import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/profile_service.dart';
import '../../services/auth_service.dart';
import '../../services/notification_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/neumorphic_container.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isDarkMode = false;
  bool _notificationsEnabled = true;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  bool _locationEnabled = false;
  String _selectedLanguage = 'en';
  final Map<String, String> _languages = {
    'en': 'English',
    'es': 'Español',
    'fr': 'Français',
    'hi': 'हिंदी',
  };

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() async {
    final profileService = context.read<ProfileService>();
    final prefs = await SharedPreferences.getInstance();
    
    setState(() {
      _isDarkMode = prefs.getBool('dark_mode') ?? false;
      _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
      _soundEnabled = prefs.getBool('sound_notifications') ?? true;
      _vibrationEnabled = prefs.getBool('vibration_notifications') ?? true;
      _selectedLanguage = prefs.getString('app_language') ?? 'en';
    });
    
    // Check location permission status
    final locationStatus = await Permission.location.status;
    setState(() {
      _locationEnabled = locationStatus.isGranted;
    });
  }

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    
    if (!authService.isAuthenticated) {
      return Scaffold(
        body: Center(
          child: Text('Please login to access settings'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildAppearanceSection(context),
            const SizedBox(height: 20),
            _buildNotificationSection(context),
            const SizedBox(height: 20),
            _buildLanguageSection(context),
            const SizedBox(height: 20),
            _buildPrivacySection(context),
            const SizedBox(height: 20),
            _buildAboutSection(context),
          ],
        ),
      ),
    );
  }

  Widget _buildAppearanceSection(BuildContext context) {
    return NeumorphicContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Appearance',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            title: Text('Dark Mode'),
            subtitle: Text('Switch between light and dark themes'),
            secondary: Icon(
              _isDarkMode ? Icons.dark_mode : Icons.light_mode,
              color: AppTheme.primaryColor,
            ),
            value: _isDarkMode,
            activeColor: AppTheme.primaryColor,
            onChanged: (value) async {
              setState(() => _isDarkMode = value);
              
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('dark_mode', value);
              
              // Update theme immediately
              if (mounted) {
                final profileService = context.read<ProfileService>();
                await profileService.setDarkMode(value);
              }
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Theme changed to ${value ? "Dark" : "Light"} mode'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideX(begin: -0.1, end: 0);
  }

  Widget _buildNotificationSection(BuildContext context) {
    return NeumorphicContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Notifications',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            title: Text('Push Notifications'),
            subtitle: Text('Receive notifications for messages'),
            secondary: Icon(Icons.notifications, color: AppTheme.primaryColor),
            value: _notificationsEnabled,
            activeColor: AppTheme.primaryColor,
            onChanged: (value) async {
              setState(() => _notificationsEnabled = value);
              
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('notifications_enabled', value);
              
              if (value) {
                // Request notification permission
                await Permission.notification.request();
                NotificationService().initialize();
              }
              
              if (mounted) {
                final profileService = context.read<ProfileService>();
                await profileService.setNotificationsEnabled(value);
              }
            },
          ),
          if (_notificationsEnabled) ...[
            SwitchListTile(
              title: Text('Sound'),
              subtitle: Text('Play sound for notifications'),
              secondary: Icon(Icons.volume_up, color: AppTheme.primaryColor),
              value: _soundEnabled,
              activeColor: AppTheme.primaryColor,
              onChanged: (value) async {
                setState(() => _soundEnabled = value);
                
                final prefs = await SharedPreferences.getInstance();
                await prefs.setBool('sound_notifications', value);
                
                if (mounted) {
                  final profileService = context.read<ProfileService>();
                  await profileService.setSoundNotificationsEnabled(value);
                }
              },
            ),
            SwitchListTile(
              title: Text('Vibration'),
              subtitle: Text('Vibrate for notifications'),
              secondary: Icon(Icons.vibration, color: AppTheme.primaryColor),
              value: _vibrationEnabled,
              activeColor: AppTheme.primaryColor,
              onChanged: (value) async {
                setState(() => _vibrationEnabled = value);
                
                final prefs = await SharedPreferences.getInstance();
                await prefs.setBool('vibration_notifications', value);
                
                if (mounted) {
                  final profileService = context.read<ProfileService>();
                  await profileService.setVibrationNotificationsEnabled(value);
                }
              },
            ),
          ],
        ],
      ),
    ).animate().fadeIn(duration: 400.ms, delay: 100.ms).slideX(begin: 0.1, end: 0);
  }

  Widget _buildLanguageSection(BuildContext context) {
    return NeumorphicContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Language',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...(_languages.entries.map((entry) {
            return RadioListTile<String>(
              title: Text(entry.value),
              subtitle: Text(_getLanguageSubtitle(entry.key)),
              secondary: _getLanguageFlag(entry.key),
              value: entry.key,
              groupValue: _selectedLanguage,
              activeColor: AppTheme.primaryColor,
              onChanged: (value) async {
                if (value != null) {
                  setState(() => _selectedLanguage = value);
                  
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setString('app_language', value);
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Language changed to ${_languages[value]}'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                  
                  // In a real app, you would reload the UI with new locale
                  // using something like flutter_localizations
                }
              },
            );
          }).toList()),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms, delay: 200.ms).slideX(begin: -0.1, end: 0);
  }

  Widget _buildPrivacySection(BuildContext context) {
    return NeumorphicContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Privacy & Permissions',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            title: Text('Location Access'),
            subtitle: Text('Allow app to access your location'),
            secondary: Icon(Icons.location_on, color: AppTheme.primaryColor),
            value: _locationEnabled,
            activeColor: AppTheme.primaryColor,
            onChanged: (value) async {
              if (value) {
                final status = await Permission.location.request();
                setState(() {
                  _locationEnabled = status.isGranted;
                });
                
                if (status.isGranted) {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setBool('location_enabled', true);
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Location access granted'),
                      backgroundColor: AppTheme.successColor,
                    ),
                  );
                } else if (status.isPermanentlyDenied) {
                  // Open app settings
                  await openAppSettings();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Location access denied'),
                      backgroundColor: AppTheme.errorColor,
                    ),
                  );
                }
              } else {
                setState(() => _locationEnabled = false);
                final prefs = await SharedPreferences.getInstance();
                await prefs.setBool('location_enabled', false);
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Location access disabled'),
                  ),
                );
              }
            },
          ),
          ListTile(
            title: Text('Clear Chat History'),
            subtitle: Text('Delete all message history'),
            leading: Icon(Icons.delete_forever, color: Colors.red),
            onTap: () => _showClearHistoryDialog(context),
          ),
          ListTile(
            title: Text('Export Data'),
            subtitle: Text('Export your profile and chat data'),
            leading: Icon(Icons.download, color: AppTheme.primaryColor),
            onTap: () => _exportData(context),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms, delay: 300.ms).slideX(begin: 0.1, end: 0);
  }

  Widget _buildAboutSection(BuildContext context) {
    return NeumorphicContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'About',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ListTile(
            title: Text('Version'),
            subtitle: Text('1.0.0'),
            leading: Icon(Icons.info_outline, color: AppTheme.primaryColor),
          ),
          ListTile(
            title: Text('Terms of Service'),
            leading: Icon(Icons.description, color: AppTheme.primaryColor),
            trailing: Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              // Open terms of service
            },
          ),
          ListTile(
            title: Text('Privacy Policy'),
            leading: Icon(Icons.privacy_tip, color: AppTheme.primaryColor),
            trailing: Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              // Open privacy policy
            },
          ),
          ListTile(
            title: Text('Licenses'),
            leading: Icon(Icons.code, color: AppTheme.primaryColor),
            trailing: Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              showLicensePage(
                context: context,
                applicationName: 'PingMe',
                applicationVersion: '1.0.0',
                applicationIcon: Icon(
                  Icons.chat_bubble_rounded,
                  size: 64,
                  color: AppTheme.primaryColor,
                ),
              );
            },
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms, delay: 400.ms).slideX(begin: -0.1, end: 0);
  }

  String _getLanguageSubtitle(String code) {
    switch (code) {
      case 'en':
        return 'English (US)';
      case 'es':
        return 'Spanish';
      case 'fr':
        return 'French';
      case 'hi':
        return 'Hindi';
      default:
        return '';
    }
  }

  Widget _getLanguageFlag(String code) {
    String flag;
    switch (code) {
      case 'en':
        flag = '🇺🇸';
        break;
      case 'es':
        flag = '🇪🇸';
        break;
      case 'fr':
        flag = '🇫🇷';
        break;
      case 'hi':
        flag = '🇮🇳';
        break;
      default:
        flag = '🌍';
    }
    return Text(flag, style: TextStyle(fontSize: 24));
  }

  void _showClearHistoryDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Clear Chat History'),
        content: Text('Are you sure you want to delete all message history? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              // Clear chat history logic here
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Chat history cleared'),
                  backgroundColor: AppTheme.successColor,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: Text('Clear'),
          ),
        ],
      ),
    );
  }

  void _exportData(BuildContext context) async {
    // Export user data logic
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Exporting data...'),
        duration: Duration(seconds: 1),
      ),
    );
    
    // In a real app, you would create a JSON file with user data
    // and save it or share it
  }
}
