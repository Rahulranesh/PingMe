import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:uuid/uuid.dart';
import '../models/user.dart';

class ProfileService extends ChangeNotifier {
  static final ProfileService _instance = ProfileService._internal();
  factory ProfileService() => _instance;
  ProfileService._internal();

  User? _currentUser;
  SharedPreferences? _prefs;
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  User? get currentUser => _currentUser;
  bool get isProfileSetup => _currentUser != null;

  Future<void> initialize() async {
    debugPrint('🔧 ProfileService: Initializing...');
    _prefs = await SharedPreferences.getInstance();
    await loadProfile();
    debugPrint('🔧 ProfileService: Initialization complete. Current user: ${_currentUser?.name} (${_currentUser?.id})');
  }

  Future<void> loadProfile() async {
    if (_prefs == null) await initialize();

    final userJson = _prefs!.getString('user_profile');
    debugPrint('🔧 ProfileService: Loading profile from storage...');
    
    if (userJson != null) {
      try {
        _currentUser = User.fromJson(json.decode(userJson));
        debugPrint('✅ ProfileService: Profile loaded successfully: ${_currentUser?.name} (${_currentUser?.id})');
        notifyListeners();
      } catch (e) {
        debugPrint('❌ ProfileService: Error loading profile: $e');
      }
    } else {
      debugPrint('⚠️ ProfileService: No saved profile found in storage');
    }
  }

  Future<void> createProfile({
    required String name,
    String? bio,
    String? avatarUrl,
    String? status,
  }) async {
    debugPrint('🔧 ProfileService: Creating new profile for $name...');
    if (_prefs == null) await initialize();

    final deviceInfo = await _getDeviceInfo();
    
    _currentUser = User(
      id: const Uuid().v4(),
      name: name,
      bio: bio,
      avatarUrl: avatarUrl,
      deviceId: deviceInfo['deviceId'] ?? const Uuid().v4(),
      ipAddress: '0.0.0.0', // Will be updated by discovery service
      port: 8889,
      status: status ?? 'Hey there! I\'m using PingMe',
      metadata: {
        'platform': deviceInfo['platform'],
        'model': deviceInfo['model'],
        'osVersion': deviceInfo['osVersion'],
      },
    );

    debugPrint('✅ ProfileService: Profile created with ID: ${_currentUser?.id}');
    await saveProfile();
    notifyListeners();
  }

  Future<void> updateProfile({
    String? name,
    String? bio,
    String? avatarUrl,
    String? status,
  }) async {
    if (_currentUser == null) return;

    _currentUser = _currentUser!.copyWith(
      name: name,
      bio: bio,
      avatarUrl: avatarUrl,
      status: status,
    );

    await saveProfile();
    notifyListeners();
  }

  Future<void> saveProfile() async {
    if (_currentUser == null || _prefs == null) {
      debugPrint('⚠️ ProfileService: Cannot save profile - user or prefs is null');
      return;
    }

    try {
      final jsonString = json.encode(_currentUser!.toJson());
      await _prefs!.setString('user_profile', jsonString);
      debugPrint('✅ ProfileService: Profile saved to storage for ${_currentUser?.name} (${_currentUser?.id})');
    } catch (e) {
      debugPrint('❌ ProfileService: Error saving profile: $e');
    }
  }

  Future<void> updateOnlineStatus(bool isOnline) async {
    if (_currentUser == null) return;

    _currentUser!.isOnline = isOnline;
    _currentUser!.lastSeen = DateTime.now();
    
    await saveProfile();
    notifyListeners();
  }

  Future<void> updateIpAddress(String ipAddress) async {
    if (_currentUser == null) return;

    _currentUser!.ipAddress = ipAddress;
    await saveProfile();
    notifyListeners();
  }

