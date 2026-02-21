import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:konnect/src/colors.dart';
import 'package:konnect/src/models/models.dart';
import 'package:konnect/src/services/api_service.dart';
import 'package:konnect/src/utils/utils.dart';
import 'package:konnect/src/widgets/conversationList.dart';
import 'package:konnect/src/widgets/messageBubble.dart';
import 'package:konnect/src/widgets/messageField.dart';
import 'package:konnect/src/widgets/profileCard.dart';

final messagesApiProvider = FutureProvider.family<void, int>((
  ref,
  chatId,
) async {
  final dio = ApiClient.dio;
  final data = await fetchMessages(dio, chatId.toString());
  ref.read(messagesProvider(chatId).notifier).setInitial(data);
});

final messagesProvider =
    StateNotifierProvider.family<MessagesNotifier, List<Message>, int>(
      (ref, chatId) => MessagesNotifier(),
    );

class MessagesNotifier extends StateNotifier<List<Message>> {
  MessagesNotifier() : super([]);

  void setInitial(List<Message> initial) => state = initial;

  void addUpdates(List<Message> updates) {
    state = [...updates, ...state];
  }
}

final opinionsChatApiProvider = FutureProvider.family<void, int>((
  ref,
  userId2,
) async {
  // Assuming you have your fetchOpinions logic ready
  final data = await fetchOpinions(userId2);
  ref.read(opinionsChatProvider(userId2).notifier).setInitial(data);
});

// The storage: Holds the list of OpinionSummary objects
final opinionsChatProvider = StateNotifierProvider.family<
  OpinionsChatNotifier,
  List<OpinionSummary>,
  int
>((ref, userId2) => OpinionsChatNotifier());

class OpinionsChatNotifier extends StateNotifier<List<OpinionSummary>> {
  OpinionsChatNotifier() : super([]);

  void setInitial(List<OpinionSummary> initial) => state = initial;
}

Future<List<Message>> fetchMessages(Dio dio, String chatId) async {
  final res = await dio.get(
    '/messages/$chatId',
  ); /////maybe do something with security here, check if the user belongs in the chat

  final messages =
      (res.data as List<dynamic>)
          .map((e) => Message.fromJson(e as Map<String, dynamic>))
          .toList();

  return messages;
}

class ChatScreen extends ConsumerStatefulWidget {
  final String userName;
  final String userProfilePic;
  // final int userId1;
  final int userId2;
  final int chatId; // New variable to store chat ID

  ChatScreen({
    required this.userName,
    required this.userProfilePic,
    // required this.userId1,
    required this.userId2,
    required this.chatId,
  }); // Initializing chatId

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  @override
  void initState() {
    super.initState();

    // Run AFTER first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _markRead();
    });
  }

  void _markRead() {
    ref.read(conversationListProvider.notifier).setReadMessage(widget.chatId);

    ApiClient.dio.post('/setReadMessage/${widget.chatId}');
  }

  @override
  Widget build(BuildContext context) {
    // Load initial messages for this chat
    ref.watch(messagesApiProvider(widget.chatId));

    // Subscribe to WS updates
    ref.watch(wsListenerProvider);

    // Get current messages
    final messages = ref.watch(messagesProvider(widget.chatId));

    ref.watch(opinionsChatApiProvider(widget.userId2));

    // 2. Listen to the actual data
    final opinions = ref.watch(opinionsChatProvider(widget.userId2));
    print("messages: ${messages}");
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          _markRead();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.backgroundColor,
        appBar: AppBar(
          title: GestureDetector(
            onTap: () {
              //complete it here
              showProfileCard(context, widget.userId2);
            },
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.grey[300], // Fallback color
                  backgroundImage:
                      widget.userProfilePic != 'assets/images/profile.png'
                          ? NetworkImage(widget.userProfilePic)
                          : AssetImage('assets/images/profile.png')
                              as ImageProvider,
                ),
                SizedBox(width: 15), // Space between avatar and name
                Text(
                  widget.userName,
                  style: TextStyle(color: AppColors.textColor),
                ),
              ],
            ),
          ),
          backgroundColor: AppColors.secondaryColor,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: AppColors.textColor, size: 30),
            onPressed: () {
              Navigator.pop(context); // Go back to the previous screen
            },
          ),
        ),
        body: Center(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,

            children: [
              Expanded(
                child:
                    messages.isNotEmpty
                        ? ListView.builder(
                          reverse: true,
                          itemCount: opinions.length + messages.length,
                          itemBuilder: (context, index) {
                            if (index < messages.length) {
                              final message = messages[index];
                              return MessageBubble(
                                otherId: widget.userId2,
                                message: message.content,
                                isMe: message.senderId != widget.userId2,
                                finalMessage:
                                    index == 0 ||
                                    messages[index - 1].senderId !=
                                        message.senderId,
                                firstMessage:
                                    index == messages.length - 1 ||
                                    messages[index + 1].senderId !=
                                        message.senderId,

                                profile2Url:
                                    message.senderId == widget.userId2
                                        ? widget.userProfilePic
                                        : "",
                                isOpinion: false,
                              );
                            } else {
                              final opinion =
                                  opinions[1 - index + messages.length];
                              return MessageBubble(
                                otherId: widget.userId2,
                                profile2Url: opinion.profileUrl,
                                message: opinion.opinion,
                                isMe:
                                    opinion.senderId !=
                                    widget
                                        .userId2, // Dynamically set based on user
                                finalMessage: true,
                                firstMessage: true,
                                isOpinion: true,
                              );
                            }
                          },
                        )
                        : motivatingPart(
                          userName: widget.userName,
                          userProfilePic: widget.userProfilePic,
                          // userId1: userId1,
                          userId2: widget.userId2,
                          opinions: opinions,
                        ),
              ),
              MessageInput(user2: widget.userId2, chatId: widget.chatId),
            ],
          ),
        ),
      ),
    );
  }
}

class motivatingPart extends StatelessWidget {
  final String userName;

  final String userProfilePic;
  // final String userId1;
  final int userId2;
  final List<OpinionSummary> opinions;
  motivatingPart({
    required this.userName,
    // required this.userId1,
    required this.userId2,
    required this.userProfilePic,
    required this.opinions,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Center(
        child: SingleChildScrollView(
          child: Column(
            children: [
              SizedBox(height: 50),
              Text(
                '$userName, 23 ', //////////////ADD AGE
                style: TextStyle(
                  fontFamily: "RobotoMono",
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 10),

              CircleAvatar(
                radius: 50,
                backgroundImage: NetworkImage(userProfilePic),
              ),
              SizedBox(height: 10),
              Text(
                'Chat with $userName',
                style: TextStyle(
                  fontFamily: "RobotoMono",
                  fontSize: 20,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 30),
              Column(
                children:
                    opinions.map((opinion) {
                      return MessageBubble(
                        otherId: userId2,
                        profile2Url: opinion.profileUrl,
                        message: opinion.opinion,
                        isMe:
                            opinion.senderId !=
                            userId2, // Dynamically set based on user
                        finalMessage: true,
                        firstMessage: true,
                        isOpinion: true,
                      );
                    }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
