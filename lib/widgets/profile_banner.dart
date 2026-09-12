import 'package:flutter/material.dart';
import '../core/theme/procedural_art.dart';

/// Renders a profile banner with network image support, graceful failure handling,
/// and a pubkey-seeded procedural topographic landscape gradient fallback.
class ProfileBanner extends StatelessWidget {
  final String? bannerUrl;
  final String pubkey;
  final double height;
  final Widget? overlay;

  const ProfileBanner({
    super.key,
    this.bannerUrl,
    required this.pubkey,
    this.height = 155.0,
    this.overlay,
  });

  @override
  Widget build(BuildContext context) {
    final hasUrl = bannerUrl != null && bannerUrl!.trim().isNotEmpty;

    Widget bannerContent;
    if (hasUrl) {
      bannerContent = Image.network(
        bannerUrl!.trim(),
        width: double.infinity,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildProceduralFallback(),
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return _buildProceduralFallback();
        },
      );
    } else {
      bannerContent = _buildProceduralFallback();
    }

    return SizedBox(
      width: double.infinity,
      height: height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          bannerContent,
          if (overlay != null) overlay!,
        ],
      ),
    );
  }

  Widget _buildProceduralFallback() {
    return Container(
      width: double.infinity,
      height: height,
      decoration: BoxDecoration(
        gradient: ProceduralArt.getGradient(pubkey),
      ),
      child: CustomPaint(
        painter: TopographicContourPainter(
          seed: pubkey,
          strokeColor: Colors.white,
        ),
      ),
    );
  }
}
