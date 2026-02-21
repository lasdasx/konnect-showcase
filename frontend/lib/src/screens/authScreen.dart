import 'dart:io';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:konnect/src/colors.dart';
import 'package:konnect/src/screens/emailVerification.dart';
import 'package:konnect/src/screens/mainScreen.dart';
import 'package:konnect/src/screens/onboarding/onBoardingTotal.dart';
import 'package:konnect/src/services/api_service.dart';
import 'package:konnect/src/services/auth/authService.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:konnect/src/utils/utils.dart';

bool isPasswordStrong(String password) {
  final regex = RegExp(r'^(?=.*[A-Z])(?=.*[0-9])(?=.*[!@#\$&*~]).{8,}$');
  return regex.hasMatch(password);
}

String? validatePassword(String password) {
  if (password.length < 8) {
    return 'Password must be at least 8 characters long';
  }
  if (!RegExp(r'[A-Z]').hasMatch(password)) {
    return 'Password must contain at least one uppercase letter';
  }
  if (!RegExp(r'[0-9]').hasMatch(password)) {
    return 'Password must contain at least one number';
  }
  if (!RegExp(r'[!@#\$&*~]').hasMatch(password)) {
    return 'Password must contain at least one special character (!@#\$&*~)';
  }
  return null; // all good
}

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final _nameController = TextEditingController();
  bool isLogin = true;
  bool isLoading = false;

  final authentication = AuthService();

  void _submitAuthForm() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    final name = _nameController.text.trim();

    if (!isLogin) {
      // Check passwords match
      if (_passwordController.text != _confirmPasswordController.text) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Passwords do not match')));
        return;
      }

      // Check password strength
      final passwordError = validatePassword(_passwordController.text);
      if (passwordError != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(passwordError)));
        return;
      }
    }

    setState(() => isLoading = true);

    try {
      if (isLogin) {
        final res = await ApiClient.dio.post(
          '/auth/login',
          data: {'email': email, 'password': password},
        );

        final accessToken = res.data['token'];
        final refreshToken = res.data['refresh_token'];
        // final uid = res.data['user']['id'];

        AuthService().saveTokens(accessToken, refreshToken);
        print("AAAA");
        final fcmToken = await FirebaseMessaging.instance.getToken();
        print("FCM TOKEN $fcmToken");
        if (fcmToken != null) {
          print("BBB");
          await ApiClient.dio.post(
            '/register-device-token',
            data: {
              'device_token': fcmToken,
              'device_id': await getDeviceId(), // optional: "android" or "ios"
            },
          );
          print("CCCC");
        }
        FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
          await ApiClient.dio.post(
            '/register-device-token',
            data: {'device_token': newToken, "device_id": getDeviceId()},
          );
        });
        print("DDDD");

        // Check if the user has completed onboarding
        final onboarded = res.data['user']['onboarded'] ?? false;

        if (onboarded) {
          // If onboarded, navigate to the Home screen
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => mainScreen()),
          );
        } else {
          // If not onboarded, navigate to the Onboarding screen
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const OnboardingFlow()),
          );
        }
      } else {
        // Register the user

        final res = await ApiClient.dio.post(
          '/auth/register',
          data: {'email': email, 'password': password},
        );

        // AuthService().saveTokens(accessToken, refreshToken);

        // After registration, navigate to Onboarding screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder:
                (context) =>
                    EmailVerificationScreen(email: email, password: password),
          ),
        );
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 412) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder:
                (context) =>
                    EmailVerificationScreen(email: email, password: password),
          ),
        );
        return;
      }
      // Safely extract the error message
      String errorMsg = e.message ?? "An error occurred";

      if (e.response?.data != null && e.response?.data is Map) {
        // Explicitly cast to Map so Dart knows 'error' is a String key, not an int index
        final data = e.response!.data as Map<String, dynamic>;
        errorMsg = data['error'] ?? errorMsg;
      }

      print("Error from server: $errorMsg");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(errorMsg)));
    } catch (e) {
      // Fallback for other exceptions
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unexpected error: ${e.toString()}')),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight, // fill the screen
                ),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Branding area
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 24,
                        ),
                        child: Column(
                          children: [
                            const SizedBox(height: 60),
                            const Icon(
                              Icons.public,
                              size: 80,
                              color: AppColors.selectedTabColor,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              "Konnect",
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              "Make connections across borders",
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 16,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),

                      // Push the form to the bottom
                      Expanded(child: Container()),

                      // Form area
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.fromLTRB(
                          24,
                          24,
                          24,
                          MediaQuery.of(context).viewInsets.bottom + 24,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.secondaryColor,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(32),
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              isLogin ? "Welcome Back" : "Create an Account",
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textColor,
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Email
                            TextField(
                              controller: _emailController,
                              style: const TextStyle(
                                color: AppColors.textColor,
                              ),
                              decoration: InputDecoration(
                                labelText: 'Email',
                                labelStyle: const TextStyle(
                                  color: Colors.white70,
                                ),
                                prefixIcon: const Icon(
                                  Icons.email,
                                  color: Colors.white70,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderSide: const BorderSide(
                                    color: Colors.white24,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: const BorderSide(
                                    color: AppColors.selectedTabColor,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Password
                            TextField(
                              controller: _passwordController,
                              obscureText: true,
                              style: const TextStyle(
                                color: AppColors.textColor,
                              ),
                              decoration: InputDecoration(
                                labelText: 'Password',
                                labelStyle: const TextStyle(
                                  color: Colors.white70,
                                ),
                                prefixIcon: const Icon(
                                  Icons.lock,
                                  color: Colors.white70,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderSide: const BorderSide(
                                    color: Colors.white24,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: const BorderSide(
                                    color: AppColors.selectedTabColor,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),

                            if (!isLogin) ...[
                              const SizedBox(height: 12),
                              TextField(
                                controller: _confirmPasswordController,
                                obscureText: true,
                                style: const TextStyle(
                                  color: AppColors.textColor,
                                ),
                                decoration: InputDecoration(
                                  labelText: 'Confirm Password',
                                  labelStyle: const TextStyle(
                                    color: Colors.white70,
                                  ),
                                  prefixIcon: const Icon(
                                    Icons.lock,
                                    color: Colors.white70,
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderSide: const BorderSide(
                                      color: Colors.white24,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: const BorderSide(
                                      color: AppColors.selectedTabColor,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ],
                            const SizedBox(height: 16),

                            // Submit button
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton(
                                onPressed: isLoading ? null : _submitAuthForm,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.selectedTabColor,
                                  foregroundColor: Colors.black,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child:
                                    isLoading
                                        ? const SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(
                                            color: Colors.black,
                                            strokeWidth: 2,
                                          ),
                                        )
                                        : Text(
                                          isLogin ? 'Login' : 'Register',
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Switch login/register
                            TextButton(
                              onPressed:
                                  () => setState(() => isLogin = !isLogin),
                              child: Text(
                                isLogin
                                    ? "Don't have an account? Register"
                                    : "Already have an account? Login",
                                style: const TextStyle(color: Colors.white70),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
