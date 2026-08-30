import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/app_providers.dart';
import '../../../models/travel_profile.dart';

/// Screen to create or edit a Kind 30602 Travel & Community Profile.
class TravelProfileEditorScreen extends ConsumerStatefulWidget {
  final TravelProfile? initialProfile;

  const TravelProfileEditorScreen({super.key, this.initialProfile});

  @override
  ConsumerState<TravelProfileEditorScreen> createState() => _TravelProfileEditorScreenState();
}

class _TravelProfileEditorScreenState extends ConsumerState<TravelProfileEditorScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _contentController;
  late TextEditingController _originCityController;
  late TextEditingController _originCountryController;
  late TextEditingController _homeCityController;
  late TextEditingController _homeCountryController;
  late TextEditingController _occupationController;
  late TextEditingController _educationController;
  late TextEditingController _birthYearController;

  String? _gender;
  final Set<String> _selectedModes = {};
  final List<LanguageProficiency> _languages = [];
  final List<String> _interests = [];
  final List<ExternalIdentity> _externalIdentities = [];

  final TextEditingController _customInterestController = TextEditingController();

  bool _isSaving = false;

  final List<String> _availableInterests = const [
    'hiking', 'cycling', 'cooking', 'music', 'art', 'reading',
    'photography', 'nostr', 'open_source', 'van_life', 'camping',
    'surfing', 'yoga', 'coffee', 'philosophy', 'board_games',
  ];

  @override
  void initState() {
    super.initState();
    final init = widget.initialProfile;

    _contentController = TextEditingController(text: init?.content ?? '');
    _originCityController = TextEditingController(text: init?.originCity ?? '');
    _originCountryController = TextEditingController(text: init?.originCountry ?? '');
    _homeCityController = TextEditingController(text: init?.homeCity ?? '');
    _homeCountryController = TextEditingController(text: init?.homeCountry ?? '');
    _occupationController = TextEditingController(text: init?.occupation ?? '');
    _educationController = TextEditingController(text: init?.education ?? '');
    _birthYearController = TextEditingController(
      text: init?.birthYear != null ? init!.birthYear.toString() : '',
    );

    _gender = init?.gender;
    if (init != null) {
      _selectedModes.addAll(init.modes);
      _languages.addAll(init.languages);
      _interests.addAll(init.interests);
      _externalIdentities.addAll(init.externalIdentities);
    }
  }

  @override
  void dispose() {
    _contentController.dispose();
    _originCityController.dispose();
    _originCountryController.dispose();
    _homeCityController.dispose();
    _homeCountryController.dispose();
    _occupationController.dispose();
    _educationController.dispose();
    _birthYearController.dispose();
    _customInterestController.dispose();
    super.dispose();
  }

  void _addLanguageDialog() {
    String selectedCode = 'en';
    String selectedLevel = 'fluent';

    const languageOptions = {
      'en': 'English',
      'es': 'Spanish',
      'fr': 'French',
      'de': 'German',
      'it': 'Italian',
      'pt': 'Portuguese',
      'ru': 'Russian',
      'zh': 'Chinese',
      'ja': 'Japanese',
      'ko': 'Korean',
      'ar': 'Arabic',
      'hi': 'Hindi',
      'nl': 'Dutch',
      'pl': 'Polish',
      'tr': 'Turkish',
      'sv': 'Swedish',
      'vi': 'Vietnamese',
      'id': 'Indonesian',
    };

    const levelOptions = ['native', 'fluent', 'intermediate', 'learning'];

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Add Language'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: selectedCode,
                    decoration: const InputDecoration(labelText: 'Language'),
                    items: languageOptions.entries
                        .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setDialogState(() => selectedCode = val);
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: selectedLevel,
                    decoration: const InputDecoration(labelText: 'Proficiency Level'),
                    items: levelOptions
                        .map((e) => DropdownMenuItem(
                              value: e,
                              child: Text(e[0].toUpperCase() + e.substring(1)),
                            ))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setDialogState(() => selectedLevel = val);
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    setState(() {
                      _languages.removeWhere((l) => l.code == selectedCode);
                      _languages.add(LanguageProficiency(code: selectedCode, level: selectedLevel));
                    });
                    Navigator.of(ctx).pop();
                  },
                  child: const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _addExternalIdentityDialog() {
    String platform = 'trustroots';
    final userCtrl = TextEditingController();

    const platforms = [
      'trustroots',
      'couchsurfing',
      'warmshowers',
      'bewelcome',
      'blablacar',
      'github',
      'mastodon',
    ];

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Link Legacy & External Profile'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: platform,
                    decoration: const InputDecoration(labelText: 'Network / Platform'),
                    items: platforms
                        .map((p) => DropdownMenuItem(
                              value: p,
                              child: Text(p[0].toUpperCase() + p.substring(1)),
                            ))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setDialogState(() => platform = val);
                    },
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: userCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Username or Profile Handle',
                      hintText: 'e.g. alice_travels',
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    final username = userCtrl.text.trim();
                    if (username.isNotEmpty) {
                      setState(() {
                        _externalIdentities.removeWhere((e) => e.platform == platform);
                        _externalIdentities.add(ExternalIdentity(platform: platform, username: username));
                      });
                    }
                    Navigator.of(ctx).pop();
                  },
                  child: const Text('Link Account'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEditing = widget.initialProfile != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Travel Profile' : 'Create Travel Profile'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: FilledButton.icon(
              onPressed: _isSaving ? null : _saveProfile,
              icon: _isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.check_rounded, size: 18),
              label: Text(isEditing ? 'Save' : 'Publish'),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20.0),
          children: [
            // --- SECTION 1: Active Interaction Modes ---
            Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.hub_outlined, color: theme.colorScheme.primary),
                        const SizedBox(width: 8),
                        Text(
                          'Active Interaction Modes',
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Select the real-world peer-to-peer activities you are open to participating in.',
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 14),

                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildModeChip('host', '🏠 Hosting Travelers'),
                        _buildModeChip('guest', '🎒 Traveling / Surfing'),
                        _buildModeChip('meetup', '☕ Local Hangouts & Coffee'),
                        _buildModeChip('rideshare', '🚗 Rideshare / Carpool'),
                        _buildModeChip('language_exchange', '🗣️ Language Exchange'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // --- SECTION 2: Languages Spoken ---
            Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.translate_rounded, color: theme.colorScheme.primary),
                        const SizedBox(width: 8),
                        Text(
                          'Languages Spoken',
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const Spacer(),
                        TextButton.icon(
                          onPressed: _addLanguageDialog,
                          icon: const Icon(Icons.add_rounded, size: 18),
                          label: const Text('Add'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    if (_languages.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Text(
                          'No languages added yet. Tap "+ Add" to specify languages you speak.',
                          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
                        ),
                      )
                    else
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _languages.map((lang) {
                          return Chip(
                            avatar: const Icon(Icons.language_rounded, size: 16),
                            label: Text(lang.displayName),
                            onDeleted: () {
                              setState(() => _languages.remove(lang));
                            },
                          );
                        }).toList(),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // --- SECTION 3: Traveler Story & Philosophy ---
            Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.auto_stories_outlined, color: theme.colorScheme.primary),
                        const SizedBox(width: 8),
                        Text(
                          'About You & Travel Philosophy',
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Why do you use hospitality networks? What are your travel experiences and passions?',
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _contentController,
                      maxLines: 5,
                      decoration: const InputDecoration(
                        hintText: 'Share your travel background, lifestyle, passions, and what cultural exchange means to you...',
                        alignLabelWithHint: true,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // --- SECTION 4: Origins & Demographics (Optional) ---
            Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.badge_outlined, color: theme.colorScheme.primary),
                        const SizedBox(width: 8),
                        Text(
                          'Origins & Personal Background (Optional)',
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Origin vs Home
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _originCityController,
                            decoration: const InputDecoration(
                              labelText: 'Grew up / Origin City',
                              hintText: 'e.g. Munich',
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _originCountryController,
                            decoration: const InputDecoration(
                              labelText: 'Origin Country',
                              hintText: 'e.g. Germany',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _homeCityController,
                            decoration: const InputDecoration(
                              labelText: 'Current Home City',
                              hintText: 'e.g. Lyon',
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _homeCountryController,
                            decoration: const InputDecoration(
                              labelText: 'Current Country',
                              hintText: 'e.g. France',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Gender & Birth Year
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String?>(
                            initialValue: _gender,
                            decoration: const InputDecoration(labelText: 'Gender'),
                            items: const [
                              DropdownMenuItem(value: null, child: Text('— Unspecified')),
                              DropdownMenuItem(value: 'female', child: Text('Female')),
                              DropdownMenuItem(value: 'male', child: Text('Male')),
                              DropdownMenuItem(value: 'non-binary', child: Text('Non-binary')),
                              DropdownMenuItem(value: 'other', child: Text('Other')),
                            ],
                            onChanged: (val) => setState(() => _gender = val),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _birthYearController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Birth Year',
                              hintText: 'e.g. 1995',
                              helperText: _birthYearController.text.isNotEmpty
                                  ? 'Age: ~${DateTime.now().year - (int.tryParse(_birthYearController.text) ?? DateTime.now().year)}'
                                  : null,
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _occupationController,
                      decoration: const InputDecoration(
                        labelText: 'Occupation / Field',
                        hintText: 'e.g. Software Engineer / Photographer',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // --- SECTION 5: Interests & Topics ---
            Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.interests_outlined, color: theme.colorScheme.primary),
                        const SizedBox(width: 8),
                        Text(
                          'Interests & Passions',
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _availableInterests.map((interest) {
                        final isSelected = _interests.contains(interest);
                        return FilterChip(
                          label: Text('#$interest'),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _interests.add(interest);
                              } else {
                                _interests.remove(interest);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // --- SECTION 6: External Identity & Legacy Links (NIP-39) ---
            Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.link_rounded, color: theme.colorScheme.primary),
                        const SizedBox(width: 8),
                        Text(
                          'Linked Networks & Reputation',
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const Spacer(),
                        TextButton.icon(
                          onPressed: _addExternalIdentityDialog,
                          icon: const Icon(Icons.add_link_rounded, size: 18),
                          label: const Text('Link Account'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Link your profiles on Trustroots, Couchsurfing, WarmShowers, BeWelcome, or GitHub to import cross-network trust.',
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 12),

                    if (_externalIdentities.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6.0),
                        child: Text(
                          'No external accounts linked yet.',
                          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
                        ),
                      )
                    else
                      Column(
                        children: _externalIdentities.map((id) {
                          return ListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(Icons.verified_outlined, size: 20),
                            title: Text('${id.platformName}: @${id.username}'),
                            trailing: IconButton(
                              icon: const Icon(Icons.close_rounded, size: 18),
                              onPressed: () {
                                setState(() => _externalIdentities.remove(id));
                              },
                            ),
                          );
                        }).toList(),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            FilledButton.icon(
              onPressed: _isSaving ? null : _saveProfile,
              style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
              icon: const Icon(Icons.cloud_upload_rounded),
              label: Text(
                isEditing ? 'Save & Broadcast Travel Profile' : 'Publish Travel Profile (Kind 30602)',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildModeChip(String mode, String label) {
    final isSelected = _selectedModes.contains(mode);
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          if (selected) {
            _selectedModes.add(mode);
          } else {
            _selectedModes.remove(mode);
          }
        });
      },
    );
  }

  void _saveProfile() async {
    final authState = ref.read(authStateProvider).valueOrNull;
    if (authState == null || !authState.isAuthenticated || authState.pubkey == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in with your Nostr keys to publish a profile')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final repo = ref.read(profileRepositoryProvider);
      final myPubkey = authState.pubkey!;
      final existing = widget.initialProfile;

      final birthYear = int.tryParse(_birthYearController.text.trim());

      final updatedProfile = TravelProfile(
        eventId: existing?.eventId ?? '',
        authorPubkey: myPubkey,
        dTag: existing?.dTag ?? 'travel-profile',
        content: _contentController.text.trim(),
        createdAt: DateTime.now(),
        gender: _gender,
        birthYear: birthYear,
        originCountry: _originCountryController.text.trim().isNotEmpty ? _originCountryController.text.trim() : null,
        originCity: _originCityController.text.trim().isNotEmpty ? _originCityController.text.trim() : null,
        homeCountry: _homeCountryController.text.trim().isNotEmpty ? _homeCountryController.text.trim() : null,
        homeCity: _homeCityController.text.trim().isNotEmpty ? _homeCityController.text.trim() : null,
        occupation: _occupationController.text.trim().isNotEmpty ? _occupationController.text.trim() : null,
        education: _educationController.text.trim().isNotEmpty ? _educationController.text.trim() : null,
        languages: _languages,
        modes: _selectedModes.toList(),
        interests: _interests,
        externalIdentities: _externalIdentities,
      );

      await repo.saveTravelProfile(updatedProfile);

      // Invalidate provider so profile screen immediately updates
      ref.invalidate(userTravelProfileProvider(myPubkey));
      ref.invalidate(currentUserTravelProfileProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Travel Profile updated on Nostr relays!')),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save profile: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }
}
