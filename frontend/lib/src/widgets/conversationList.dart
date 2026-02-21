import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:intl/intl.dart';
import 'package:konnect/src/colors.dart';
import 'package:konnect/src/models/models.dart';
import 'package:konnect/src/services/api_service.dart';
import 'package:konnect/src/screens/chatScreen.dart';
import 'package:konnect/src/widgets/profileCard.dart';

final conversationListApiProvider = FutureProvider<void>((ref) async {
  final dio = ApiClient.dio;
  final data = await fetchConversationUsers(dio);

  ref.read(conversationListProvider.notifier).setInitial(data);
});

final conversationListProvider =
    StateNotifierProvider<ConversationListNotifier, List<ChatSummary>>(
      (ref) => ConversationListNotifier(),
    );

class ConversationListNotifier extends StateNotifier<List<ChatSummary>> {
  ConversationListNotifier() : super([]);

  void setInitial(List<ChatSummary> initial) => state = initial;

  void addMessageUpdate(Message update) {
    final senderId = update.senderId;
    final receiverId = update.receiverId;
    bool received, sent;
    state = state.map((c) {
      received = c.userId == senderId;
      sent = c.userId == receiverId;
      if (sent || received) {
        // Merge new data into existing conversation
        c.lastMessage = update.content;
        c.time = update.time!;
        c.read = sent;
      }
      return c;
    }).toList();
    print("mikos: ${state.length}");

    //   if (!found) {
    //     state = [...state, conversation];

    //   state = [...state, update]; // append to existing list
  }

  void addConversationUpdate(ChatSummary update) {
    state = [...state, update]; // append to existing list
  }

  void setReadMessage(int chatId) {
    state = state.map((c) {
      if (c.id == chatId) {
        c.read = true;
        return c;
      }
      return c;
    }).toList();
  }
}

class ConversationsList extends ConsumerWidget {
  final int currentUserId;

  const ConversationsList({Key? key, required this.currentUserId})
    : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(conversationListApiProvider);

    // 2️⃣ Subscribe to WS updates
    ref.watch(wsListenerProvider);

    final convoUsers = ref.watch(conversationListProvider);

    if (convoUsers.isEmpty) {
      return const Center(
        child: Text(
          "Here will appear your conversations",
          style: TextStyle(color: Colors.white),
        ),
      );
    }

    // Sort chats by last message time
    convoUsers.sort((a, b) {
      DateTime aTime = a.time;
      DateTime bTime = b.time;
      return bTime.compareTo(aTime);
    });
    return ListView.builder(
      itemCount: convoUsers.length,
      itemBuilder: (context, index) {
        var convo = convoUsers[index];
        var lastMessage = convo.lastMessage;
        var isRead = convo.read;
        var lastMessageTime = convo.time;
        int otherUserId = convo.userId;

        var profilePic = convo.profileUrl;
        var userName = convo.name;

        return InkWell(
          onTap: () async {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChatScreen(
                  userName: userName,
                  userProfilePic: profilePic,
                  // userId1: currentUserId,
                  userId2: convo.userId, ///////////change that to int
                  chatId: convo.id,
                ),
              ),
            );
          },
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            child: Row(
              children: [
                // Custom CircleAvatar with full size control
                GestureDetector(
                  onTap: () {
                    showProfileCard(context, otherUserId);
                  },
                  child: CircleAvatar(
                    radius: 30, // Adjust as needed (e.g., 40 for bigger)
                    backgroundImage: profilePic.startsWith("http")
                        ? NetworkImage(profilePic)
                        : AssetImage(profilePic) as ImageProvider,
                  ),
                ),
                SizedBox(width: 16), // Spacing between avatar and text
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userName,
                        style: TextStyle(
                          fontSize: 20,
                          fontFamily: 'RobotoMono',
                          color: AppColors.textColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        lastMessage,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: isRead
                              ? FontWeight.normal
                              : FontWeight.bold,
                          color: isRead
                              ? AppColors.secondaryColor
                              : AppColors.textColor,
                        ),
                      ),
                    ],
                  ),
                ),
                // Timestamp on the right
                Text(
                  formatTimestamp(lastMessageTime),
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

Future<List<ChatSummary>> fetchConversationUsers(Dio dio) async {
  final res = await dio.get('/chats');

  List<ChatSummary> conversationUsers = (res.data as List)
      .map((json) => ChatSummary.fromJson(json as Map<String, dynamic>))
      .toList();

  return conversationUsers;
}

String formatTimestamp(DateTime dateTime) {
  DateTime now = DateTime.now().toUtc();
  DateTime yesterday = now.subtract(Duration(days: 1));

  // Format the month and day as "Mar 25"

  // Check if the timestamp is from today
  if (dateTime.year == now.year &&
      dateTime.month == now.month &&
      dateTime.day == now.day) {
    // If it's from today, return the time
    return "${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}"; // Example: "14:05"
  }
  // Check if the timestamp is from yesterday
  else if (dateTime.year == yesterday.year &&
      dateTime.month == yesterday.month &&
      dateTime.day == yesterday.day) {
    // If it's from yesterday, return "Yesterday"
    return "Yesterday";
  } else {
    // If the year is the same as the current year, return just the month and day (e.g. "Mar 25")
    if (dateTime.year == now.year) {
      return "${DateFormat('MMM').format(dateTime)} ${dateTime.day}";
    }
    // If it's from a different year, return the full date in the "Mar 25, 2023" format
    else {
      return "${DateFormat('MMM dd, yyyy').format(dateTime)}"; // Example: "Mar 25, 2023"
    }
  }
}
