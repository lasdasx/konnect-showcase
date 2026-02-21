import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:konnect/src/colors.dart';
import 'package:konnect/src/screens/onboarding/onBoardingTotal.dart';
import 'package:konnect/src/services/api_service.dart';
import 'package:konnect/src/services/auth/authService.dart';

class EmailVerificationScreen extends StatefulWidget {
  final String email;
  final String password;
  const EmailVerificationScreen({
    Key? key,
    required this.email,
    required this.password,
  }) : super(key: key);

  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  final List<TextEditingController> _controllers = List.generate(
    6,
    (_) => TextEditingController(),
  );

  bool _isLoading = false;
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  @override
  void initState() {
    super.initState();
    _sendVerificationEmail();
  }

  Future<void> _sendVerificationEmail() async {
    await ApiClient.dio.post(
      '/auth/verificationEmail',
      data: {'email': widget.email},
    );
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _onChanged(String value, int index) {
    if (value.length == 1 && index < 5) {
      _focusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Verify your email',
              style: TextStyle(
                color: AppColors.textColor,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'A 6-digit verification code, valid for 1 hour, has been sent to your email.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textColor.withOpacity(0.7),
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(
                6,
                (index) => SizedBox(
                  width: 50,
                  child: TextField(
                    controller: _controllers[index],
                    focusNode: _focusNodes[index],
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    maxLength: 1,
                    style: const TextStyle(
                      color: AppColors.textColor,
                      fontSize: 24,
                    ),
                    cursorColor: AppColors.selectedTabColor,

                    decoration: InputDecoration(
                      counterText: '',
                      filled: true,
                      fillColor: AppColors.secondaryColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (value) => _onChanged(value, index),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.onboardingButton,
                padding: const EdgeInsets.symmetric(
                  horizontal: 48,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: _isLoading
                  ? null
                  : () async {
                      setState(() {
                        _isLoading = true;
                      });
                      try {
                        final code = _controllers
                            .map((controller) => controller.text)
                            .join();
                        // Handle verification submission here
                        print('Entered code: $code');
                        if (code.length != 6) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please enter a 6-digit code'),
                            ),
                          );
                          return;
                        }

                        final res = await ApiClient.dio.post(
                          '/auth/login',
                          data: {
                            'email': widget.email,
                            'password': widget.password,
                            'passcode': code,
                          },
                        );
                        if (res.statusCode == 200) {
                          final accessToken = res.data['token'];
                          final refreshToken = res.data['refresh_token'];
                          AuthService().saveTokens(accessToken, refreshToken);
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const OnboardingFlow(),
                            ),
                          );
                          // final uid = res.data['user']['id'];
                        }
                      } on DioException catch (e) {
                        //show snackbar and restart text controller
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(e.response!.data['error'])),
                        );
                        for (var controller in _controllers) {
                          controller.clear();
                        }
                        _focusNodes.first.requestFocus();
                      }
                    },
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : const Text(
                      'Verify',
                      style: TextStyle(fontSize: 18, color: Colors.black),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
