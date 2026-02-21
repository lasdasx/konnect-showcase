import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io'; // For File handling
import 'package:konnect/src/models/userProfile.dart';
import 'package:image_picker_android/image_picker_android.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';

class OnBoarding5Screen extends StatefulWidget {
  final List<String>? imagePaths;
  final ValueChanged<List<String>> onNext;
  const OnBoarding5Screen({Key? key, this.imagePaths, required this.onNext})
    : super(key: key);

  @override
  _OnBoarding5ScreenState createState() => _OnBoarding5ScreenState();
}

class _OnBoarding5ScreenState extends State<OnBoarding5Screen> {
  UserProfile userProfile = UserProfile();
  List<File> _images = [];

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final ImagePickerPlatform imagePickerImplementation =
        ImagePickerPlatform.instance;
    if (imagePickerImplementation is ImagePickerAndroid) {
      imagePickerImplementation.useAndroidPhotoPicker = true;
    }
    if (widget.imagePaths != null) {
      setState(() {
        _images = widget.imagePaths!.map((url) => File(url)).toList();
      });
    }
  }

  // Function to pick multiple images from the gallery
  Future<void> _pickImages() async {
    final List<XFile>? images = await _picker.pickMultiImage(
      limit: 6 - _images.length,
    );
    if (images != null) {
      setState(() {
        // Add selected images to the list
        _images.addAll(images.map((image) => File(image.path)).toList());
      });
    }
  }

  // Function to remove an image from the list
  void _removeImage(int index) {
    setState(() {
      _images.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                "My Images",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16),
              // Display the selected images in a GridView
              GridView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  // Number of images in each row
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: 6,
                itemBuilder: (context, index) {
                  if (index < _images.length) {
                    return Stack(
                      alignment: Alignment.topRight,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            _images[index],
                            fit: BoxFit.cover,
                            width: 100,
                            height: 100,
                          ),
                        ),
                        Positioned(
                          top: 0,
                          right: 0,
                          child: IconButton(
                            icon: Icon(
                              Icons.remove_circle,
                              color: Colors.red,
                              size: 24,
                            ),
                            onPressed: () => _removeImage(index),
                          ),
                        ),
                      ],
                    );
                  } else {
                    return Stack(
                      alignment: Alignment.topRight,
                      children: [
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: Colors.grey[800],
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        Positioned(
                          top: 0,
                          right: 0,
                          child: IconButton(
                            icon: Icon(
                              Icons.add_circle,
                              color: Colors.green,
                              size: 24,
                            ),
                            onPressed: () => _pickImages(),
                          ),
                        ),
                      ],
                    );
                  }
                },
              ),

              SizedBox(height: 60),
              Text(
                textAlign: TextAlign.center,
                "Add some photos so that others get to know you better",
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
                    widget.onNext(_images.map((image) => image.path).toList());
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
