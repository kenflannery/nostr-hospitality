import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/nostr_constants.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/hospitality_listing.dart';
import '../../../models/interaction_reference.dart';

/// Screen to compose and publish a Kind 7654 Interaction Reference.
class ReferenceComposerScreen extends ConsumerStatefulWidget {
  final String subjectPubkey;
  final String? subjectName;
  final HospitalityListing? initialListing;

  const ReferenceComposerScreen({
    super.key,
    required this.subjectPubkey,
    this.subjectName,
    this.initialListing,
  });

  @override
  ConsumerState<ReferenceComposerScreen> createState() =>
      _ReferenceComposerScreenState();
}

class _ReferenceComposerScreenState
    extends ConsumerState<ReferenceComposerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _contentController = TextEditingController();
  final _tagInputController = TextEditingController();

  String _selectedContext = NostrConstants.contextHospitality;
  String _selectedRole = NostrConstants.roleGuest;
  String? _selectedSentiment = NostrConstants.sentimentPositive;
  String? _associatedAddress;
  final List<String> _selectedTags = [];
  bool _isSubmitting = false;

  static const List<String> _suggestedTags = [
    'communicative',
    'inspiring',
    'prompt',
    'respectful',
    'clean',
    'friendly',
    'flexible',
    'generous',
    'reliable',
    'great_cook',
    'punctual',
    'easygoing',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialListing != null) {
      _associatedAddress = widget.initialListing!.addressCoordinate;
    }
  }

  @override
  void dispose() {
    _contentController.dispose();
    _tagInputController.dispose();
    super.dispose();
  }

  void _addCustomTag() {
    final text = _tagInputController.text.trim().toLowerCase().replaceAll('#', '');
    if (text.isNotEmpty && !_selectedTags.contains(text)) {
      setState(() {
        _selectedTags.add(text);
        _tagInputController.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subjectDisplay = widget.subjectName ?? 'Host/Traveler';

    return Scaffold(
      appBar: AppBar(
        title: Text('Leave Reference for $subjectDisplay'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Share your experience with $subjectDisplay',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'References are signed historical statements published to Nostr relays. They build portable, decentralized trust.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),

              // Interaction Context
              Text(
                'Interaction Context',
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _selectedContext,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.category_outlined),
                ),
                items: NostrConstants.standardContexts.map((ctx) {
                  final label = ctx == 'work_exchange'
                      ? 'Work Exchange'
                      : ctx[0].toUpperCase() + ctx.substring(1);
                  return DropdownMenuItem(
                    value: ctx,
                    child: Text(label),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _selectedContext = val);
                  }
                },
              ),
              const SizedBox(height: 20),

              // Author's Role
              Text(
                'Your Role in the Interaction',
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _selectedRole,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.badge_outlined),
                ),
                items: NostrConstants.standardRoles.map((role) {
                  final label = role == 'travel_companion'
                      ? 'Travel Companion'
                      : role[0].toUpperCase() + role.substring(1);
                  return DropdownMenuItem(
                    value: role,
                    child: Text(label),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _selectedRole = val);
                  }
                },
              ),
              const SizedBox(height: 20),

              // Optional Sentiment Selector
              Text(
                'Overall Sentiment (Optional)',
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  _buildSentimentChoice(
                    sentiment: NostrConstants.sentimentPositive,
                    label: 'Positive',
                    icon: Icons.thumb_up_alt_rounded,
                    color: AppTheme.positiveGreen,
                  ),
                  _buildSentimentChoice(
                    sentiment: NostrConstants.sentimentNeutral,
                    label: 'Neutral',
                    icon: Icons.remove_circle_outline_rounded,
                    color: AppTheme.neutralGrey,
                  ),
                  _buildSentimentChoice(
                    sentiment: NostrConstants.sentimentNegative,
                    label: 'Negative',
                    icon: Icons.thumb_down_alt_rounded,
                    color: AppTheme.negativeRed,
                  ),
                  _buildSentimentChoice(
                    sentiment: null,
                    label: 'None',
                    icon: Icons.not_interested_rounded,
                    color: Colors.grey,
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Reference Content
              Text(
                'Reference Statement',
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _contentController,
                maxLines: 5,
                decoration: const InputDecoration(
                  hintText:
                      'Describe your stay, hospitality, communication, or experience...',
                  alignLabelWithHint: true,
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please enter reference text';
                  }
                  if (val.trim().length < 10) {
                    return 'Reference should be at least 10 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Interaction Tags & Traits (t tags)
              Text(
                'Interaction Tags & Traits (Optional)',
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                'Highlight specific qualities of the interaction (e.g. communicative, clean, inspiring).',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),

              // Selected Tags
              if (_selectedTags.isNotEmpty) ...[
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: _selectedTags.map((tag) {
                    return Chip(
                      label: Text('#$tag'),
                      deleteIcon: const Icon(Icons.close_rounded, size: 16),
                      onDeleted: () {
                        setState(() => _selectedTags.remove(tag));
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 8),
              ],

              // Suggested Quick Tags
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: _suggestedTags.map((tag) {
                  final isAdded = _selectedTags.contains(tag);
                  return FilterChip(
                    label: Text(tag),
                    selected: isAdded,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedTags.add(tag);
                        } else {
                          _selectedTags.remove(tag);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 10),

              // Custom tag input
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _tagInputController,
                      decoration: const InputDecoration(
                        hintText: 'Add custom tag...',
                        prefixIcon: Icon(Icons.tag_rounded, size: 18),
                        isDense: true,
                      ),
                      onSubmitted: (_) => _addCustomTag(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filledTonal(
                    onPressed: _addCustomTag,
                    icon: const Icon(Icons.add_rounded),
                    tooltip: 'Add tag',
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Associated Hosting Listing Coordinate if any
              if (_associatedAddress != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.link_rounded,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Linked Hosting Offer',
                              style: theme.textTheme.labelMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              _associatedAddress!,
                              style: theme.textTheme.bodySmall,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 18),
                        onPressed: () {
                          setState(() => _associatedAddress = null);
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Submit button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton(
                  onPressed: _isSubmitting ? null : _submitReference,
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Publish Reference',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSentimentChoice({
    required String? sentiment,
    required String label,
    required IconData icon,
    required Color color,
  }) {
    final isSelected = _selectedSentiment == sentiment;
    return ChoiceChip(
      selected: isSelected,
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: isSelected ? color : Colors.grey),
          const SizedBox(width: 6),
          Text(label),
        ],
      ),
      onSelected: (selected) {
        if (selected) {
          setState(() => _selectedSentiment = sentiment);
        }
      },
    );
  }

  void _submitReference() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = ref.read(authStateProvider).valueOrNull;
    if (auth == null || !auth.isAuthenticated || auth.pubkey == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please authenticate before leaving references')),
      );
      return;
    }

    if (auth.pubkey == widget.subjectPubkey) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You cannot leave a reference for yourself')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final repo = ref.read(referenceRepositoryProvider);
      final draft = InteractionReference(
        id: '',
        authorPubkey: auth.pubkey!,
        subjectPubkey: widget.subjectPubkey,
        content: _contentController.text.trim(),
        createdAt: DateTime.now(),
        contexts: [_selectedContext],
        role: _selectedRole,
        sentiment: _selectedSentiment,
        associatedAddress: _associatedAddress,
        tags: _selectedTags,
      );
      await repo.publishReference(draft);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reference published to Nostr relays!')),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error publishing reference: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }
}
