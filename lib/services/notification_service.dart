import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:audioplayers/audioplayers.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  static final AudioPlayer _audioPlayer = AudioPlayer();

  static Future<void> initialize() async {
    // Initialize local notifications
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(settings);

    // Initialize Firebase Messaging
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    
    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    
    // Handle notification taps
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);
  }

  static Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
    await showNotification(
      title: message.notification?.title ?? 'New Notification',
      body: message.notification?.body ?? '',
      payload: message.data.toString(),
    );
  }

  static Future<void> _handleForegroundMessage(RemoteMessage message) async {
    await showNotification(
      title: message.notification?.title ?? 'New Notification',
      body: message.notification?.body ?? '',
      payload: message.data.toString(),
    );
    
    // Play notification sound
    await _playNotificationSound();
  }

  static Future<void> _handleNotificationTap(RemoteMessage message) async {
    // Handle notification tap - navigate to specific screen if needed
    print('Notification tapped: ${message.data}');
  }

  static Future<void> showNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'criminal_tracking_channel',
      'Criminal Tracking Notifications',
      channelDescription: 'Notifications for criminal tracking system',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      details,
      payload: payload,
    );
  }

  static Future<void> _playNotificationSound() async {
    try {
      // You can add a custom notification sound file in assets/sounds/
      // await _audioPlayer.play(AssetSource('sounds/notification.mp3'));
      
      // For now, we'll use the system notification sound
      print('Playing notification sound');
    } catch (e) {
      print('Error playing notification sound: $e');
    }
  }

  static Future<String?> getDeviceToken() async {
    try {
      return await FirebaseMessaging.instance.getToken();
    } catch (e) {
      print('Error getting device token: $e');
      return null;
    }
  }
}