import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/message.dart' as app_models;
import '../models/user.dart';
import '../models/device.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;
  Function(String?)? _onNotificationTap;
  bool _notificationsEnabled = true;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  BuildContext? _context;

  Future<void> initialize({Function(String?)? onNotificationTap, BuildContext? context}) async {
    if (_isInitialized) return;
    
    _onNotificationTap = onNotificationTap;
    _context = context;
    
    // Load notification preferences
    final prefs = await SharedPreferences.getInstance();
    _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
    _soundEnabled = prefs.getBool('sound_notifications') ?? true;
    _vibrationEnabled = prefs.getBool('vibration_notifications') ?? true;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
      onDidReceiveBackgroundNotificationResponse: _backgroundNotificationResponse,
    );

    _isInitialized = true;
    
    // Request permissions for Android 13+
    if (Platform.isAndroid) {
      await _notifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()?.requestNotificationsPermission();
    }
  }
  
  @pragma('vm:entry-point')
  static void _backgroundNotificationResponse(NotificationResponse response) {
    // Handle notification tap when app is terminated
    if (response.payload != null) {
      // Store the payload to be processed when app starts
      SharedPreferences.getInstance().then((prefs) {
        prefs.setString('pending_notification_payload', response.payload!);
      });
    }
  }

  void _onNotificationResponse(NotificationResponse response) {
    if (_onNotificationTap != null && response.payload != null) {
      _onNotificationTap!(response.payload);
    }
  }

  Future<void> showMessageNotification({
    required app_models.Message message,
    required User sender,
    String? conversationId,
  }) async {
    if (!_isInitialized) await initialize();
    
    // Check if notifications are enabled
    if (!_notificationsEnabled) return;
    
    // Check if app is in foreground
    final appState = WidgetsBinding.instance.lifecycleState;
    final isInForeground = appState == AppLifecycleState.resumed;
    
    if (isInForeground) {
      // Show in-app notification banner
      _showInAppNotification(message, sender);
      return;
    }

    // Configure notification based on settings
    final androidDetails = AndroidNotificationDetails(
      'messages',
      'Messages',
      channelDescription: 'Notifications for incoming messages',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      enableVibration: _vibrationEnabled,
      playSound: _soundEnabled,
      sound: _soundEnabled ? const RawResourceAndroidNotificationSound('notification') : null,
    );

    final iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: _soundEnabled,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    String title = sender.name;
    String body = message.content;

    if (message.type != app_models.MessageType.text) {
      switch (message.type) {
        case app_models.MessageType.image:
          body = '📷 Sent an image';
          break;
        case app_models.MessageType.video:
          body = '🎥 Sent a video';
          break;
        case app_models.MessageType.audio:
          body = '🎵 Sent an audio';
          break;
        case app_models.MessageType.file:
          body = '📎 Sent a file';
          break;
        case app_models.MessageType.location:
          body = '📍 Shared location';
          break;
        case app_models.MessageType.contact:
          body = '👤 Shared a contact';
          break;
        default:
          break;
      }
    }

    await _notifications.show(
      message.id.hashCode,
      title,
      body,
      details,
      payload: conversationId ?? message.chatId,
    );
  }
  
  void _showInAppNotification(app_models.Message message, User sender) {
    if (_context == null) return;
    
    final scaffoldMessenger = ScaffoldMessenger.of(_context!);
    scaffoldMessenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            CircleAvatar(
              radius: 16,
              child: Text(sender.name[0].toUpperCase()),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    sender.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    message.content,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'View',
          onPressed: () {
            if (_onNotificationTap != null) {
              _onNotificationTap!(message.chatId);
            }
          },
        ),
      ),
    );
    
    // Play sound if enabled
    if (_soundEnabled) {
      // In a real app, you would play a notification sound here
    }
  }

  Future<void> showDeviceNotification({
    required String deviceName,
    required String message,
    String? deviceId,
  }) async {
    if (!_isInitialized) await initialize();
    if (!_notificationsEnabled) return;

    const androidDetails = AndroidNotificationDetails(
      'discovery',
      'Device Discovery',
      channelDescription: 'Notifications for discovered devices',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      showWhen: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: false,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      deviceId.hashCode,
      'New Device Found',
      '$deviceName is available for chat',
      details,
      payload: deviceId,
    );
  }

  Future<void> showConnectionNotification({
    required String userName,
    required String userId,
    required bool isConnected,
  }) async {
    if (!_isInitialized) await initialize();

    const androidDetails = AndroidNotificationDetails(
      'connection',
      'Connection Status',
      channelDescription: 'Notifications for connection status',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      showWhen: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: false,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      userId.hashCode,
      isConnected ? 'Connected' : 'Disconnected',
      isConnected 
        ? '$userName is now connected'
        : '$userName has disconnected',
      details,
      payload: userId,
    );
  }

  Future<void> showFileTransferNotification({
    required String fileName,
    required String senderName,
    required int notificationId,
    required int progress,
    required bool isComplete,
  }) async {
    if (!_isInitialized) await initialize();

    final androidDetails = AndroidNotificationDetails(
      'file_transfer',
      'File Transfer',
      channelDescription: 'Notifications for file transfers',
      importance: Importance.low,
      priority: Priority.low,
      onlyAlertOnce: true,
      showProgress: !isComplete,
      maxProgress: 100,
      progress: progress,
      ongoing: !isComplete,
      autoCancel: isComplete,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: false,
      presentSound: false,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      notificationId,
      isComplete ? 'File Received' : 'Receiving File',
      isComplete 
        ? '$fileName from $senderName'
        : '$fileName from $senderName ($progress%)',
      details,
    );
  }

  Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
  }

  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  Future<void> updateBadgeCount(int count) async {
    // iOS specific badge count
    if (Platform.isIOS) {
      // Implementation would require iOS specific code
      debugPrint('Badge count updated to: $count');
    }
  }
}
