import 'package:flutter/material.dart';
import 'package:konnect/src/colors.dart';

class ProgressAppBar extends StatelessWidget implements PreferredSizeWidget {
  final double value;
  const ProgressAppBar({super.key, required this.value});
  @override
  Size get preferredSize => const Size.fromHeight(15); // Set preferred height
  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor:
          AppColors.backgroundColor, // Transparent or same as background
      elevation: 0, // Remove shadow to keep it clean
      automaticallyImplyLeading: false, // To remove the default back button
      flexibleSpace: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 15,
              child: LinearProgressIndicator(
                value: value,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
