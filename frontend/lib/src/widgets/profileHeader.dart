import 'package:countries_utils/countries_utils.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:konnect/src/utils/utils.dart'; // For kIsWeb

class ProfileHeader extends StatefulWidget {
  final Map<String, dynamic> userData;
  final bool ownProfile;
  const ProfileHeader({
    Key? key,
    required this.userData,
    required this.ownProfile,
  }) : super(key: key);
  @override
  State<ProfileHeader> createState() => _ProfileHeaderState();
}

class _ProfileHeaderState extends State<ProfileHeader> {
  final ImagePicker _picker = ImagePicker();
  String profileUrl =
      'assets/images/profile.png'; // Initialize with default image

  @override
  void initState() {
    super.initState();
    // Get the profile image URL on initialization
    profileUrl = widget.userData['profile_url'] ?? 'assets/images/profile.png';
  }

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
      );

      if (pickedFile != null) {
        // Copy the image to the local directory
        String url = await uploadProfileImage(pickedFile);
        print("new profile image URL: $url");
        setState(() {
          profileUrl = url; // Update the profile image after upload
        });
      }
    } catch (e) {
      print('Error picking image: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    String countryCode = widget.userData['country'].toUpperCase();
    String countryName = Countries.byCode(countryCode).name ?? 'Unknown';
    String flagEmoji = countryCode.codeUnits
        .map((e) => String.fromCharCode(e + 127397))
        .join();
    // String profileUrl = widget.userData['profile_url'];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          children: [
            SizedBox(width: 130, height: 130),
            CircleAvatar(
              radius: 60,
              backgroundColor: Colors.grey[300],
              backgroundImage: profileUrl != 'assets/images/profile.png'
                  ? NetworkImage("$profileUrl")
                  : AssetImage('assets/images/profile.png') as ImageProvider,
            ),
            if (widget.ownProfile)
              Positioned(
                bottom: 10,
                right: 5,
                child: GestureDetector(
                  onTap: () {
                    _pickImage();
                    print("Edit Button Pressed");
                  },
                  child: CircleAvatar(
                    radius: 18,
                    backgroundColor: Colors.blue,
                    child: Icon(Icons.edit, color: Colors.white, size: 20),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(width: 20),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 25),
              Text(
                '${widget.userData['name']}, ${calculateAge(DateTime.parse(widget.userData['birthday']))}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                overflow: TextOverflow.ellipsis,
                softWrap: true,
                maxLines: 5,
              ),
              const SizedBox(height: 10),
              Text(
                '$countryName $flagEmoji',
                style: const TextStyle(fontSize: 15, color: Colors.white),
                overflow: TextOverflow.ellipsis,
                softWrap: true,

                maxLines: 5,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
