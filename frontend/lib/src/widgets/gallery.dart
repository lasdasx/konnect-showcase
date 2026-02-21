import 'dart:math';
import 'package:flutter/material.dart';
import 'package:konnect/src/services/api_service.dart';
import 'package:konnect/src/widgets/addImage.dart';
import 'package:flutter/foundation.dart';
import 'package:konnect/src/widgets/deleteDialog.dart'; // For kIsWeb

class ProfileGallery extends StatefulWidget {
  final bool ownProfile;
  final List<String> imagePaths;

  final Function(int) onImageSelected;
  ProfileGallery({
    Key? key,
    required this.ownProfile,
    required this.onImageSelected,
    required this.imagePaths,
  }) : super(key: key);

  @override
  ProfileGalleryState createState() => ProfileGalleryState();
}

class ProfileGalleryState extends State<ProfileGallery> {
  int? selectedImageIndex;
  List<String> imageUrls = []; // Store image URLs from Firebase

  @override
  void initState() {
    super.initState();

    setState(() {
      imageUrls = widget.imagePaths;
    });
  }

  @override
  void didUpdateWidget(covariant ProfileGallery oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Check if the imagePaths have changed
    if (widget.imagePaths != oldWidget.imagePaths) {
      setState(() {
        imageUrls = widget.imagePaths;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.center, // Center the children horizontally
      children: [
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 5,
            mainAxisSpacing: 5,
          ),
          // Only count the actual images now
          itemCount: imageUrls.length,
          itemBuilder: (context, index) {
            return GestureDetector(
              onTap: () {
                widget.onImageSelected(index);
              },
              onLongPress: () {
                if (widget.ownProfile) {
                  CustomDialog.show(
                    context,
                    title: "Delete Image",
                    message: "Are you sure you want to delete this image?",
                    onConfirm: () async {
                      try {
                        print("Deleting image: ${imageUrls[index]}");
                        await ApiClient.dio.delete(
                          "/images",
                          data: {"key_index": index},
                        );
                        setState(() {
                          imageUrls.removeAt(index);
                        });
                      } catch (e) {
                        print("❌ Error deleting image: $e");
                      }
                    },
                    confirmLabel: "Delete",
                    confirmColor: Colors.redAccent,
                  );
                }
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(5),
                child: _buildImage(imageUrls[index]),
              ),
            );
          },
        ),

        // 1. Spacing between Grid and Button
        const SizedBox(height: 20),

        // 2. Centered Add Button (Only if ownProfile and under limit)
        if (widget.ownProfile && imageUrls.length < 6)
          Center(
            child: addImageButton(
              onImageSelected: (imagePath) {
                setState(() {
                  imageUrls.add(imagePath);
                });
              },
            ),
          ),

        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildImage(String imageUrl) {
    // if (kIsWeb) {
    //   imageUrl = "https://cors-anywhere.herokuapp.com/" + imageUrl;
    // }

    return Image.network(
      imageUrl,
      fit: BoxFit.contain,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return const Center(child: CircularProgressIndicator());
      },
      errorBuilder: (context, error, stackTrace) {
        print(
          "Error loading image: $imageUrl\nError: $error\nStackTrace: $stackTrace",
        );
        return const Center(child: Icon(Icons.error, color: Colors.red));
      },
    );
  }
}
