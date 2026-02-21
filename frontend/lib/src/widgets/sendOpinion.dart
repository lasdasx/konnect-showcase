import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:konnect/src/colors.dart';
import 'package:konnect/src/screens/exploreScreen.dart';
import 'package:konnect/src/services/api_service.dart';

final opinionControllerProvider =
    StateProvider.family<TextEditingController, int>((ref, index) {
      final controller = TextEditingController();
      ref.onDispose(() => controller.dispose());
      return controller;
    });

class SendOpinion extends ConsumerWidget {
  final dynamic profile_id;
  final dynamic receiverUserId;
  final dynamic profileImage;

  const SendOpinion({
    super.key,
    required this.receiverUserId,
    required this.profileImage,
    required this.profile_id,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(opinionControllerProvider(profile_id));

    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 8, 0, 16),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.end, // Aligns buttons to the bottom as box grows
        children: [
          // Skip Button
          Padding(
            padding: const EdgeInsets.only(
              bottom: 4,
            ), // Fine-tune vertical alignment
            child: _CircleIconButton(
              iconPath: 'assets/icons/skip.png',
              color: AppColors.skipColor,
              onPressed: () {
                controller.clear();
                ref
                    .read(swiperControllerProvider)
                    .swipe(CardSwiperDirection.left);
                ApiClient.dio.post(
                  '/skip',
                  data: {'skipped_id': receiverUserId},
                );
              },
            ),
          ),

          // const SizedBox(width: 8),

          // Expanding Message Input
          Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                color: AppColors.messageFieldBackground.withOpacity(0.9),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white24),
              ),
              child: TextField(
                controller: controller,
                maxLength: 200,
                // These two lines enable the "grow" logic:
                minLines: 1,
                maxLines:
                    5, // Prevents the box from taking over the whole screen
                style: const TextStyle(color: Colors.white, fontSize: 15),
                textInputAction:
                    TextInputAction.newline, // Allows enter key to add lines
                decoration: const InputDecoration(
                  hintText: "Message...",
                  hintStyle: TextStyle(fontSize: 15, color: Colors.white60),
                  counterText: "",
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  border: InputBorder.none,
                ),
                onChanged: (text) {
                  if (text.length >= 200) {
                    _showLimitSnackBar(context);
                  }
                },
              ),
            ),
          ),

          // const SizedBox(width: 8),

          // Send Button
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: _CircleIconButton(
              isIconData: true,
              iconData: Icons.send_rounded,
              color: AppColors.paperplaneColor,
              onPressed: () {
                ref
                    .read(swiperControllerProvider)
                    .swipe(CardSwiperDirection.right);
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showLimitSnackBar(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text("Character limit reached!"),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

// Helper widget for consistent button styling
class _CircleIconButton extends StatelessWidget {
  final String? iconPath;
  final IconData? iconData;
  final Color color;
  final VoidCallback onPressed;
  final bool isIconData;

  const _CircleIconButton({
    this.iconPath,
    this.iconData,
    required this.color,
    required this.onPressed,
    this.isIconData = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child:
              isIconData
                  ? Icon(iconData, color: color, size: 28)
                  : ImageIcon(AssetImage(iconPath!), color: color, size: 28),
        ),
      ),
    );
  }
}
