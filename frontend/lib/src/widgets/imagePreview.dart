import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // For kIsWeb

class ImagePreview extends StatefulWidget {
  final int selectedImageIndex;
  final List<String> imagePaths;
  final Function(int) onImageChanged;
  final GlobalKey imagePreviewKey;

  ImagePreview({
    required this.imagePreviewKey,
    required this.selectedImageIndex,
    required this.imagePaths,
    required this.onImageChanged,
  }) : super(key: imagePreviewKey);

  @override
  ImagePreviewState createState() => ImagePreviewState();
}

class ImagePreviewState extends State<ImagePreview> {
  int selectedImageIndex = -1;
  List<String> imagePaths = [];
  GlobalKey imagePreviewKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    setState(() {
      imagePreviewKey = widget.imagePreviewKey;
      selectedImageIndex = widget.selectedImageIndex;
      imagePaths = widget.imagePaths;
    });
  }

  void updateIndex(index) {
    print("calles update State");
    setState(() {
      selectedImageIndex = index;
    });
  }

  @override
  void didUpdateWidget(covariant ImagePreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Check if the imagePaths have changed
    if (widget.imagePaths != oldWidget.imagePaths) {
      setState(() {
        imagePaths = widget.imagePaths;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (selectedImageIndex != -1) {
      return PopScope(
        canPop: false,
        onPopInvokedWithResult:
            (didPop, result) => {
              setState(() {
                selectedImageIndex = -1;
              }),
            },
        child: GestureDetector(
          onTap: () {
            // Close the preview by setting the selectedImageIndex to null
            setState(() {
              selectedImageIndex = -1;
            }); // Passing -1 will close the preview
          },
          child: Container(
            color: Colors.black.withOpacity(0.7),
            child: Center(
              child: PageView.builder(
                controller: PageController(initialPage: selectedImageIndex),
                itemCount: imagePaths.length,
                onPageChanged: (index) {
                  setState(() {
                    selectedImageIndex = index;
                  });
                },
                itemBuilder: (context, index) {
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: _buildImage(imagePaths[index]),
                  );
                },
              ),
            ),
          ),
        ),
      );
    } else {
      return Container();
    }
  }

  Widget _buildImage(String imageUrl) {
    print("Build image");
    print(imageUrl);
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
