import 'package:flutter/material.dart';
import 'package:konnect/src/colors.dart';
import 'package:konnect/src/models/userProfile.dart';
import 'package:country_picker/country_picker.dart'; // Correct import for country_picker
import 'package:konnect/src/screens/onboarding/onBoarding4.dart';
import 'package:konnect/src/utils/utils.dart';
import 'package:konnect/src/widgets/progressAppBar.dart';

class OnBoarding3Screen extends StatefulWidget {
  final ValueChanged<Country> onNext;
  final Country? country;
  const OnBoarding3Screen({super.key, required this.onNext, this.country});

  @override
  State<OnBoarding3Screen> createState() => _OnBoarding3ScreenState();
}

class _OnBoarding3ScreenState extends State<OnBoarding3Screen> {
  Country? selectedCountry;

  @override
  void initState() {
    super.initState();
    if (widget.country != null) {
      selectedCountry = widget.country;
    }
  }

  // Country Picker widget
  void _pickCountry() {
    showCountryPicker(
      countryListTheme: CountryListThemeData(
        // Dark background and light text color
        inputDecoration: InputDecoration(
          hintText: 'Search for a country...',
          hintStyle: TextStyle(color: Colors.white70),
          enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.white70),
          ),
          focusedBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.white),
          ),
        ),
        backgroundColor: AppColors.secondaryColor, // Dark background
        textStyle: TextStyle(color: Colors.white), // Light text
        searchTextStyle: TextStyle(color: Colors.white70), // Light search text
      ),
      context: context,
      showPhoneCode: false, // Hide phone code if you don't need it
      onSelect: (Country country) {
        setState(() {
          selectedCountry = country;
        });
        print(
          country.countryCode,
        ); // Optionally print the selected country code
      },
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
                "I am from",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  fontFamily: "RobotoMono",
                ),
              ),
              SizedBox(height: 24),
              GestureDetector(
                onTap: _pickCountry,
                child: Container(
                  width: 280,
                  padding: EdgeInsets.symmetric(vertical: 18),
                  decoration: BoxDecoration(
                    color: Colors.grey[800],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child:
                      selectedCountry != null
                          ? Text(
                            selectedCountry!.name +
                                " " +
                                getFlagEmoji(selectedCountry!.countryCode),
                            style: TextStyle(color: Colors.white, fontSize: 18),
                            textAlign: TextAlign.center,
                          )
                          : Text(
                            "Select your country",
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 18,
                            ),
                            textAlign: TextAlign.center,
                          ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                "Let others know where you are from",
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
                    if (selectedCountry != null) {
                      widget.onNext(selectedCountry!);
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
