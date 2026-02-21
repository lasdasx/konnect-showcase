import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:konnect/firebase_options.dart';
import 'package:konnect/src/flutterNotifications.dart';
import 'package:konnect/src/screens/mainScreen.dart';
import 'package:konnect/src/screens/splashScreen.dart';
import 'package:konnect/src/services/api_service.dart';
import 'package:konnect/src/services/auth/authInterceptor.dart';
import 'package:konnect/src/services/auth/authService.dart';

final mainScreenKey = GlobalKey<mainScreenState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await setupNotificationChannel();
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  FirebaseMessaging.onMessageOpenedApp.listen((message) {
    mainScreenKey.currentState?.handleNotificationTap(message.data);
  });
  final authService = AuthService();

  ApiClient.dio.interceptors.add(AuthInterceptor(authService));

  runApp(const ProviderScope(child: MyApp()));

  RemoteMessage? initialMessage =
      await FirebaseMessaging.instance.getInitialMessage();
  if (initialMessage != null) {
    // Delay to ensure mainScreen is built
    Future.delayed(Duration(milliseconds: 500), () {
      mainScreenKey.currentState?.handleNotificationTap(initialMessage.data);
    });
  }
}

// const String devMachineIP =
//     "192.168.1.7"; // Replace with your actual IP address

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      home: SplashScreen(),
      // home: mainScreen(userId: id),
      theme: ThemeData(fontFamily: "RobotoMono"),
    );
  }
}
