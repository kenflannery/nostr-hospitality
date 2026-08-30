import 'package:flutter/material.dart';
import '../core/constants/nostr_constants.dart';
import '../core/theme/app_theme.dart';

/// Renders a color-coded sentiment pill for Kind 7654 references.
class SentimentBadge extends StatelessWidget {
  final String? sentiment;
  final bool compact;

  const SentimentBadge({
    super.key,
    required this.sentiment,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (sentiment == null || sentiment!.isEmpty) {
      return const SizedBox.shrink();
    }

    final s = sentiment!.toLowerCase();
    Color bgColor;
    Color fgColor;
    IconData icon;
    String label;

    if (s == NostrConstants.sentimentPositive) {
      bgColor = AppTheme.positiveGreen.withValues(alpha: 0.12);
      fgColor = AppTheme.positiveGreen;
      icon = Icons.thumb_up_alt_rounded;
      label = 'Positive';
    } else if (s == NostrConstants.sentimentNegative) {
      bgColor = AppTheme.negativeRed.withValues(alpha: 0.12);
      fgColor = AppTheme.negativeRed;
      icon = Icons.thumb_down_alt_rounded;
      label = 'Negative';
    } else if (s == NostrConstants.sentimentNeutral) {
      bgColor = AppTheme.neutralGrey.withValues(alpha: 0.12);
      fgColor = AppTheme.neutralGrey;
      icon = Icons.remove_circle_outline_rounded;
      label = 'Neutral';
    } else {
      bgColor = Colors.grey.withValues(alpha: 0.12);
      fgColor = Colors.grey;
      icon = Icons.info_outline;
      label = sentiment!;
    }

    if (compact) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: fgColor),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: fgColor,
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: fgColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: fgColor,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
