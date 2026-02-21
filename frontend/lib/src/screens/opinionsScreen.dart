import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:konnect/src/colors.dart';
import 'package:konnect/src/models/models.dart';
import 'package:konnect/src/services/api_service.dart';

final opinionsApiProvider = FutureProvider<void>((ref) async {
  final data = await _fetchOpinions();
  ref.read(opinionsProvider.notifier).setInitial(data);
});

final opinionsProvider =
    StateNotifierProvider<OpinionsNotifier, List<OpinionSummary>>(
      (ref) => OpinionsNotifier(),
    );
Future<List<OpinionSummary>> _fetchOpinions() async {
  try {
    // Example: Replace with your real API call
    final result1 = await ApiClient.dio.get('/opinions');
    final result = result1.data;
    final opinions =
        (result as List)
            .map((opinion) => OpinionSummary.fromJson(opinion))
            .toList();
    return opinions;
  } catch (e) {
    print('Error fetching opinions: $e');
    return [];
  }
}

class OpinionsNotifier extends StateNotifier<List<OpinionSummary>> {
  OpinionsNotifier() : super([]);

  void setInitial(List<OpinionSummary> initial) => state = initial;

  void addOpinionUpdate(OpinionSummary update) {
    state = [update, ...state]; // append to existing list
  }
}

class OpinionsScreen extends ConsumerWidget {
  const OpinionsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(opinionsApiProvider);
    ref.watch(wsListenerProvider);
    final opinions = ref.watch(opinionsProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: Center(
        child:
            opinions.isEmpty
                ? Text(
                  "Here will appear the first messages you receive.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white),
                )
                : Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ), // Padding for the list and screen edges
                  child: ListView.builder(
                    itemCount: opinions.length,
                    itemBuilder: (context, index) {
                      final opinion = opinions[index];
                      String profileUrl =
                          opinion.profileUrl ?? 'assets/images/profile.png';
                      return Padding(
                        padding: EdgeInsets.only(
                          bottom: 12.0,
                        ), // Space between list items
                        child: Row(
                          crossAxisAlignment:
                              CrossAxisAlignment.start, // Align items properly
                          children: [
                            Container(
                              height: 100,
                              width: 100,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(
                                  8.0,
                                ), // Rounded corners
                                child: ImageFiltered(
                                  imageFilter: ImageFilter.blur(
                                    sigmaX: 8,
                                    sigmaY: 8,
                                  ), // Blur effect
                                  child:
                                      profileUrl != "assets/images/profile.png"
                                          ? Image.network(
                                            profileUrl,
                                            width: 100,
                                            height: 100,
                                            fit: BoxFit.cover,
                                          )
                                          : Image.asset(
                                            "assets/images/profile.png",
                                            width: 100,
                                            height: 100,
                                            fit: BoxFit.cover,
                                          ),
                                ),
                              ),
                            ),
                            SizedBox(width: 12), // Space between image and text
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment
                                        .start, // Align text to the left
                                children: [
                                  // Space between text and sender
                                  Text(
                                    opinion
                                        .name, // Display the fetched username
                                    style: TextStyle(
                                      color: Colors.grey[400],
                                      fontSize: 14,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    (opinion.opinion.length > 50)
                                        ? opinion.opinion.substring(0, 45) +
                                            "..." // Show first 100 characters and append "..."
                                        : opinion
                                            .opinion, // Show the entire text if it's shorter than 100 chars
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
      ),
    );
  }
}
