import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/profile_service.dart';
import '../../services/auth_service.dart';
import '../../services/mdns_discovery_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/neumorphic_container.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _bioController = TextEditingController();
  final _statusController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  
  bool _isDarkMode = false;
  bool _notificationsEnabled = true;
  bool _readReceipts = true;
  bool _typingIndicator = true;
  bool _isEditing = false;
  String? _localImagePath;
  String? _avatarUrl;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  void _loadProfile() async {
    final authService = context.read<AuthService>();
    final profileService = context.read<ProfileService>();
    
    if (!authService.isAuthenticated || authService.currentUser == null) {
      return;
    }
    
    final user = authService.currentUser!;
    
    _nameController.text = user.name;
    _emailController.text = user.metadata['email'] ?? '';
    _bioController.text = user.bio ?? '';
    _statusController.text = user.status ?? '';
    _avatarUrl = user.avatarUrl;
    
    // Load saved avatar from shared preferences
    final prefs = await SharedPreferences.getInstance();
    _localImagePath = prefs.getString('user_avatar_${user.id}');
    
    _isDarkMode = await profileService.isDarkMode();
    _notificationsEnabled = await profileService.areNotificationsEnabled();
    _readReceipts = await profileService.isReadReceiptsEnabled();
    _typingIndicator = await profileService.isTypingIndicatorEnabled();
    
    setState(() {});
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _statusController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    final user = authService.currentUser;

    if (!authService.isAuthenticated || user == null) {
      return Scaffold(
        body: Center(
          child: Text('Please login to view profile'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Profile'),
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.check : Icons.edit),
            onPressed: () {
              if (_isEditing) {
                _saveProfile();
              }
              setState(() {
                _isEditing = !_isEditing;
              });
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildProfileHeader(context, user),
            const SizedBox(height: 24),
            _buildProfileForm(context),
            const SizedBox(height: 24),
            _buildSettingsSection(context),
            const SizedBox(height: 24),
            _buildAboutSection(context),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context, user) {
    return Column(
      children: [
        Stack(
          children: [
            GestureDetector(
              onTap: _isEditing ? () => _showAvatarOptions(context) : null,
              child: _localImagePath != null && File(_localImagePath!).existsSync()
                  ? CircleAvatar(
                      radius: 50,
                      backgroundImage: FileImage(File(_localImagePath!)),
                    )
                  : _avatarUrl != null && _avatarUrl!.isNotEmpty
                      ? CircleAvatar(
                          radius: 50,
                          backgroundImage: NetworkImage(_avatarUrl!),
                        )
                      : Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [
                                AppTheme.primaryColor,
                                AppTheme.secondaryColor,
                              ],
                            ),
                          ),
                          child: Center(
                            child: Text(
                              user?.name?.isNotEmpty == true
                                  ? user.name[0].toUpperCase()
                                  : 'U',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 40,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
            ).animate().scale(duration: 300.ms),
            if (_isEditing)
              Positioned(
                bottom: 0,
                right: 0,
                child: NeumorphicButton(
                  onPressed: () => _showAvatarOptions(context),
                  padding: const EdgeInsets.all(8),
                  borderRadius: BorderRadius.circular(50),
                  child: const Icon(
                    Icons.camera_alt,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          user?.name ?? 'Guest User',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          user?.metadata['email'] ?? '',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          user?.status ?? 'Hey there! I\'m using PingMe',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildProfileForm(BuildContext context) {
    return NeumorphicContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Profile Information',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _nameController,
            enabled: _isEditing,
            decoration: InputDecoration(
              labelText: 'Name',
              hintText: 'Enter your name',
              prefixIcon: const Icon(Icons.person_outline),
              filled: true,
              fillColor: _isEditing ? null : Colors.grey.withOpacity(0.1),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _emailController,
            enabled: _isEditing,
            decoration: InputDecoration(
              labelText: 'Email',
              hintText: 'Enter your email',
              prefixIcon: const Icon(Icons.email_outlined),
              filled: true,
              fillColor: _isEditing ? null : Colors.grey.withOpacity(0.1),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _statusController,
            enabled: _isEditing,
            decoration: InputDecoration(
              labelText: 'Status',
              hintText: 'What\'s on your mind?',
              prefixIcon: const Icon(Icons.info_outline),
              filled: true,
              fillColor: _isEditing ? null : Colors.grey.withOpacity(0.1),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _bioController,
            enabled: _isEditing,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: 'Bio',
              hintText: 'Tell us about yourself',
              prefixIcon: const Icon(Icons.edit_note),
              filled: true,
              fillColor: _isEditing ? null : Colors.grey.withOpacity(0.1),
            ),
          ),
          if (_isEditing) ...[
            const SizedBox(height: 20),
            Center(
              child: NeumorphicButton(
                onPressed: _saveProfile,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                child: const Text(
                  'Save Changes',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildSettingsSection(BuildContext context) {
    return NeumorphicContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Settings',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildSettingTile(
            context,
            'Dark Mode',
            Icons.dark_mode_outlined,
            Switch(
              value: _isDarkMode,
              onChanged: (value) {
                setState(() => _isDarkMode = value);
                context.read<ProfileService>().setDarkMode(value);
              },
              activeColor: AppTheme.primaryColor,
            ),
          ),
          _buildSettingTile(
            context,
            'Notifications',
            Icons.notifications_outlined,
            Switch(
              value: _notificationsEnabled,
              onChanged: (value) {
                setState(() => _notificationsEnabled = value);
                context.read<ProfileService>().setNotificationsEnabled(value);
              },
              activeColor: AppTheme.primaryColor,
            ),
          ),
          _buildSettingTile(
            context,
            'Read Receipts',
            Icons.done_all,
            Switch(
              value: _readReceipts,
              onChanged: (value) {
                setState(() => _readReceipts = value);
                context.read<ProfileService>().setReadReceiptsEnabled(value);
              },
              activeColor: AppTheme.primaryColor,
            ),
          ),
          _buildSettingTile(
            context,
            'Typing Indicator',
            Icons.keyboard,
            Switch(
              value: _typingIndicator,
              onChanged: (value) {
                setState(() => _typingIndicator = value);
                context.read<ProfileService>().setTypingIndicatorEnabled(value);
              },
              activeColor: AppTheme.primaryColor,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms, delay: 100.ms).slideY(begin: 0.1, end: 0);
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
          _buildAboutTile(context, 'Version', '1.0.0'),
          _buildAboutTile(context, 'Device ID', 
            context.read<ProfileService>().currentUser?.deviceId ?? 'Unknown'),
          _buildAboutTile(context, 'IP Address',
            context.read<ProfileService>().currentUser?.ipAddress ?? 'Not connected'),
          const SizedBox(height: 16),
          Center(
            child: Column(
              children: [
                Text(
                  'PingMe',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Real-time P2P Chat over WiFi',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms, delay: 200.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildSettingTile(BuildContext context, String title, IconData icon, Widget trailing) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primaryColor),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
          trailing,
        ],
      ),
    );
  }

  Widget _buildAboutTile(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey,
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  void _showAvatarOptions(BuildContext context) {
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
              leading: const Icon(Icons.camera_alt, color: AppTheme.primaryColor),
              title: const Text('Take Photo'),
              onTap: () async {
                Navigator.pop(context);
                await _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: AppTheme.primaryColor),
              title: const Text('Choose from Gallery'),
              onTap: () async {
                Navigator.pop(context);
                await _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Remove Photo'),
              onTap: () async {
                Navigator.pop(context);
                await _removeAvatar();
              },
            ),
          ],
        ),
      ),
    );
  }
  
  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(source: source);
      if (image != null) {
        setState(() {
          _localImagePath = image.path;
        });
        
        // Save to shared preferences
        final prefs = await SharedPreferences.getInstance();
        final authService = context.read<AuthService>();
        if (authService.currentUser != null) {
          await prefs.setString('user_avatar_${authService.currentUser!.id}', image.path);
          
          // Broadcast avatar update
          _broadcastProfileUpdate();
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick image: $e')),
      );
    }
  }
  
  Future<void> _removeAvatar() async {
    setState(() {
      _localImagePath = null;
      _avatarUrl = null;
    });
    
    final prefs = await SharedPreferences.getInstance();
    final authService = context.read<AuthService>();
    if (authService.currentUser != null) {
      await prefs.remove('user_avatar_${authService.currentUser!.id}');
      _broadcastProfileUpdate();
    }
  }

  void _saveProfile() async {
    final authService = context.read<AuthService>();
    
    if (!authService.isAuthenticated || authService.currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to update profile')),
      );
      return;
    }
    
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name cannot be empty')),
      );
      return;
    }

    // Update user profile locally
    await authService.updateUserProfile(
      name: _nameController.text.trim(),
      bio: _bioController.text.trim(),
      status: _statusController.text.trim(),
    );
    
    // Update email if changed
    if (_emailController.text.trim().isNotEmpty) {
      authService.currentUser?.metadata['email'] = _emailController.text.trim();
    }
    
    // Broadcast profile update to other devices
    _broadcastProfileUpdate();

    setState(() {
      _isEditing = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Profile updated successfully'),
        backgroundColor: AppTheme.successColor,
      ),
    );
  }
  
  void _broadcastProfileUpdate() {
    // Broadcast profile changes to connected devices
    try {
      final mdnsService = context.read<MDNSDiscoveryService>();
      final authService = context.read<AuthService>();
      
      if (authService.currentUser != null) {
        // Update metadata for discovery
        for (final device in mdnsService.discoveredDevices.values) {
          mdnsService.sendMessage(device.id, {
            'type': 'profile_update',
            'userId': authService.currentUser!.id,
            'name': authService.currentUser!.name,
            'avatarUrl': _avatarUrl ?? '',
            'status': authService.currentUser!.status ?? '',
            'timestamp': DateTime.now().toIso8601String(),
          });
        }
      }
    } catch (e) {
      debugPrint('Failed to broadcast profile update: $e');
    }
  }
}
