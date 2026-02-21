import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:konnect/src/colors.dart';
import 'package:konnect/src/models/models.dart';
import 'package:konnect/src/services/api_service.dart';
import 'dart:core';

import 'package:konnect/src/widgets/exploreCard.dart';
import 'package:konnect/src/widgets/sendOpinion.dart';

class ProfileListNotifier extends StateNotifier<List<UserExploreSummary>> {
  ProfileListNotifier() : super([]);

  // Add new profiles to the list
  void addProfiles(List<UserExploreSummary> profiles) {
    if (state.isEmpty) {
      state = [profiles[0]];
      state = [...state, ...profiles];
    } else {
      state = [...state, ...profiles];
    }
  }

  // Remove the first profile (move to next)
  void nextProfile() {
    if (state.isNotEmpty) {
      state = state.sublist(1);
    }
  }

  void nextProfile2() {
    if (state.isNotEmpty) {
      state = state.sublist(2);
    }
  }
}

// The provider to access the ProfileListNotifier
final profileListProvider =
    StateNotifierProvider<ProfileListNotifier, List<UserExploreSummary>>(
      (ref) => ProfileListNotifier(),
    );

final swiperControllerProvider = Provider<CardSwiperController>((ref) {
  return CardSwiperController();
});

class ExploreScreen extends ConsumerStatefulWidget {
  const ExploreScreen({Key? key}) : super(key: key);
  @override
  ConsumerState<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends ConsumerState<ExploreScreen> {
  bool isLoading = false;

  void _maybeFetchMoreProfiles() {
    final profiles = ref.read(profileListProvider);

    if (profiles.length <= 4 && !isLoading) {
      fetchProfileRecs();
    }
  }

  Future<void> fetchProfileRecs() async {
    if (isLoading) return;
    setState(() => isLoading = true);

    try {
      final result = await ApiClient.dio.get('/recomendations');

      print("Edooooooo");

      List<dynamic> rawList = result.data;

      List<UserExploreSummary> userProfRecs =
          rawList
              .map<UserExploreSummary>(
                (json) => UserExploreSummary.fromJson(json),
              )
              .toList();

      ref.read(profileListProvider.notifier).addProfiles(userProfRecs);
    } catch (error) {
      print('Error calling function: $error');
    } finally {
      setState(() => isLoading = false);
    }
  }

  DateTime? parseTimestamp(dynamic timestamp) {
    if (timestamp is Timestamp) {
      return timestamp.toDate();
    } else if (timestamp is Map && timestamp.containsKey('_seconds')) {
      return DateTime.fromMillisecondsSinceEpoch(timestamp['_seconds'] * 1000);
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    fetchProfileRecs();
  }

  @override
  Widget build(BuildContext context) {
    final profiles = ref.watch(profileListProvider);
    final controller = ref.watch(swiperControllerProvider);
    // if (profiles.length <= 4 && !isLoading) {
    //   fetchProfileRecs();
    // }
    print("Profilessssss: ${profiles.length}");
    final cards =
        profiles
            .map(
              (element) => Explorecard(
                receiverId: element.id,
                // senderId: widget.userId,
                profile: element,
              ),
            )
            .toList();
    print(profiles.map((element) => element.id).toList());
    return profiles.isEmpty && isLoading
        ? Center(child: CircularProgressIndicator()) // Show loader initially
        : profiles.isEmpty || profiles.length == 1
        ? Center(
          child: Text(
            "No profiles available right now",
            style: TextStyle(color: Colors.white),
          ),
        )
        : Scaffold(
          backgroundColor: AppColors.backgroundColor,
          body: CardSwiper(
            initialIndex: 1,
            controller: controller,
            cardBuilder:
                (context, index, percentThresholdX, percentThresholdY) =>
                    cards[index],
            scale: 0.9,
            isLoop: false,
            onEnd: () => {print("ended")},
            threshold: 100,
            cardsCount: cards.length,
            allowedSwipeDirection: AllowedSwipeDirection.all(),
            numberOfCardsDisplayed: 2,
            padding: EdgeInsets.all(0),
            backCardOffset: Offset(0, 0),

            onSwipe: (prevIndex, currentIndex, direction) async {
              if (direction == CardSwiperDirection.left) {
                final skippedUser =
                    profiles[prevIndex]; // the card that was just swiped
                print(profiles.map((element) => element.id).toList());
                print("Skipped user id: ${skippedUser.id}");
                print(skippedUser.id);
                ApiClient.dio.post(
                  '/skip',
                  data: {'skipped_id': skippedUser.id},
                );

                print(ref.read(profileListProvider));
                ref.read(profileListProvider.notifier).nextProfile();

                controller.moveTo(0);

                print(profiles.map((element) => element.id).toList());
                _maybeFetchMoreProfiles(); // 👈 HERE

                return true;
              } else if (direction == CardSwiperDirection.right) {
                final swipedUser =
                    profiles[prevIndex]; // the card that was just swiped

                final text =
                    ref
                        .watch(
                          opinionControllerProvider(profiles[prevIndex].id),
                        )
                        .text
                        .trim();
                if (text.isNotEmpty) {
                  ref
                      .read(opinionControllerProvider(profiles[prevIndex].id))
                      .clear();
                  ApiClient.dio.post(
                    '/opinion',
                    data: {'receiver_id': swipedUser.id, 'opinion': text},
                  );
                  ref.read(profileListProvider.notifier).nextProfile();
                  controller.moveTo(0);
                  print(profiles.map((element) => element.id).toList());
                  _maybeFetchMoreProfiles(); // 👈 HERE
                  print(profiles.map((element) => element.id).toList());

                  return true;
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Opinion Can't be empty!"),
                      duration: Duration(seconds: 2),
                    ),
                  );
                  return false;
                }
              }
              return false;
            },
          ),
        );
  }
}
