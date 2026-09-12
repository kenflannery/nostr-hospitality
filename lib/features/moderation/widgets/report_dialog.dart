import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/nostr_constants.dart';
import '../../../core/providers/app_providers.dart';

/// Shows the NIP-56 report dialog for a user or listing.
void showReportDialog(
  BuildContext context, {
  String? targetPubkey,
  String? targetEventId,
  String? targetDisplayName,
}) {
  showDialog(
    context: context,
    builder: (ctx) => ReportDialog(
      targetPubkey: targetPubkey,
      targetEventId: targetEventId,
      targetDisplayName: targetDisplayName,
    ),
  );
}

class ReportDialog extends ConsumerStatefulWidget {
  final String? targetPubkey;
  final String? targetEventId;
  final String? targetDisplayName;

  const ReportDialog({
    super.key,
    this.targetPubkey,
    this.targetEventId,
    this.targetDisplayName,
  });

  @override
  ConsumerState<ReportDialog> createState() => _ReportDialogState();
}

class _ReportDialogState extends ConsumerState<ReportDialog> {
  String _selectedType = NostrConstants.reportSpam;
  final TextEditingController _contentController = TextEditingController();
  bool _alsoMute = true;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  String _getCategoryLabel(String type) {
    switch (type) {
      case NostrConstants.reportSpam:
        return 'Spam or Commercial Bot';
      case NostrConstants.reportNudity:
        return 'Nudity or Explicit Content';
      case NostrConstants.reportProfanity:
        return 'Hate Speech, Harassment, or Abuse';
      case NostrConstants.reportIllegal:
        return 'Illegal Activity';
      case NostrConstants.reportImpersonation:
        return 'Impersonation';
      case NostrConstants.reportOther:
      default:
        return 'Other Violation';
    }
  }

  Future<void> _submit() async {
    setState(() => _isSubmitting = true);

    try {
      final moderation = ref.read(moderationServiceProvider);
      await moderation.submitReport(
        targetPubkey: widget.targetPubkey,
        targetEventId: widget.targetEventId,
        reportType: _selectedType,
        content: _contentController.text.trim(),
        alsoMute: _alsoMute && widget.targetPubkey != null,
      );

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _alsoMute && widget.targetPubkey != null
                  ? 'Report submitted and user muted.'
                  : 'Report submitted.',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit report: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final targetName = widget.targetDisplayName ??
        (widget.targetEventId != null ? 'Listing' : 'Account');

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.flag_outlined, color: theme.colorScheme.error),
          const SizedBox(width: 8),
          Expanded(child: Text('Report $targetName')),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Publish a signed Kind 1984 report (NIP-56) to notify relay operators and client moderation filters.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Select Violation Type:',
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            ...NostrConstants.standardReportTypes.map((type) {
              // ignore: deprecated_member_use
              return RadioListTile<String>(
                title: Text(_getCategoryLabel(type), style: const TextStyle(fontSize: 13)),
                value: type,
                // ignore: deprecated_member_use
                groupValue: _selectedType,
                dense: true,
                contentPadding: EdgeInsets.zero,
                // ignore: deprecated_member_use
                onChanged: (val) {
                  if (val != null) setState(() => _selectedType = val);
                },
              );
            }),
            const SizedBox(height: 12),
            TextField(
              controller: _contentController,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: 'Details / Reason (Optional)',
                hintText: 'Describe the issue...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
              ),
            ),
            if (widget.targetPubkey != null) ...[
              const SizedBox(height: 12),
              CheckboxListTile(
                title: const Text('Also mute and block this user', style: TextStyle(fontSize: 13)),
                value: _alsoMute,
                dense: true,
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                onChanged: (val) {
                  setState(() => _alsoMute = val ?? true);
                },
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isSubmitting ? null : _submit,
          style: FilledButton.styleFrom(backgroundColor: theme.colorScheme.error),
          child: _isSubmitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                )
              : const Text('Submit Report'),
        ),
      ],
    );
  }
}
