import 'package:flutter/material.dart';
import '../core/constants/nostr_constants.dart';

/// Renders a role tag badge for reference authors or profile listings.
class RoleBadge extends StatelessWidget {
  final String? role;

  const RoleBadge({
    super.key,
    required this.role,
  });

  @override
  Widget build(BuildContext context) {
    if (role == null || role!.isEmpty) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final r = role!.toLowerCase();

    IconData icon;
    String label;

    if (r == NostrConstants.roleHost) {
      icon = Icons.home_rounded;
      label = 'Host';
    } else if (r == NostrConstants.roleGuest) {
      icon = Icons.luggage_rounded;
      label = 'Guest';
    } else if (r == NostrConstants.roleTraveler ||
        r == NostrConstants.roleTravelCompanion) {
      icon = Icons.explore_rounded;
      label = 'Traveler';
    } else {
      icon = Icons.person_outline_rounded;
      label = role![0].toUpperCase() + role!.substring(1);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: theme.colorScheme.onSecondaryContainer),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: theme.colorScheme.onSecondaryContainer,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
