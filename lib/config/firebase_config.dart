import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class FirebaseConfig {
  static const firebaseConfig = {
    'apiKey': 'your-api-key',
    'authDomain': 'your-project.firebaseapp.com',
    'projectId': 'your-project-id',
    'storageBucket': 'your-project.appspot.com',
    'messagingSenderId': 'your-sender-id',
    'appId': 'your-app-id',
  };

  static Future<void> initializeFirebase() async {
    await Firebase.initializeApp();
    
    // Initialize Firebase Messaging
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    
    // Request permission for notifications
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted permission');
    } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
      print('User granted provisional permission');
    } else {
      print('User declined or has not accepted permission');
    }
  }

  static Future<String?> getFirebaseToken() async {
    try {
      FirebaseMessaging messaging = FirebaseMessaging.instance;
      String? token = await messaging.getToken();
      return token;
    } catch (e) {
      print('Error getting Firebase token: $e');
      return null;
    }
  }
}