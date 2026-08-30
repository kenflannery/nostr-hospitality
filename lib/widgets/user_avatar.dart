import 'package:flutter/material.dart';

/// Reusable user avatar with network image loading, fallback initials, and cached state.
class UserAvatar extends StatelessWidget {
  final String? imageUrl;
  final String nameOrPubkey;
  final double radius;
  final VoidCallback? onTap;

  const UserAvatar({
    super.key,
    this.imageUrl,
    required this.nameOrPubkey,
    this.radius = 20,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final initial = nameOrPubkey.isNotEmpty ? nameOrPubkey[0].toUpperCase() : '?';

    Widget avatar = CircleAvatar(
      radius: radius,
      backgroundColor: theme.colorScheme.primaryContainer,
      child: imageUrl != null && imageUrl!.trim().isNotEmpty
          ? ClipOval(
              child: Image.network(
                imageUrl!.trim(),
                width: radius * 2,
                height: radius * 2,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _buildFallback(theme, initial),
              ),
            )
          : _buildFallback(theme, initial),
    );

    if (onTap != null) {
      avatar = InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: avatar,
      );
    }

    return avatar;
  }

  Widget _buildFallback(ThemeData theme, String initial) {
    return Center(
      child: Text(
        initial,
        style: TextStyle(
          color: theme.colorScheme.onPrimaryContainer,
          fontWeight: FontWeight.bold,
          fontSize: radius * 0.9,
        ),
      ),
    );
  }
}
