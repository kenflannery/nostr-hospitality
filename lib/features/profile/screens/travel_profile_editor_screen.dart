import 'package:flutter/material.dart';
import '../../../models/travel_profile.dart';
import 'edit_profile_screen.dart';

/// Legacy entry point for Kind 30602 profile editor, now forwarding to the unified [EditProfileScreen].
class TravelProfileEditorScreen extends StatelessWidget {
  final TravelProfile? initialProfile;

  const TravelProfileEditorScreen({super.key, this.initialProfile});

  @override
  Widget build(BuildContext context) {
    return EditProfileScreen(initialTravelProfile: initialProfile);
  }
}
