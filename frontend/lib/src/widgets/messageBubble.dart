import 'package:flutter/material.dart';
import 'package:konnect/src/colors.dart';
import 'package:konnect/src/widgets/profileCard.dart';

class MessageBubble extends StatelessWidget {
  final String message;
  final String profile2Url;
  final bool isMe;
  final int otherId;
  final bool finalMessage;
  final bool firstMessage;
  final bool isOpinion;
  MessageBubble({
    required this.profile2Url,
    required this.message,
    required this.otherId,
    required this.isMe,
    required this.finalMessage,
    required this.firstMessage,
    required this.isOpinion,
  });

  @override
  Widget build(BuildContext context) {
    print("firstMessage: $firstMessage");
    print("finalMessage: $finalMessage");
    print("isme: $isMe");
    print("text:  $message");
    return Row(
      mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.end, // Align items at the bottom

      children: [
        SizedBox(width: 10),
        !isMe && finalMessage
            ? GestureDetector(
              onTap:
                  () => {
                    ///complete it here
                    showProfileCard(context, otherId),
                  },
              child: CircleAvatar(
                radius: 20,
                backgroundColor: Colors.grey[300],
                backgroundImage:
                    profile2Url != 'assets/images/profile.png'
                        ? NetworkImage(profile2Url)
                        : AssetImage('assets/images/profile.png')
                            as ImageProvider,
              ),
            )
            : SizedBox(width: 40),
        Flexible(
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            margin: EdgeInsets.only(
              top: 2,
              bottom: 2,
              left: isMe ? 40 : 10,
              right: isMe ? 10 : 60,
            ),
            // EdgeInsets.symmetric(
            //   vertical: 2,
            //   horizontal: isMe ? 30 : 10,
            // ),
            decoration: BoxDecoration(
              color:
                  isMe
                      ? (!isOpinion
                          ? AppColors.myBubble
                          : AppColors.myOpinionBubble)
                      : (!isOpinion
                          ? AppColors.otherBubble
                          : AppColors.otherOpinionBubble), // Your color scheme
              borderRadius:
                  isMe
                      ? BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(firstMessage ? 20 : 5),
                        bottomLeft: Radius.circular(20),
                        bottomRight: Radius.circular(5),
                      )
                      : BorderRadius.only(
                        topLeft: Radius.circular(firstMessage ? 20 : 5),
                        topRight: Radius.circular(20),
                        bottomLeft: Radius.circular(5),
                        bottomRight: Radius.circular(20),
                      ),
            ),
            child: Text(
              message,
              style: TextStyle(
                color: Colors.white,
                fontSize: isOpinion ? 18 : 14,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class OpinionBubble extends StatelessWidget {
  final String message;
  final bool isMe;
  final bool finalMessage;
  final bool firstMessage;
  final bool isOpinion;
  OpinionBubble({
    required this.message,
    required this.isMe,
    required this.finalMessage,
    required this.firstMessage,
    required this.isOpinion,
  });

  @override
  Widget build(BuildContext context) {
    print("firstMessage: $firstMessage");
    print("finalMessage: $finalMessage");
    print("isme: $isMe");
    print("text:  $message");
    return Row(
      mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.end, // Align items at the bottom

      children: [
        Flexible(
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            margin: EdgeInsets.only(
              left: isMe ? 40 : 5,
              right: isMe ? 5 : 60,
              top: 2,
              bottom: 2,
            ),
            decoration: BoxDecoration(
              color:
                  isMe
                      ? (!isOpinion
                          ? AppColors.myBubble
                          : AppColors.myOpinionBubble)
                      : (!isOpinion
                          ? AppColors.otherBubble
                          : AppColors.otherOpinionBubble), // Your color scheme
              borderRadius:
                  isMe
                      ? BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(firstMessage ? 20 : 5),
                        bottomLeft: Radius.circular(20),
                        bottomRight: Radius.circular(5),
                      )
                      : BorderRadius.only(
                        topLeft: Radius.circular(firstMessage ? 20 : 5),
                        topRight: Radius.circular(20),
                        bottomLeft: Radius.circular(5),
                        bottomRight: Radius.circular(20),
                      ),
            ),
            child: Text(
              message,
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ),
      ],
    );
  }
}
