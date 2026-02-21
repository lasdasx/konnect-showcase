// lib/models/user_profile.dart
import 'package:country_picker/country_picker.dart';

class UserProfile {
  String? name;
  DateTime? birthday;
  Country? country;
  String? gender;
  List<String>? lookingFor;
  String? profileImagePath; // <- Add this

  List<String> photoUrls = []; // Will store uploaded image URLs
  String? bio;

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'birthday': birthday!.toIso8601String(),
      'country': country!.countryCode,
      'gender': gender,
      'lookingFor': lookingFor,
      "profile_url": profileImagePath,
      'images_url': photoUrls,
      'bio': bio,
      'onboarded': true,
    };
  }
}