  Future<Map<String, String>> _getDeviceInfo() async {
    final info = <String, String>{};
    
    // Run device info collection in parallel with timeout
    try {
      final futures = <Future<void>>[];
      
      if (Platform.isAndroid) {
        futures.add(() async {
          final androidInfo = await _deviceInfo.androidInfo.timeout(const Duration(seconds: 2));
          info.addAll({
            'deviceId': androidInfo.id,
            'platform': 'Android',
            'model': '${androidInfo.manufacturer} ${androidInfo.model}',
            'osVersion': 'Android ${androidInfo.version.release}',
          });
        }());
      } else if (Platform.isIOS) {
        futures.add(() async {
          final iosInfo = await _deviceInfo.iosInfo.timeout(const Duration(seconds: 2));
          info.addAll({
            'deviceId': iosInfo.identifierForVendor ?? const Uuid().v4(),
            'platform': 'iOS',
            'model': iosInfo.model,
            'osVersion': 'iOS ${iosInfo.systemVersion}',
          });
        }());
      } else {
        // For other platforms, use fallback immediately
        info.addAll({
          'deviceId': const Uuid().v4(),
          'platform': Platform.operatingSystem,
          'model': 'Unknown',
          'osVersion': 'Unknown',
        });
      }
      
      // Wait for platform-specific operations with timeout
      await Future.wait(futures, eagerError: true).timeout(const Duration(seconds: 3));
      
    } catch (e) {
      debugPrint('Device info timeout: $e');
      // Use fallback values
      info.addAll({
        'deviceId': const Uuid().v4(),
        'platform': Platform.operatingSystem,
        'model': 'Unknown',
        'osVersion': 'Unknown',
      });
    }
    
    return info;
  }

  Future<void> clearProfile() async {
    if (_prefs == null) return;
    
    await _prefs!.remove('user_profile');
    _currentUser = null;
    notifyListeners();
  }

  // Settings management
  Future<bool> getSettingBool(String key, {bool defaultValue = false}) async {
    if (_prefs == null) await initialize();
    return _prefs!.getBool(key) ?? defaultValue;
  }

  Future<void> setSettingBool(String key, bool value) async {
    if (_prefs == null) await initialize();
    await _prefs!.setBool(key, value);
    notifyListeners();
  }

  Future<String?> getSettingString(String key) async {
    if (_prefs == null) await initialize();
    return _prefs!.getString(key);
  }

  Future<void> setSettingString(String key, String value) async {
    if (_prefs == null) await initialize();
    await _prefs!.setString(key, value);
    notifyListeners();
  }

  // Theme preference
  Future<bool> isDarkMode() async {
    return await getSettingBool('dark_mode', defaultValue: false);
  }

  Future<void> setDarkMode(bool value) async {
    await setSettingBool('dark_mode', value);
  }

  // Notification preferences
  Future<bool> areNotificationsEnabled() async {
    return await getSettingBool('notifications_enabled', defaultValue: true);
  }

  Future<void> setNotificationsEnabled(bool value) async {
    await setSettingBool('notifications_enabled', value);
  }

  Future<bool> areSoundNotificationsEnabled() async {
    return await getSettingBool('sound_notifications', defaultValue: true);
  }

  Future<void> setSoundNotificationsEnabled(bool value) async {
    await setSettingBool('sound_notifications', value);
  }

  Future<bool> areVibrationNotificationsEnabled() async {
    return await getSettingBool('vibration_notifications', defaultValue: true);
  }

  Future<void> setVibrationNotificationsEnabled(bool value) async {
    await setSettingBool('vibration_notifications', value);
  }

  // Privacy settings
  Future<bool> isReadReceiptsEnabled() async {
    return await getSettingBool('read_receipts', defaultValue: true);
  }

  Future<void> setReadReceiptsEnabled(bool value) async {
    await setSettingBool('read_receipts', value);
  }

  Future<bool> isTypingIndicatorEnabled() async {
    return _prefs?.getBool('typing_indicator_enabled') ?? true;
  }

  Future<void> setTypingIndicatorEnabled(bool value) async {
    await setSettingBool('typing_indicator', value);
  }

  Future<bool> isLastSeenEnabled() async {
    return await getSettingBool('last_seen', defaultValue: true);
  }

  Future<void> setLastSeenEnabled(bool value) async {
    await setSettingBool('last_seen', value);
  }


}
