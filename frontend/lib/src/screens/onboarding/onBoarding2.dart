import 'package:flutter/material.dart';
import 'package:konnect/src/colors.dart';
import 'package:konnect/src/screens/onboarding/onBoarding2.dart';
import 'package:konnect/src/screens/onboarding/onBoarding3.dart';

class OnBoarding2Screen extends StatefulWidget {
  final ValueChanged<DateTime> onNext;
  final DateTime? birthday;

  const OnBoarding2Screen({super.key, required this.onNext, this.birthday});

  @override
  State<OnBoarding2Screen> createState() => _OnBoarding2ScreenState();
}

class _OnBoarding2ScreenState extends State<OnBoarding2Screen> {
  DateTime? selectedDate;

  @override
  void initState() {
    super.initState();
    if (widget.birthday != null) {
      selectedDate = widget.birthday;
    }
  }

  void _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: Colors.blue,
              surface: Colors.grey[900]!,
              onSurface: Colors.white,
            ),
            dialogBackgroundColor: Colors.grey[850],
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

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
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(
          top: 200,
          left: 24,
          right: 24,
          bottom: 24,
        ),
        child: Center(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                "My birthday is",

                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  fontFamily: "RobotoMono",
                ),
              ),
              SizedBox(height: 24),
              GestureDetector(
                onTap: _pickDate,
                child: Container(
                  width: 280,
                  padding: EdgeInsets.symmetric(vertical: 18),
                  decoration: BoxDecoration(
                    color: Colors.grey[800],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    selectedDate != null
                        ? "${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}"
                        : "Select your birthday",
                    style: TextStyle(
                      color:
                          selectedDate != null ? Colors.white : Colors.white70,
                      fontSize: 18,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                "Your birthday helps us \n personalize your experience.",
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
                    backgroundColor: Colors.blue, // Dark theme button color
                  ),
                  onPressed: () {
                    if (selectedDate != null) {
                      widget.onNext(selectedDate!);
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
