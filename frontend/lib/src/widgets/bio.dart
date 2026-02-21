import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:konnect/src/services/api_service.dart';

class ProfileBio extends StatefulWidget {
  final String userBio;
  final TextEditingController bioController;
  final bool ownProfile;

  ProfileBio({
    Key? key,
    required this.userBio,
    required this.bioController,
    required this.ownProfile,
  }) : super(key: key);

  @override
  _ProfileBioState createState() => _ProfileBioState();
}

class _ProfileBioState extends State<ProfileBio> {
  bool _isEditing = false;
  String userBio = "Press the edit button to add bio.'";
  @override
  void initState() {
    super.initState();

    setState(() {
      userBio = widget.userBio;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          children: [
            if (widget.ownProfile)
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  onPressed: () async {
                    if (_isEditing) {
                      setState(() {
                        userBio = widget.bioController.text.trim() == ""
                            ? "Press the edit button to add bio."
                            : widget.bioController.text.trim();
                        _isEditing = false;
                      });

                      await ApiClient.dio.patch(
                        '/user',
                        data: {"bio": widget.bioController.text},
                      );
                    } else {
                      setState(() {
                        _isEditing = true;
                      });
                    }
                  },
                  icon: Icon(
                    _isEditing ? Icons.check : Icons.edit,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
        _isEditing
            ? TextField(
                controller: widget.bioController,
                style: const TextStyle(fontSize: 16, color: Colors.white),
                maxLines: null,
                maxLength: 500,
                decoration: const InputDecoration(
                  hintText: 'Edit your bio...',
                  hintStyle: TextStyle(color: Colors.white54),
                  border: InputBorder.none,
                ),
                inputFormatters: [
                  TextInputFormatter.withFunction((oldValue, newValue) {
                    int lineCount = '\n'.allMatches(newValue.text).length + 1;
                    if (lineCount > 10) {
                      return oldValue;
                    }
                    return newValue;
                  }),
                ],
              )
            : Text(
                userBio,
                style: const TextStyle(fontSize: 16, color: Colors.white70),
              ),
      ],
    );
  }
}
