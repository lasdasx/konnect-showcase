import 'package:flutter/material.dart';
import 'package:konnect/src/colors.dart';
import 'package:konnect/src/models/userProfile.dart';
import 'package:country_picker/country_picker.dart';
import 'package:konnect/src/screens/onboarding/onBoarding4.dart';
import 'package:konnect/src/screens/onboarding/onBoarding5.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import 'package:konnect/src/widgets/progressAppBar.dart';

class OnBoarding4Screen extends StatefulWidget {
  final ValueChanged<String> onNext;
  final String? url;
  const OnBoarding4Screen({super.key, required this.onNext, this.url});

  @override
  State<OnBoarding4Screen> createState() => _OnBoarding4ScreenState();
}

class _OnBoarding4ScreenState extends State<OnBoarding4Screen> {
  UserProfile userProfile = UserProfile();
  File? _image;

  final ImagePicker _picker = ImagePicker();

  // Function to pick an image from gallery
  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _image = File(image.path);
      });
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.url != null) {
      setState(() {
        _image = File(widget.url!);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(
          top: 100,
          left: 24,
          right: 24,
          bottom: 24,
        ),
        child: Center(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                textAlign: TextAlign.center,
                "My profile pic",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  fontFamily: "RobotoMono",
                ),
              ),
              SizedBox(height: 24),
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  width: 280,
                  height: 280, // Set a fixed height for the container
                  decoration: BoxDecoration(
                    color: Colors.grey[800],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child:
                      _image == null
                          ? Center(
                            child: Icon(
                              Icons.camera_alt,
                              color: Colors.white70,
                              size: 40,
                            ),
                          )
                          : ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(_image!, fit: BoxFit.cover),
                          ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                "Select your best photo and make a good first impression",
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
                    backgroundColor: Colors.blue,
                  ),
                  onPressed: () {
                    if (_image != null) {
                      widget.onNext(_image!.path);
                    }
                  },
                  child: const Text(
                    'Next',
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
