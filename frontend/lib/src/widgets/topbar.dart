import 'package:flutter/material.dart';
import 'package:konnect/src/widgets/settings.dart';
import '../colors.dart';

class CustomTopBar extends StatelessWidget implements PreferredSizeWidget {
  final int? selectedIndex;
  const CustomTopBar({Key? key, this.selectedIndex}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(
        bottom: Radius.circular(20), // round bottom corners
      ),
      child: AppBar(
        automaticallyImplyLeading: false, // This removes the back button

        title: const Text(
          "Konnect",
          style: TextStyle(
            fontFamily: "RobotoMono",
            fontSize: 30,
            letterSpacing: 10,
            color: AppColors.textColor,
          ),
        ),
        actions: [
          selectedIndex == 3
              ? IconButton(
                icon: const Icon(
                  Icons.settings_outlined,
                  color: AppColors.textColor,
                ),
                onPressed: () {
                  SettingsMenu.show(context);
                },
              )
              : Container(),
          const SizedBox(width: 8), // Little bit of breathing room on the right
        ],
        backgroundColor: AppColors.secondaryColor,
        elevation: 0.0,
        // forceMaterialTransparency: true, // For newer Flutter versions
        scrolledUnderElevation: 0.0, // Prevents color change on scroll
        // surfaceTintColor: Colors.transparent, // Removes tint
        // shadowColor: Colors.transparent,
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight * 0.9);
}
