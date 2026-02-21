import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:konnect/src/colors.dart';
import 'package:konnect/src/models/models.dart';
import 'package:konnect/src/screens/chatScreen.dart';
import 'package:konnect/src/services/api_service.dart';
import 'package:konnect/src/widgets/conversationList.dart';

class MessageInput extends ConsumerStatefulWidget {
  final int user2;
  final int chatId;
  MessageInput({required this.user2, required this.chatId});
  @override
  _MessageInputState createState() => _MessageInputState();
}

class _MessageInputState extends ConsumerState<MessageInput> {
  final TextEditingController _controller = TextEditingController();

  void _sendMessage() async {
    if (_controller.text.trim().isEmpty) return;

    final int receiverId = widget.user2;
    final int chat_id = widget.chatId;

    String message = _controller.text.trim();
    _controller.clear();

    // Check if chat exists, if not create it
    print("message chat id: $chat_id");
    final res = await ApiClient.dio.post(
      "/message",
      data: Message(chatId: chat_id, receiverId: receiverId, content: message),
    );
    if (res.statusCode == 200) {
      print("Message sent successfully");
      final succesfulMessage = Message.fromJson(res.data);
      ref.read(messagesProvider(widget.chatId).notifier).addUpdates([
        succesfulMessage,
      ]);
      ref
          .read(conversationListProvider.notifier)
          .addMessageUpdate(succesfulMessage);
    } else {
      print("Failed to send message");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.messageFieldBackground.withOpacity(0.9),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white24),
        ),
        child: Row(
          crossAxisAlignment:
              CrossAxisAlignment.end, // Anchors everything to the bottom
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                style: const TextStyle(color: Colors.white, fontSize: 16),
                minLines: 1,
                maxLines: 5,
                decoration: const InputDecoration(
                  hintText: "Message...",
                  hintStyle: TextStyle(color: Colors.white54),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.fromLTRB(16, 12, 12, 12),
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            // Using a specific Padding to align with the text line
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: IconButton(
                icon: const Icon(
                  Icons.send_rounded,
                  color: AppColors.paperplaneColor,
                  size: 26,
                ),
                onPressed: _sendMessage,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
