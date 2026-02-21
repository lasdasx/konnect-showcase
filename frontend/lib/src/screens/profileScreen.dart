import 'package:flutter/material.dart';
import 'package:konnect/src/models/models.dart';
import 'package:konnect/src/services/api_service.dart';
import 'package:konnect/src/widgets/bio.dart';
import 'package:konnect/src/widgets/gallery.dart';
import 'package:konnect/src/widgets/imagePreview.dart';
import 'package:konnect/src/widgets/profileHeader.dart';

class ProfileScreen extends StatefulWidget {
  final bool ownProfile;

  ProfileScreen({Key? key, required this.ownProfile}) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int selectedImageIndex = -1;
  Map<String, dynamic>? userData;
  bool isLoading = true;
  List<String> imagePaths = [];
  late TextEditingController _bioController;
  String userBio = "Press the edit button to add bio..";
  final GlobalKey<ImagePreviewState> imagePreviewKey =
      GlobalKey<ImagePreviewState>();

  @override
  void initState() {
    super.initState();
    print("AAAAXXX");
    _loadUserData();
  }

  // Load user data once when the screen is initialized
  Future<void> _loadUserData() async {
    try {
      final res = await ApiClient.dio.get('/user/me');
      final data = res.data; // Map<String, dynamic>
      final curUser = User.fromJson(data);
      print("XXXXX");
      print(curUser);
      // ApiService.getUser(int.parse(widget.userId))
      setState(() {
        userData = curUser.toJson();
        userBio = userData?["bio"] == ""
            ? 'Press the edit button to add bio..'
            : userData?["bio"];
        imagePaths = userData?["images_url"] ?? [];
        isLoading = false;
        _bioController = TextEditingController(text: userData?["bio"] ?? '');
      });
      setState(() {
        isLoading = false;
      });
    } catch (error) {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (userData == null) {
      return const Center(child: Text('User not found'));
    }

    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 20),
                ProfileHeader(
                  userData: userData ?? {},
                  ownProfile: widget.ownProfile,
                ),

                ProfileBio(
                  userBio: userBio,
                  bioController: _bioController,
                  ownProfile: widget.ownProfile,
                ),
                const SizedBox(height: 30),

                // Image Gallery
                ProfileGallery(
                  ownProfile: widget.ownProfile,
                  imagePaths: imagePaths,
                  onImageSelected: (index) {
                    // Access ChildTwo's state and update it
                    print("first step");
                    if (imagePreviewKey.currentState != null) {
                      imagePreviewKey.currentState!.updateIndex(index);
                      print("second step");
                    } else {
                      print("imagePreviewKey.currentState is still null!");
                      print(imagePreviewKey);
                    }
                  },
                ),
                SizedBox(
                  height: 20,
                ), // Inside the Stack, before the ImagePreview
              ],
            ),
          ),
        ),

        // Image Preview with Swipe Feature
        // if (selectedImageIndex != -1)
        ImagePreview(
          imagePreviewKey: imagePreviewKey,
          selectedImageIndex: selectedImageIndex,
          imagePaths: imagePaths, // Pass the list of image paths
          onImageChanged: (index) {
            // setState(() {
            //   // When the image changes in the preview, update the selected index
            //   selectedImageIndex = index;
            // });
          },
        ),
      ],
    );
  }
}
