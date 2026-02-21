import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:konnect/src/models/models.dart';
import 'package:konnect/src/screens/chatScreen.dart';
import 'package:konnect/src/screens/opinionsScreen.dart';
import 'package:konnect/src/services/auth/authService.dart';
import 'package:konnect/src/widgets/chatList.dart';
import 'package:konnect/src/widgets/conversationList.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

const String local = String.fromEnvironment('LOCAL', defaultValue: 'yes');

class ApiClient {
  static final Dio dio = Dio(
    BaseOptions(
      baseUrl:
          (local == 'yes')
              ? "http://192.168.1.7:8080/api"
              : "https://konnect.lasdasx.com/api",
      // baseUrl: 'http://192.168.1.7:8080', REMOVE HARDCODED IP
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {'Content-Type': 'application/json'},
    ),
  );
}

final wsProvider = StreamProvider<dynamic>((ref) async* {
  final controller = StreamController<dynamic>();
  bool isDisposed = false;

  // Function to handle the connection logic
  Future<void> connect() async {
    while (!isDisposed) {
      try {
        final authService = AuthService();
        final token = await authService.accessToken;

        if (token == null) {
          await Future.delayed(const Duration(seconds: 5));
          continue;
        }

        final channel = WebSocketChannel.connect(
          Uri.parse(
            (local == 'yes')
                ? 'ws://192.168.1.7:8080/api/ws?token=$token'
                : 'wss://konnect.lasdasx.com/api/ws?token=$token',
          ),
        );

        // Wait for the connection to be established
        await channel.ready;

        await for (final message in channel.stream) {
          if (isDisposed) break;
          controller.add(message);
          if (message == "ping") {
            print("received ping");
            print("pong");
            // Optionally reply with "pong" if your server requires it
            // channel.sink.add("pong");
            continue;
          }
        }
      } catch (e) {
        debugPrint("WS Connection lost: $e");
      }

      // If we reach here, the connection closed. Wait before retrying.
      if (!isDisposed) {
        await Future.delayed(const Duration(seconds: 3));
        debugPrint("Attempting to reconnect...");
      }
    }
  }

  // Start the connection loop
  connect();

  ref.onDispose(() {
    isDisposed = true;
    controller.close();
  });

  yield* controller.stream;
});

final wsListenerProvider = Provider<void>((ref) {
  // Use listen to react to stream changes without rebuilding the whole provider
  ref.listen(wsProvider, (previous, next) {
    next.whenData((message) {
      try {
        final decoded = jsonDecode(message) as Map<String, dynamic>;

        switch (decoded['type']) {
          case 'matchesUpdate':
            final update = MatchSummary.fromJson(decoded['data']);
            ref.read(chatListProvider.notifier).addUpdates([update]);
            break;
          case 'newMessageUpdate':
            final update = Message.fromJson(decoded['data']);
            ref
                .read(conversationListProvider.notifier)
                .addMessageUpdate(update);

            // <-- Only add messages for this chat
            ref.read(messagesProvider(update.chatId).notifier).addUpdates([
              update,
            ]);

            break;
          case 'removeMatch':
            final match_id = decoded['data']['match_id'];
            ref.read(chatListProvider.notifier).removeMatch(match_id);
            break;
          case 'opinionsUpdate':
            final update = OpinionSummary.fromJson(decoded['data']);
            ref.read(opinionsProvider.notifier).addOpinionUpdate(update);
            break;
          case 'newConversationUpdate':
            final update = ChatSummary.fromJson(decoded['data']);
            ref
                .read(conversationListProvider.notifier)
                .addConversationUpdate(update);
            break;

          // ... rest of your cases ...
        }
      } catch (e) {
        debugPrint("WS Decode Error: $e");
      }
    });
  });
});
