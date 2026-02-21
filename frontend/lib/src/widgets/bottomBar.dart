import 'package:flutter/material.dart';
import 'package:konnect/src/colors.dart';

class CustomBottomBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemTapped;

  const CustomBottomBar({
    Key? key,
    required this.selectedIndex,
    required this.onItemTapped,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.secondaryColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: Offset(0, -2),
            ),
          ],
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.transparent, // container handles color
          elevation: 0,
          currentIndex: selectedIndex,
          onTap: onItemTapped,
          showSelectedLabels: false,
          showUnselectedLabels: false,
          selectedItemColor: AppColors.selectedTabColor,
          unselectedItemColor: AppColors.textColor,
          items: [
            _buildNavItem('assets/icons/globe.png', 0),
            _buildNavItem('assets/icons/opinions.png', 1),
            _buildNavItem('assets/icons/message.png', 2),
            _buildNavItem('assets/icons/profile.png', 3, isProfile: true),
          ],
        ),
      ),
    );
  }

  BottomNavigationBarItem _buildNavItem(
    String asset,
    int index, {
    bool isProfile = false,
  }) {
    bool isSelected = index == selectedIndex;
    double baseScale = isProfile ? 1.6 : 1.4;

    return BottomNavigationBarItem(
      icon: AnimatedContainer(
        duration: Duration(milliseconds: 250),
        curve: Curves.easeOut,
        padding: EdgeInsets.only(bottom: isSelected ? 4 : 0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Transform.scale(
              scale: isSelected ? baseScale + 0.2 : baseScale,
              child: ImageIcon(AssetImage(asset)),
            ),
          ],
        ),
      ),
      label: '',
    );
  }
}
