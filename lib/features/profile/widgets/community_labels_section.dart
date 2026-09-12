import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/nip19_utils.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../models/community_label.dart';
import 'community_label_dialog.dart';

/// Renders the NIP-32 Community Labels section on a user profile,
/// grouped into General/Lifestyle traits and Cautionary/Safety notes.
class CommunityLabelsSection extends ConsumerWidget {
  final String subjectPubkey;
  final String subjectName;
  final bool isOwnProfile;

  const CommunityLabelsSection({
    super.key,
    required this.subjectPubkey,
    required this.subjectName,
    required this.isOwnProfile,
  });

  void _showTagDetailsDialog(
    BuildContext context,
    WidgetRef ref,
    String tag,
    List<CommunityLabel> labels,
    bool isCautionary,
  ) {
    final theme = Theme.of(context);
    final auth = ref.read(authStateProvider).valueOrNull;
    final myPubkey = auth?.pubkey;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(20),
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
                Icon(
                  isCautionary ? Icons.warning_amber_rounded : Icons.label_rounded,
                  color: isCautionary ? theme.colorScheme.error : theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  '#$tag (${labels.length})',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.45,
              ),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: labels.length,
                separatorBuilder: (_, __) => const Divider(height: 16),
                itemBuilder: (context, index) {
                  final label = labels[index];
                  final isMyLabel = myPubkey != null &&
                      label.authorPubkey.toLowerCase() == myPubkey.toLowerCase();

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: isCautionary
                            ? theme.colorScheme.errorContainer
                            : theme.colorScheme.primaryContainer,
                        child: Text(
                          label.authorPubkey.substring(0, 1).toUpperCase(),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isCautionary
                                ? theme.colorScheme.onErrorContainer
                                : theme.colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  isMyLabel ? 'You' : Nip19Helper.shortenKey(label.authorPubkey),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  DateFormatter.formatRelative(label.createdAt),
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: theme.colorScheme.outline,
                                  ),
                                ),
                              ],
                            ),
                            if (label.comment.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                label.comment,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (isMyLabel) ...[
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 18),
                          tooltip: 'Delete my label',
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (dCtx) => AlertDialog(
                                title: const Text('Delete Label?'),
                                content: Text('Remove your "#$tag" label for $subjectName?'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.of(dCtx).pop(false),
                                    child: const Text('Cancel'),
                                  ),
                                  FilledButton(
                                    onPressed: () => Navigator.of(dCtx).pop(true),
                                    child: const Text('Delete'),
                                  ),
                                ],
                              ),
                            );

                            if (confirm == true) {
                              try {
                                await ref
                                    .read(communityLabelRepositoryProvider)
                                    .deleteLabel(label.id, targetPubkey: subjectPubkey);
                                ref.invalidate(userLabelsStreamProvider(subjectPubkey));
                                if (ctx.mounted) Navigator.of(ctx).pop();
                              } catch (e) {
                                if (ctx.mounted) {
                                  ScaffoldMessenger.of(ctx).showSnackBar(
                                    SnackBar(content: Text('Failed to delete label: $e')),
                                  );
                                }
                              }
                            }
                          },
                        ),
                      ],
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final labelsAsync = ref.watch(userLabelsStreamProvider(subjectPubkey));
    final labels = labelsAsync.valueOrNull ?? [];
    final moderation = ref.watch(moderationServiceProvider);

    // Group labels by tag
    final Map<String, List<CommunityLabel>> tagMap = {};
    for (final l in labels) {
      tagMap.putIfAbsent(l.tag, () => []).add(l);
    }

    final lifestyleTags = <String>[];
    final cautionaryTags = <String>[];

    for (final tag in tagMap.keys) {
      if (moderation.isCautionary(tag)) {
        cautionaryTags.add(tag);
      } else {
        lifestyleTags.add(tag);
      }
    }

    lifestyleTags.sort((a, b) => tagMap[b]!.length.compareTo(tagMap[a]!.length));
    cautionaryTags.sort((a, b) => tagMap[b]!.length.compareTo(tagMap[a]!.length));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.label_outline_rounded, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              'Community Labels',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            if (!isOwnProfile)
              TextButton.icon(
                onPressed: () => showAddCommunityLabelDialog(
                  context,
                  subjectPubkey: subjectPubkey,
                  subjectName: subjectName,
                ),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add Label'),
              ),
          ],
        ),
        const SizedBox(height: 8),

        if (labels.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6.0),
            child: Text(
              isOwnProfile
                  ? 'No community labels have been published for your profile yet.'
                  : 'No community labels published for this profile yet. Tap "Add Label" to endorse a trait or note a boundary.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          )
        else ...[
          // Group 1: General & Lifestyle Traits
          if (lifestyleTags.isNotEmpty) ...[
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: lifestyleTags.map((tag) {
                final count = tagMap[tag]?.length ?? 0;
                return ActionChip(
                  avatar: const Icon(Icons.tag_rounded, size: 14),
                  label: Text('#$tag ($count)'),
                  onPressed: () => _showTagDetailsDialog(
                    context,
                    ref,
                    tag,
                    tagMap[tag]!,
                    false,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
          ],

          // Group 2: Cautionary & Safety Notes
          if (cautionaryTags.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.errorContainer.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.colorScheme.error.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        size: 16,
                        color: theme.colorScheme.error,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Community Advisories',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: theme.colorScheme.error,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: cautionaryTags.map((tag) {
                      final count = tagMap[tag]?.length ?? 0;
                      return ActionChip(
                        avatar: Icon(
                          Icons.report_problem_outlined,
                          size: 14,
                          color: theme.colorScheme.error,
                        ),
                        label: Text(
                          '#$tag ($count)',
                          style: TextStyle(
                            color: theme.colorScheme.error,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        backgroundColor: theme.colorScheme.errorContainer,
                        side: BorderSide(
                          color: theme.colorScheme.error.withValues(alpha: 0.4),
                        ),
                        onPressed: () => _showTagDetailsDialog(
                          context,
                          ref,
                          tag,
                          tagMap[tag]!,
                          true,
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ],
        ],
      ],
    );
  }
}
