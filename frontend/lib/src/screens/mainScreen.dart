import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:konnect/src/colors.dart';
import 'package:konnect/src/screens/exploreScreen.dart';
import 'package:konnect/src/screens/messagesScreen.dart';
import 'package:konnect/src/screens/opinionsScreen.dart';
import 'package:konnect/src/screens/profileScreen.dart';
import 'package:konnect/src/services/api_service.dart';
import 'package:konnect/src/widgets/bottomBar.dart';
import 'package:konnect/src/widgets/topbar.dart';

class mainScreen extends ConsumerStatefulWidget {
  mainScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<mainScreen> createState() => mainScreenState();
}

class mainScreenState extends ConsumerState<mainScreen> {
  int _selectedIndex = 0; // Default to Home Screen
  // Screens for the Bottom Navigation
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    ref.read(wsProvider);

    _screens = [
      ExploreScreen(),
      OpinionsScreen(),
      MessagesScreen(),
      ProfileScreen(ownProfile: true),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: CustomTopBar(selectedIndex: _selectedIndex),
      body: IndexedStack(index: _selectedIndex, children: _screens),
      bottomNavigationBar: CustomBottomBar(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }

  // Add a function to handle notification taps
  void handleNotificationTap(Map<String, dynamic> data) {
    if (data['screen'] == 'chat') {
      // Assuming MessagesScreen is at index 2
      setState(() {
        _selectedIndex = 2;
      });
    } else if (data['screen'] == 'opinions') {
      setState(() {
        _selectedIndex = 1;
      });
    }
  }
}
