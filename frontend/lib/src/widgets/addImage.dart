import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:konnect/src/colors.dart';
import 'package:image_picker/image_picker.dart';
import 'package:konnect/src/utils/utils.dart';

import 'dart:io';
import 'package:konnect/src/services/api_service.dart';

class addImageButton extends StatefulWidget {
  final Function(String) onImageSelected;

  const addImageButton({super.key, required this.onImageSelected});

  @override
  State<addImageButton> createState() => _addImageButtonState();
}

class _addImageButtonState extends State<addImageButton> {
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;
  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
      );
      if (pickedFile == null) return;

      setState(() => _isUploading = true);

      // Copy the image to the local directory

      // Convert XFile to File

      // Send POST request
      final response = await uploadSupportImage(pickedFile);

      // Backend response, maybe the uploaded file URL
      print('Upload success: $response ');

      // Notify parent widget about the selected image
      widget.onImageSelected(response);
    } catch (e) {
      print('Error picking image: $e');
    } finally {
      setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // A neutral, modern color palette
    final Color iconColor = const Color.fromARGB(
      255,
      255,
      255,
      255,
    ).withOpacity(0.6);
    final Color borderColor = const Color.fromARGB(
      255,
      255,
      255,
      255,
    ).withOpacity(0.1);

    return GestureDetector(
      onTap: _isUploading ? null : _pickImage,
      child: Container(
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(5)),
        child:
            _isUploading
                ? SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 4,
                    valueColor: AlwaysStoppedAnimation<Color>(iconColor),
                  ),
                )
                : ImageIcon(
                  size: 60,
                  const AssetImage('assets/icons/addImage.png'),
                  color: AppColors.secondaryColor,
                ),
      ),
    );
  }
}
