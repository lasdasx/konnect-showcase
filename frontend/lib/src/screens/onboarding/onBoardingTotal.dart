import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cross_file/cross_file.dart';
import 'package:dio/dio.dart';

import 'package:flutter/material.dart';
import 'package:konnect/src/colors.dart';
import 'package:konnect/src/models/userProfile.dart';
import 'package:konnect/src/screens/mainScreen.dart';
import 'package:konnect/src/screens/onboarding/onBoarding1.dart';
import 'package:konnect/src/screens/onboarding/onBoarding2.dart';
import 'package:konnect/src/screens/onboarding/onBoarding3.dart';
import 'package:konnect/src/screens/onboarding/onBoarding4.dart';
import 'package:konnect/src/screens/onboarding/onBoarding5.dart';
import 'package:konnect/src/screens/onboarding/onBoarding6.dart';
import 'package:konnect/src/screens/onboarding/onBoarding7.dart';
import 'package:konnect/src/services/api_service.dart';
import 'package:konnect/src/utils/utils.dart';
import 'package:konnect/src/widgets/progressAppBar.dart';

class OnboardingFlow extends StatefulWidget {
  const OnboardingFlow({super.key});

  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  UserProfile userProfile = UserProfile();

  void _nextPage() {
    if (_currentPage < 6) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.ease,
      );
    } else {
      _finishSignup();
    }
  }

  void _finishSignup() async {
    try {
      List<String> supportImages = userProfile.photoUrls;
      String profileImagePath = userProfile.profileImagePath!;

      print("Profile Image Path: $profileImagePath");
      print("Support Images: $supportImages");

      final profileUploadFuture = uploadProfileImage(XFile(profileImagePath));
      final supportUploadFutures =
          supportImages
              .map((path) async => await uploadSupportImage(XFile(path)))
              .toList();

      final results = await Future.wait([
        profileUploadFuture,
        ...supportUploadFutures,
      ]);

      userProfile.profileImagePath = results[0];
      userProfile.photoUrls = results.sublist(1);

      print("the profile is " + userProfile.toMap().toString());
      await ApiClient.dio.patch('/user', data: userProfile.toMap());

      print("Signup complete: ${userProfile.name}, ${userProfile.birthday}");

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => mainScreen()),
      );
    } on DioException catch (e) {
      final message =
          e.response?.data is Map
              ? e.response?.data['error'] ?? 'Something went wrong'
              : e.message ?? 'Network error';

      print('Dio error: $message');

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.ease,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _currentPage == 0,
      onPopInvokedWithResult: (bool didPop, Object? result) async {
        if (_currentPage > 0) {
          // Navigate to the previous page in the PageView
          _previousPage();
          return; // Prevent default back navigation
        }
        return; // Allow default back navigation (exit the screen)
      },
      child: Scaffold(
        backgroundColor: AppColors.backgroundColor,
        appBar: ProgressAppBar(
          value: (_currentPage + 1) / 7,
        ), // Example with 4 pages
        body: PageView(
          controller: _pageController,
          physics:
              const NeverScrollableScrollPhysics(), // Disable manual swiping
          onPageChanged: (index) {
            setState(() {
              _currentPage = index;
            });
          },
          children: [
            OnBoarding1Screen(
              name: userProfile.name,
              onNext: (name) {
                userProfile.name = name;
                _nextPage();
              },
            ),
            OnBoarding2Screen(
              birthday: userProfile.birthday,
              onNext: (birthday) {
                userProfile.birthday = birthday;
                _nextPage();
              },
            ),
            OnBoarding3Screen(
              country: userProfile.country,
              onNext: (country) {
                userProfile.country = country;
                _nextPage();
              },
            ),
            OnBoarding4Screen(
              url: userProfile.profileImagePath,
              onNext: (url) {
                print(url);
                userProfile.profileImagePath = url;
                _nextPage();
              },
            ),
            OnBoarding5Screen(
              imagePaths: userProfile.photoUrls,
              onNext: (urls) {
                userProfile.photoUrls = urls;
                _nextPage();
              },
            ),
            OnBoarding6Screen(
              bio: userProfile.bio,
              onNext: (bio) {
                userProfile.bio = bio;
                _nextPage();
              },
            ),
            OnBoarding7Screen(
              onNext: (record) {
                final gender = record;
                userProfile.gender = gender;
                _nextPage();
              },
            ),
          ],
        ),
      ),
    );
  }
}
