import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/nostr_constants.dart';
import '../../../core/providers/app_providers.dart';
import '../../../models/community_label.dart';

/// Shows the bottom sheet to publish a Kind 1985 Community Label for a user.
void showAddCommunityLabelDialog(
  BuildContext context, {
  required String subjectPubkey,
  required String subjectName,
  String? targetEventId,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => CommunityLabelDialog(
      subjectPubkey: subjectPubkey,
      subjectName: subjectName,
      targetEventId: targetEventId,
    ),
  );
}

class CommunityLabelDialog extends ConsumerStatefulWidget {
  final String subjectPubkey;
  final String subjectName;
  final String? targetEventId;

  const CommunityLabelDialog({
    super.key,
    required this.subjectPubkey,
    required this.subjectName,
    this.targetEventId,
  });

  @override
  ConsumerState<CommunityLabelDialog> createState() => _CommunityLabelDialogState();
}

class _CommunityLabelDialogState extends ConsumerState<CommunityLabelDialog> {
  final TextEditingController _customTagController = TextEditingController();
  final TextEditingController _commentController = TextEditingController();
  String? _selectedTag;
  bool _isPublishing = false;

  @override
  void dispose() {
    _customTagController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  void _selectTag(String tag) {
    setState(() {
      _selectedTag = tag.trim().toLowerCase();
      _customTagController.text = _selectedTag!;
    });
  }

  Future<void> _publish() async {
    final tag = _selectedTag?.trim().toLowerCase() ??
        _customTagController.text.trim().toLowerCase().replaceAll('#', '');

    if (tag.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select or type a tag.')),
      );
      return;
    }

    setState(() => _isPublishing = true);

    try {
      final draft = CommunityLabel(
        id: '',
        authorPubkey: '',
        targetPubkey: widget.subjectPubkey,
        targetEventId: widget.targetEventId,
        tag: tag,
        namespace: NostrConstants.labelNamespaceTopic,
        comment: _commentController.text.trim(),
        createdAt: DateTime.now(),
      );

      await ref.read(communityLabelRepositoryProvider).publishLabel(draft);
      ref.invalidate(userLabelsStreamProvider(widget.subjectPubkey));

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Label "#$tag" published for ${widget.subjectName}!'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to publish label: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isPublishing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final moderation = ref.watch(moderationServiceProvider);
    final cautionTags = moderation.cautionTags;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Icon(Icons.label_outline_rounded, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Add Label for ${widget.subjectName}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Publish a signed community tag (NIP-32) endorsing a trait or noting a boundary.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 18),

            // Tier 1: General & Lifestyle Traits
            Text(
              'Traits, Rhythm & Lifestyle',
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: NostrConstants.defaultGeneralTags.map((t) {
                final isSelected = _selectedTag == t;
                return ChoiceChip(
                  label: Text('#$t'),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) _selectTag(t);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 18),

            // Tier 2: Cautionary & Boundary Tags
            Text(
              'Cautionary & Boundary Notes',
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.error,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Notices from your network regarding safety or host/guest friction.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: cautionTags.map((t) {
                final isSelected = _selectedTag == t;
                return ChoiceChip(
                  label: Text('#$t'),
                  selected: isSelected,
                  selectedColor: theme.colorScheme.errorContainer,
                  labelStyle: TextStyle(
                    color: isSelected
                        ? theme.colorScheme.onErrorContainer
                        : theme.colorScheme.error,
                    fontWeight: FontWeight.w600,
                  ),
                  side: BorderSide(
                    color: theme.colorScheme.error.withValues(alpha: 0.3),
                  ),
                  onSelected: (selected) {
                    if (selected) _selectTag(t);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Custom Tag Input
            TextField(
              controller: _customTagController,
              decoration: InputDecoration(
                labelText: 'Custom Tag (or select above)',
                prefixText: '#',
                hintText: 'e.g. sourdough_baker, early_riser',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
              ),
              onChanged: (val) {
                setState(() {
                  _selectedTag = val.trim().toLowerCase().replaceAll('#', '');
                });
              },
            ),
            const SizedBox(height: 14),

            // Optional Context/Comment
            TextField(
              controller: _commentController,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: 'Optional Note / Story (content)',
                hintText: 'e.g. Made a hell of a pasta dish, or late-night noise context...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _isPublishing ? null : () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: _isPublishing ? null : _publish,
                  icon: _isPublishing
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send_rounded, size: 16),
                  label: const Text('Publish Label'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
