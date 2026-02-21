import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:konnect/src/colors.dart';
import 'package:konnect/src/models/models.dart';
import 'package:konnect/src/services/api_service.dart';
import 'package:konnect/src/screens/chatScreen.dart';

final chatListApiProvider = FutureProvider<void>((ref) async {
  final dio = ApiClient.dio;
  final data = await fetchChatUsers(dio); // replace "1" with currentUserId
  ref.read(chatListProvider.notifier).setInitial(data);
});

final chatListProvider =
    StateNotifierProvider<ChatListNotifier, List<MatchSummary>>(
      (ref) => ChatListNotifier(),
    );

class ChatListNotifier extends StateNotifier<List<MatchSummary>> {
  ChatListNotifier() : super([]);

  void setInitial(List<MatchSummary> initial) => state = initial;

  void addUpdates(List<MatchSummary> updates) {
    state = [
      ...updates,

      ...state,
    ]; // append to existing list matchSummary einai to state
  }

  void removeMatch(int matchId) {
    state = state.where((match) => match.id != matchId).toList();
  }
}

class ChatList extends ConsumerWidget {
  const ChatList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1️⃣ Load initial data
    ref.watch(chatListApiProvider);

    // 2️⃣ Subscribe to WS updates
    ref.watch(wsListenerProvider);

    final chatUsers = ref.watch(chatListProvider);

    if (chatUsers.isEmpty) {
      return const Center(
        child: Text(
          "Here will appear your matches",
          style: TextStyle(color: Colors.white),
        ),
      );
    }
    return Align(
      alignment: AlignmentGeometry.centerLeft,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children:
              chatUsers.map((user) {
                return GestureDetector(
                  onTap: () {
                    // Handle navigation to chat screen
                    print("Tapped on ${user.name}");
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => ChatScreen(
                              userName: user.name,
                              userProfilePic: user.profileUrl,
                              // userId1: "1",
                              userId2: user.userId,
                              chatId: user.id,
                            ),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundImage:
                              user.profileUrl != null
                                  ? NetworkImage(user.profileUrl)
                                  : AssetImage("assets/default_avatar.png")
                                      as ImageProvider,
                        ),
                        SizedBox(height: 8),
                        Text(
                          user.name,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
        ),
      ),
    );
  }
}

Future<List<MatchSummary>> fetchChatUsers(Dio dio) async {
  final res = await dio.get('/matches');

  final chatUsers =
      (res.data as List<dynamic>)
          .map((e) => MatchSummary.fromJson(e as Map<String, dynamic>))
          .toList();

  return chatUsers;
}
