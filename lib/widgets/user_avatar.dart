import 'package:flutter/material.dart';
import '../core/theme/procedural_art.dart';

/// Reusable user avatar with network image loading, deterministic procedural gradient
/// fallbacks, optional border rings, and depth drop-shadows.
class UserAvatar extends StatelessWidget {
  final String? imageUrl;
  final String nameOrPubkey;
  final String? pubkey;
  final double radius;
  final VoidCallback? onTap;
  final double borderWidth;
  final Color? borderColor;
  final bool hasShadow;

  const UserAvatar({
    super.key,
    this.imageUrl,
    required this.nameOrPubkey,
    this.pubkey,
    this.radius = 20,
    this.onTap,
    this.borderWidth = 0.0,
    this.borderColor,
    this.hasShadow = false,
  });

  @override
  Widget build(BuildContext context) {
    final initial = nameOrPubkey.isNotEmpty ? nameOrPubkey[0].toUpperCase() : '?';
    final seed = pubkey ?? nameOrPubkey;
    final hasImage = imageUrl != null && imageUrl!.trim().isNotEmpty;

    Widget avatar = Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: borderWidth > 0
            ? Border.all(
                color: borderColor ?? Colors.white,
                width: borderWidth,
              )
            : null,
        boxShadow: hasShadow
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.16),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ]
            : null,
      ),
      child: ClipOval(
        child: hasImage
            ? Image.network(
                imageUrl!.trim(),
                width: radius * 2,
                height: radius * 2,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _buildFallback(context, initial, seed),
              )
            : _buildFallback(context, initial, seed),
      ),
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

  Widget _buildFallback(BuildContext context, String initial, String seed) {
    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        gradient: ProceduralArt.getGradient(seed),
      ),
      child: Center(
        child: Text(
          initial,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: radius * 0.85,
            shadows: const [
              Shadow(
                color: Colors.black38,
                offset: Offset(0, 1),
                blurRadius: 2,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

