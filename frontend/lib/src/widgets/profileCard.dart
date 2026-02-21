import 'package:flutter/material.dart';
import 'package:konnect/src/models/models.dart';
import 'package:konnect/src/utils/utils.dart';
import 'package:konnect/src/widgets/messageBubble.dart';

class ProfileCard extends StatelessWidget {
  final int receiverId;

  const ProfileCard({Key? key, required this.receiverId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // print(supportImages);
    return Expanded(
      child: Card(
        margin: EdgeInsets.only(top: 90, bottom: 90, left: 15, right: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Stack(
            children: [
              SingleChildScrollView(
                child: FutureBuilder<User?>(
                  future: loadUserData(receiverId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: const CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      return Text('Error: ${snapshot.error}');
                    } else {
                      User? profile = snapshot.data;
                      if (profile == null) {
                        return const Text('User data not found');
                      }
                      return Column(
                        children: [
                          Text(
                            '${profile.name} ${getFlagEmoji(profile.country)}, ${calculateAge(profile.birthday)} ',
                            style: TextStyle(
                              fontSize: 25,
                              fontFamily: "RobotoMono",
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          SizedBox(height: 5),

                          Container(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image(
                                image: NetworkImage(profile.profileUrl),
                              ),
                            ),
                          ),
                          SizedBox(height: 10),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              "Bio: ",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontFamily: "RobotoMono",
                                fontSize: 20,
                              ),
                            ),
                          ),
                          SizedBox(height: 10),

                          Text(profile.bio),

                          Column(
                            children: profile.imagesUrl.map((imageUrl) {
                              return Padding(
                                padding: EdgeInsets.symmetric(vertical: 5),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image(image: NetworkImage(imageUrl)),
                                ),
                              );
                            }).toList(),
                          ),
                          //     }
                          //   },
                          // ),
                          SizedBox(height: 80),

                          FutureBuilder<List<OpinionSummary>>(
                            future: fetchOpinions(receiverId),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return Center(
                                  child: CircularProgressIndicator(),
                                ); // Show loading indicator
                              }
                              if (snapshot.hasError) {
                                return Center(
                                  child: Text("Error loading opinions"),
                                );
                              } else {
                                List<OpinionSummary> sortedOpinions =
                                    snapshot.data ?? [];
                                print("Opinions loaded: ${snapshot.data}");

                                return Column(
                                  children: [
                                    Align(
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        "First Messages: ",
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontFamily: "RobotoMono",
                                          fontSize: 20,
                                        ),
                                      ),
                                    ),
                                    SizedBox(height: 10),
                                    for (OpinionSummary opinion
                                        in sortedOpinions)
                                      OpinionBubble(
                                        message: opinion.opinion,
                                        isMe: opinion.senderId != receiverId,
                                        firstMessage: true,
                                        finalMessage: true,
                                        isOpinion: true,
                                      ),
                                  ],
                                );
                              }
                            },
                          ),
                        ],
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void showProfileCard(context, otherUserId) {
  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: "ProfileCard",
    pageBuilder: (context, animation, secondaryAnimation) => SizedBox.shrink(),
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final curvedValue = Curves.easeInOut.transform(animation.value);
      return Transform.translate(
        offset: Offset(
          0,
          (1 - curvedValue) * MediaQuery.of(context).size.height,
        ),
        child: Opacity(
          opacity: animation.value,
          child: ProfileCard(receiverId: otherUserId),
        ),
      );
    },
    transitionDuration: Duration(milliseconds: 300),
  );
}
