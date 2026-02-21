import 'package:flutter/material.dart';
import 'package:flutter_riverpod/experimental/persist.dart';
import 'package:konnect/src/colors.dart';
import 'package:konnect/src/screens/splashScreen.dart';
import 'package:konnect/src/services/api_service.dart';
import 'package:konnect/src/services/auth/authService.dart';
import 'package:konnect/src/widgets/deleteDialog.dart';

void showSettingsMenu(BuildContext context) {
  showModalBottomSheet(
    context: context,
    backgroundColor: AppColors.secondaryColor, // Matches your theme
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize:
              MainAxisSize.min, // Sheet only takes as much space as needed
          children: [
            // Handle for aesthetics
          ],
        ),
      );
    },
  );
}

// src/widgets/settings_menu.dart
class SettingsMenu {
  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.secondaryColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SettingsMenuContent(),
    );
  }
}

// Private widget to keep the logic encapsulated
class SettingsMenuContent extends StatelessWidget {
  const SettingsMenuContent();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[600],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 10),
            // Logout Option
            ListTile(
              onTap: () {
                CustomDialog.show(
                  context,
                  title: "Log Out",
                  message: "Are you sure you want to log out?",
                  onConfirm: () async {
                    try {
                      // 2. Tell the backend to delete the Refresh Token record
                      // This ensures the token can't be used even if it's stolen

                      final refreshToken = await AuthService().refreshToken;
                      if (refreshToken != null) {
                        await ApiClient.dio.post(
                          '/auth/logout',
                          data: {
                            'refresh_token': refreshToken, // Pass it here
                          },
                        );
                      }
                    } catch (e) {
                      debugPrint(
                        "Server logout failed, but clearing local data anyway: $e",
                      );
                    } finally {
                      await AuthService().deleteTokens();

                      if (context.mounted) {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SplashScreen(),
                          ), // Or your LandingPage
                          (route) => false,
                        );
                      }
                    }
                  },
                  confirmLabel: "Log out",
                  confirmColor: Colors.redAccent,
                );
              },
              leading: const Icon(Icons.logout, color: AppColors.textColor),
              title: const Text(
                'Log Out',
                style: TextStyle(color: AppColors.textColor),
              ),
            ),

            // Future options can go here (e.g., Privacy, Notifications)
            const Divider(color: Colors.grey),

            // Delete Account (Danger Zone)
            ListTile(
              onTap:
                  () => CustomDialog.show(
                    context,
                    title: "Delete Account",
                    message:
                        "Are you sure you want to delete your account? You will be hidden from other users immediately. Your data will be permanently deleted after 30 days. To cancel this request and reactivate your account, simply log back in before the 30-day period ends.",
                    onConfirm: () async {
                      try {
                        // 2. Tell the backend to delete the Refresh Token record
                        // This ensures the token can't be used even if it's stolen

                        await ApiClient.dio.delete('/user');
                      } catch (e) {
                        debugPrint(
                          "Server logout failed, but clearing local data anyway: $e",
                        );
                      } finally {
                        await AuthService().deleteTokens();

                        if (context.mounted) {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const SplashScreen(),
                            ), // Or your LandingPage
                            (route) => false,
                          );
                        }
                      }
                    },
                    confirmLabel: "Delete",
                    confirmColor: Colors.redAccent,
                  ),
              leading: const Icon(
                Icons.delete_forever,
                color: Colors.redAccent,
              ),
              title: const Text(
                'Delete Account',
                style: TextStyle(color: Colors.redAccent),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
