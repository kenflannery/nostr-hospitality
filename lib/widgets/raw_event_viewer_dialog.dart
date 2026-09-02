import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ndk/entities.dart';
import '../models/hospitality_listing.dart';
import '../models/interaction_reference.dart';
import '../models/travel_profile.dart';
import '../models/user_profile.dart';

/// Shows an unobtrusive developer popup modal displaying the raw Nostr event JSON.
void showRawEventDialog(
  BuildContext context, {
  required String title,
  required dynamic event,
  String? description,
}) {
  showDialog(
    context: context,
    builder: (ctx) => RawEventViewerDialog(
      title: title,
      event: event,
      description: description,
    ),
  );
}

/// Formatted raw Nostr event JSON viewer for developers and curious users.
class RawEventViewerDialog extends StatelessWidget {
  final String title;
  final dynamic event;
  final String? description;

  const RawEventViewerDialog({
    super.key,
    required this.title,
    required this.event,
    this.description,
  });

  Map<String, dynamic> _extractEventMap(dynamic ev) {
    if (ev is Nip01Event) {
      return {
        if (ev.id.isNotEmpty) 'id': ev.id,
        'pubkey': ev.pubKey,
        'created_at': ev.createdAt,
        'kind': ev.kind,
        'tags': ev.tags,
        'content': ev.content,
        if (ev.sig != null && ev.sig!.isNotEmpty) 'sig': ev.sig,
      };
    } else if (ev is HospitalityListing) {
      final nip01 = ev.toNip01Event(authorPubkey: ev.authorPubkey);
      return _extractEventMap(nip01);
    } else if (ev is InteractionReference) {
      final nip01 = ev.toNip01Event(authorPubkey: ev.authorPubkey);
      return _extractEventMap(nip01);
    } else if (ev is TravelProfile) {
      final nip01 = ev.toNip01Event(authorPubkey: ev.authorPubkey);
      return _extractEventMap(nip01);
    } else if (ev is UserProfile) {
      final nip01 = ev.toNip01Event();
      return _extractEventMap(nip01);
    } else if (ev is Map<String, dynamic>) {
      return ev;
    } else {
      return {'raw': ev.toString()};
    }
  }

  int? _extractKind(Map<String, dynamic> map) {
    if (map['kind'] is int) return map['kind'] as int;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final eventMap = _extractEventMap(event);
    final kind = _extractKind(eventMap);
    final jsonString = const JsonEncoder.withIndent('  ').convert(eventMap);

    return AlertDialog(
      titlePadding: const EdgeInsets.fromLTRB(20, 18, 12, 0),
      contentPadding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.code_rounded,
              color: theme.colorScheme.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (kind != null || description != null)
                  Text(
                    description ?? 'Kind $kind Nostr Event',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.copy_rounded, size: 20),
            tooltip: 'Copy JSON',
            onPressed: () {
              Clipboard.setData(ClipboardData(text: jsonString));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Raw Nostr Event JSON copied to clipboard'),
                  duration: Duration(seconds: 2),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
        ],
      ),
      content: SizedBox(
        width: 580,
        height: 380,
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E24),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.1),
            ),
          ),
          padding: const EdgeInsets.all(14),
          child: SingleChildScrollView(
            child: SelectableText(
              jsonString,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 12.5,
                height: 1.45,
                color: Color(0xFF98C379),
              ),
            ),
          ),
        ),
      ),
      actions: [
        FilledButton.tonalIcon(
          onPressed: () {
            Clipboard.setData(ClipboardData(text: jsonString));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Raw Nostr Event JSON copied to clipboard'),
                duration: Duration(seconds: 2),
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
          icon: const Icon(Icons.copy_rounded, size: 16),
          label: const Text('Copy JSON'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
