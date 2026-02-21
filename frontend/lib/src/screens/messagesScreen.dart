import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:konnect/src/widgets/chatList.dart';
import 'package:konnect/src/widgets/conversationList.dart';

class MessagesScreen extends StatelessWidget {
  const MessagesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(height: 20),
        ChatList(),

        SizedBox(height: 20),
        Expanded(child: ConversationsList(currentUserId: 1)),
      ],
    );
  }
}
