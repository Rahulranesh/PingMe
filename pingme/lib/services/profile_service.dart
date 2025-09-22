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
    _prefs = await SharedPreferences.getInstance();
    await loadProfile();
  }

  Future<void> loadProfile() async {
    if (_prefs == null) await initialize();

    final userJson = _prefs!.getString('user_profile');
    if (userJson != null) {
      try {
        _currentUser = User.fromJson(json.decode(userJson));
        notifyListeners();
      } catch (e) {
        debugPrint('Error loading profile: $e');
      }
    }
  }

  Future<void> createProfile({
    required String name,
    String? bio,
    String? avatarUrl,
    String? status,
  }) async {
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
    if (_currentUser == null || _prefs == null) return;

    await _prefs!.setString(
      'user_profile',
      json.encode(_currentUser!.toJson()),
    );
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

    try {
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        info['deviceId'] = androidInfo.id;
        info['platform'] = 'Android';
        info['model'] = '${androidInfo.manufacturer} ${androidInfo.model}';
        info['osVersion'] = 'Android ${androidInfo.version.release}';
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        info['deviceId'] = iosInfo.identifierForVendor ?? const Uuid().v4();
        info['platform'] = 'iOS';
        info['model'] = iosInfo.model;
        info['osVersion'] = 'iOS ${iosInfo.systemVersion}';
      } else if (Platform.isMacOS) {
        final macInfo = await _deviceInfo.macOsInfo;
        info['deviceId'] = macInfo.systemGUID ?? const Uuid().v4();
        info['platform'] = 'macOS';
        info['model'] = macInfo.model;
        info['osVersion'] = 'macOS ${macInfo.majorVersion}.${macInfo.minorVersion}';
      } else if (Platform.isLinux) {
        final linuxInfo = await _deviceInfo.linuxInfo;
        info['deviceId'] = linuxInfo.machineId ?? const Uuid().v4();
        info['platform'] = 'Linux';
        info['model'] = linuxInfo.name;
        info['osVersion'] = linuxInfo.version ?? 'Unknown';
      } else if (Platform.isWindows) {
        final windowsInfo = await _deviceInfo.windowsInfo;
        info['deviceId'] = windowsInfo.deviceId;
        info['platform'] = 'Windows';
        info['model'] = windowsInfo.productName;
        info['osVersion'] = 'Windows ${windowsInfo.majorVersion}.${windowsInfo.minorVersion}';
      }
    } catch (e) {
      debugPrint('Error getting device info: $e');
      info['deviceId'] = const Uuid().v4();
      info['platform'] = Platform.operatingSystem;
      info['model'] = 'Unknown';
      info['osVersion'] = 'Unknown';
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


  @override
  void dispose() {
    super.dispose();
  }
}
