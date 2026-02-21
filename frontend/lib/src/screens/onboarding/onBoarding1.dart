import 'package:flutter/material.dart';
import 'package:konnect/src/colors.dart';
import 'package:konnect/src/models/userProfile.dart';

class OnBoarding1Screen extends StatefulWidget {
  final ValueChanged<String> onNext;
  final String? name;

  const OnBoarding1Screen({super.key, required this.onNext, this.name});

  @override
  State<OnBoarding1Screen> createState() => _OnBoarding1ScreenState();
}

class _OnBoarding1ScreenState extends State<OnBoarding1Screen> {
  final _nameController = TextEditingController();

  UserProfile userProfile = UserProfile();

  InputDecoration _inputDecoration() {
    return InputDecoration(
      filled: true,
      fillColor: Colors.grey[800], // Dark background color
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    // Initialize the controller with the passed initial name, if any
    if (widget.name != null) {
      _nameController.text = widget.name!;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.only(
            top: 200,
            left: 24,
            right: 24,
            bottom: 24,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                "My first name is",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  fontFamily: "RobotoMono",
                ),
              ),
              SizedBox(height: 24),
              TextField(
                maxLength: 15,
                textAlign: TextAlign.center,
                controller: _nameController,
                cursorColor: Colors.white70,
                decoration: _inputDecoration(),
                style: TextStyle(
                  color: Colors.white,
                ), // White text for dark mode
              ),
              const SizedBox(height: 16),
              Text(
                "This is how you will appear on others. \n You won't be able to change it",
                style: TextStyle(color: Colors.grey[400]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 60),

              SizedBox(
                width: 120,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    backgroundColor:
                        AppColors.onboardingButton, // Dark theme button color
                  ),
                  onPressed: () {
                    if (_nameController.text.trim().isNotEmpty) {
                      widget.onNext(_nameController.text.trim());
                    }
                  },
                  child: const Text(
                    'Next',
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ), // White text on button
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
