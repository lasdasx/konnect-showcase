import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class OnBoarding7Screen extends StatefulWidget {
  final ValueChanged<String> onNext;
  OnBoarding7Screen({super.key, required this.onNext});

  @override
  State<StatefulWidget> createState() => _OnBoarding7State();
}

class _OnBoarding7State extends State<OnBoarding7Screen> {
  bool _isLoading = false;

  String? _selectedGender;
  // final List<String> _preferredGenders = [];

  final List<String> _genders = ['Male', 'Female'];

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "I am",
              style: TextStyle(
                fontSize: 28,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ..._genders.map(
              (gender) => RadioListTile<String>(
                title: Text(gender, style: TextStyle(color: Colors.white)),
                value: gender,
                groupValue: _selectedGender,
                onChanged: (value) {
                  setState(() {
                    _selectedGender = value;
                  });
                },
                activeColor: Colors.blue,
              ),
            ),
            const SizedBox(height: 32),

            const SizedBox(height: 16),

            const SizedBox(height: 40),
            Center(
              child: SizedBox(
                width: 140,
                child: ElevatedButton(
                  onPressed: () async {
                    if (_selectedGender == null || _isLoading) return;

                    setState(() => _isLoading = true);

                    try {
                      widget.onNext(_selectedGender!);
                    } catch (error) {
                      print('Error calling function: $error');
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    backgroundColor: Colors.green,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Text(
                          "Complete",
                          style: TextStyle(color: Colors.white),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
