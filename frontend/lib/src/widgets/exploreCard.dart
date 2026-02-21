import 'package:flutter/material.dart';
import 'package:konnect/src/colors.dart';
import 'package:konnect/src/models/models.dart';
import 'package:konnect/src/utils/utils.dart';
import 'package:konnect/src/widgets/sendOpinion.dart';

class Explorecard extends StatefulWidget {
  // final String profileImage;
  // final List<String> supportImages;
  final UserExploreSummary profile;
  final receiverId;

  const Explorecard({
    Key? key,
    required this.receiverId,
    required this.profile,
    // required this.profileImage,
    // required this.supportImages,
  }) : super(key: key);

  @override
  State<Explorecard> createState() => _ExplorecardState();
}

class _ExplorecardState extends State<Explorecard> {
  late final ScrollController _scrollController;

  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void didUpdateWidget(covariant Explorecard oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Profile changed → reset scroll to top
    if (oldWidget.profile.id != widget.profile.id) {
      _scrollController.jumpTo(0);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profile = widget.profile;
    List<String> supportImages = profile.imagesUrl;
    String profileImage = profile.profileUrl;
    print(supportImages);
    return Card(
      color: AppColors.cardColor,
      margin: EdgeInsets.all(10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Stack(
          children: [
            SingleChildScrollView(
              controller: _scrollController, // 👈 IMPORTANT

              child: Column(
                children: [
                  Text(
                    '${profile.name} ${getFlagEmoji(profile.country)}, ${profile.age} ',
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
                      child:
                          profileImage != 'assets/images/profile.png'
                              ? Image(image: NetworkImage(profileImage))
                              : Image.asset('assets/images/profile.png'),
                    ),
                  ),
                  SizedBox(height: 10),
                  if (profile.bio != "")
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
                    children:
                        supportImages.map((imageUrl) {
                          return Padding(
                            padding: EdgeInsets.symmetric(vertical: 5),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image(image: NetworkImage(imageUrl)),
                            ),
                          );
                        }).toList(),
                  ),
                  SizedBox(height: 80),
                ],
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: SendOpinion(
                profile_id: profile.id,
                receiverUserId: widget.receiverId,
                profileImage: profileImage,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
