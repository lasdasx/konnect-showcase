import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:konnect/src/screens/mainScreen.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> setupNotificationChannel() async {
  const AndroidNotificationChannel highChannel = AndroidNotificationChannel(
    'high_importance_channel', // must match AndroidManifest.xml
    'High Importance Notifications',
    description: 'Used for important notifications',
    importance: Importance.high,
    playSound: true,
    enableVibration: true,
  );
  // Low importance channel
  const AndroidNotificationChannel lowChannel = AndroidNotificationChannel(
    'low_importance_channel', // ID
    'Low Importance Notifications',
    description: 'Used for less important notifications',
    importance: Importance.low,
    playSound: false,
    enableVibration: false,
  );

  final androidImpl = flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();

  await androidImpl?.createNotificationChannel(highChannel);
  await androidImpl?.createNotificationChannel(lowChannel);
}

// Register the handler
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('Handling a background message: ${message.messageId}');
}
