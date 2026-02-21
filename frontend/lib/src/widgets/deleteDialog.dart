import 'package:flutter/material.dart';
import '../colors.dart';

class CustomDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmLabel;
  final Color confirmColor;
  final VoidCallback onConfirm;

  const CustomDialog({
    Key? key,
    required this.title,
    required this.message,
    required this.onConfirm,
    required this.confirmLabel,
    this.confirmColor = AppColors.dialogRed,
  }) : super(key: key);

  /// --- The Static Method ---
  static Future<void> show(
    BuildContext context, {
    required String title,
    required String message,
    required VoidCallback onConfirm,
    required String confirmLabel,
    Color confirmColor = AppColors.dialogRed,
  }) {
    return showDialog(
      context: context,
      builder:
          (context) => CustomDialog(
            title: title,
            message: message,
            onConfirm: onConfirm,
            confirmLabel: confirmLabel,
            confirmColor: confirmColor,
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.secondaryColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textColor,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textColor.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        color: AppColors.textColor.withOpacity(0.6),
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: TextButton(
                    onPressed: () {
                      Navigator.pop(context); // Close dialog
                      onConfirm(); // Execute action
                    },
                    child: Text(
                      confirmLabel,
                      style: TextStyle(
                        color: confirmColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
