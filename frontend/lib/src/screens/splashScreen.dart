import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:konnect/main.dart';
import 'package:konnect/src/colors.dart';
import 'package:konnect/src/services/api_service.dart';
import 'package:konnect/src/services/auth/authService.dart';
import 'package:konnect/src/utils/utils.dart';

import '../screens/authScreen.dart';
import '../screens/mainScreen.dart';
import '../screens/onboarding/onBoardingTotal.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _checkUserAuthentication();
  }

  Future<void> _checkUserAuthentication() async {
    final token = await _authService.accessToken;

    if (token == null) {
      // No token → go to login
      _goToAuth();
      return;
    }

    try {
      // Attempt to fetch user info
      final res = await ApiClient.dio.get('/user/me');
      final data = res.data;

      final onboarded = data['onboarded'] ?? false;

      if (onboarded) {
        _goToApp();
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const OnboardingFlow()),
        );
      }
    } on Exception catch (_) {
      // Token invalid, refresh failed, or network error → go to login
      _goToAuth();
    }
  }

  void _goToApp() {
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
      await ApiClient.dio.post(
        '/register-device-token',
        data: {'device_token': newToken, "device_id": getDeviceId()},
      );
    });
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => mainScreen(key: mainScreenKey)),
    );
  }

  void _goToAuth() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const AuthScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(
          backgroundColor: AppColors.backgroundColor,
        ),
      ),
    );
  }
}
