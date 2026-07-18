import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/profile_service.dart';
import '../../services/auth_service.dart';
import '../../services/theme_service.dart';
import '../../services/language_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/neumorphic_container.dart';
import '../../utils/localization_helper.dart';
import 'terms_of_service_screen.dart';
import 'privacy_policy_screen.dart';
import 'language_selection_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isDarkMode = false;
  bool _notificationsEnabled = true;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  bool _locationEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() async {
    final profileService = context.read<ProfileService>();
    final themeService = context.read<ThemeService>();
    final prefs = await SharedPreferences.getInstance();
    
    setState(() {
      _isDarkMode = themeService.isDarkMode;
      _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
      _soundEnabled = prefs.getBool('sound_notifications') ?? true;
      _vibrationEnabled = prefs.getBool('vibration_notifications') ?? true;
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
          child: Text(context.l10n.pleaseLoginToAccessSettings),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.settings),
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
            context.l10n.appearance,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            title: Text(context.l10n.darkMode),
            subtitle: Text(context.l10n.switchTheme),
            secondary: Icon(
              _isDarkMode ? Icons.dark_mode : Icons.light_mode,
              color: AppTheme.primaryColor,
            ),
            value: _isDarkMode,
            activeColor: AppTheme.primaryColor,
            onChanged: (value) async {
              setState(() => _isDarkMode = value);
              
              final themeService = context.read<ThemeService>();
              await themeService.setTheme(value);
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(value ? context.l10n.changedToDarkMode : context.l10n.changedToLightMode),
                  duration: const Duration(seconds: 1),
                  backgroundColor: AppTheme.primaryColor,
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
            context.l10n.notifications,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            title: Text(context.l10n.pushNotifications),
            subtitle: Text(context.l10n.receiveNotifications),
            secondary: const Icon(Icons.notifications, color: AppTheme.primaryColor),
            value: _notificationsEnabled,
            activeColor: AppTheme.primaryColor,
            onChanged: (value) async {
              setState(() => _notificationsEnabled = value);
              
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('notifications_enabled', value);
              
              if (value) {
                // Request notification permission
                await Permission.notification.request();
                // NotificationService().initialize(); // Commented out until implemented
              }
              
              if (mounted) {
                final profileService = context.read<ProfileService>();
                await profileService.setNotificationsEnabled(value);
              }
            },
          ),
          if (_notificationsEnabled) ...[
            SwitchListTile(
              title: Text(context.l10n.sound),
              subtitle: Text(context.l10n.playSound),
              secondary: const Icon(Icons.volume_up, color: AppTheme.primaryColor),
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
              title: Text(context.l10n.vibration),
              subtitle: Text(context.l10n.vibrateNotifications),
              secondary: const Icon(Icons.vibration, color: AppTheme.primaryColor),
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
            context.l10n.language,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Consumer<LanguageService>(
            builder: (context, languageService, _) {
              return ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.primaryColor.withOpacity(0.1),
                  ),
                  child: Center(
                    child: Text(
                      languageService.getLanguageFlag(languageService.currentLanguage),
                      style: const TextStyle(fontSize: 20),
                    ),
                  ),
                ),
                title: Text(
                  languageService.getLanguageName(languageService.currentLanguage),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  context.l10n.appLanguage,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey,
                  ),
                ),
                trailing: Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: AppTheme.primaryColor,
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LanguageSelectionScreen(),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms, delay: 150.ms).slideX(begin: 0.1, end: 0);
  }

  Widget _buildPrivacySection(BuildContext context) {
    return NeumorphicContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.privacyPermissions,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            title: Text(context.l10n.locationAccess),
            subtitle: Text(context.l10n.allowLocation),
            secondary: const Icon(Icons.location_on, color: AppTheme.primaryColor),
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
                      content: Text(context.l10n.locationGranted),
                      backgroundColor: AppTheme.successColor,
                    ),
                  );
                } else if (status.isPermanentlyDenied) {
                  // Open app settings
                  await openAppSettings();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(context.l10n.locationDenied),
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
                    content: Text(context.l10n.locationDisabled),
                  ),
                );
              }
            },
          ),
          ListTile(
            title: Text(context.l10n.clearChatHistory),
            subtitle: Text(context.l10n.deleteAllMessages),
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            onTap: () => _showClearHistoryDialog(context),
          ),
          ListTile(
            title: Text(context.l10n.exportData),
            subtitle: Text(context.l10n.exportProfileData),
            leading: const Icon(Icons.download, color: AppTheme.primaryColor),
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
            context.l10n.about,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ListTile(
            title: Text(context.l10n.version),
            subtitle: const Text('1.0.0'),
            leading: const Icon(Icons.info_outline, color: AppTheme.primaryColor),
          ),
          ListTile(
            title: Text(context.l10n.termsOfService),
            leading: const Icon(Icons.description, color: AppTheme.primaryColor),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const TermsOfServiceScreen(),
                ),
              );
            },
          ),
          ListTile(
            title: Text(context.l10n.privacyPolicy),
            leading: const Icon(Icons.privacy_tip, color: AppTheme.primaryColor),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PrivacyPolicyScreen(),
                ),
              );
            },
          ),
          ListTile(
            title: Text(context.l10n.licenses),
            leading: const Icon(Icons.code, color: AppTheme.primaryColor),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              showLicensePage(
                context: context,
                applicationName: 'PingMe',
                applicationVersion: '1.0.0',
                applicationIcon: const Icon(
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

  void _showClearHistoryDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.clearChatHistory),
        content: Text(context.l10n.areYouSure),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              // Clear chat history logic here
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(context.l10n.chatHistoryCleared),
                  backgroundColor: AppTheme.successColor,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: Text(context.l10n.clear),
          ),
        ],
      ),
    );
  }

  void _exportData(BuildContext context) async {
    // Export user data logic
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.l10n.exportingData),
        duration: const Duration(seconds: 1),
      ),
    );
    
    // In a real app, you would create a JSON file with user data
    // and save it or share it
  }
}
