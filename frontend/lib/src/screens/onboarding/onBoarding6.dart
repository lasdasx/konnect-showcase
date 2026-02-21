import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class OnBoarding6Screen extends StatefulWidget {
  final String? bio;
  final ValueChanged<String> onNext;
  OnBoarding6Screen({required this.bio, required this.onNext});

  @override
  State<StatefulWidget> createState() => _OnBoarding6State();
}

class _OnBoarding6State extends State<OnBoarding6Screen> {
  final TextEditingController _bioController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _bioController.text = widget.bio ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(
          top: 20,
          left: 24,
          right: 24,
          bottom: 24.0,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: 80),
              Text(
                textAlign: TextAlign.center,
                "About me...",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16),

              // Display the selected images in a GridView
              TextField(
                controller: _bioController,
                maxLines: null,
                maxLength: 500,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText:
                      "E.g. Coffee lover from Brazil who dances salsa on weekends.",
                  hintStyle: const TextStyle(color: Colors.white70),
                  filled: true,
                  fillColor: Colors.white12,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              SizedBox(height: 60),
              Text(
                textAlign: TextAlign.center,
                "Speak about yourself",
                style: TextStyle(
                  color: Colors.grey[400],
                  // fontSize: 20,
                  fontWeight: FontWeight.bold,
                  fontFamily: "RobotoMono",
                ),
              ),
              const SizedBox(height: 16),

              const SizedBox(height: 100),

              SizedBox(
                width: 120,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    backgroundColor: Colors.blue, // Dark theme button color
                  ),
                  onPressed: () {
                    widget.onNext(_bioController.text);
                    // You can navigate to another screen or perform an action here
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
