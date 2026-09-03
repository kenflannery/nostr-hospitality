import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/country_constants.dart';
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

  late TextEditingController _nameController;
  late TextEditingController _contentController;
  late TextEditingController _originCityController;
  String? _originCountry;
  late TextEditingController _homeCityController;
  String? _homeCountry;
  late TextEditingController _currentCityController;
  String? _currentCountry;
  late TextEditingController _occupationController;
  late TextEditingController _educationController;
  late TextEditingController _birthYearController;

  String? _gender;
  int? _birthMonth;
  int? _birthDay;

  final List<LanguageProficiency> _languages = [];
  final List<String> _interests = [];
  final List<ExternalIdentity> _externalIdentities = [];
  final List<String> _images = [];

  final TextEditingController _customInterestController = TextEditingController();

  bool _isSaving = false;
  bool _isUploadingImage = false;

  final List<String> _availableInterests = const [
    'meetup', 'hiking', 'cycling', 'cooking', 'music', 'art', 'reading',
    'photography', 'nostr', 'open_source', 'van_life', 'camping',
    'surfing', 'yoga', 'coffee', 'philosophy', 'board_games', 'rideshare',
  ];

  @override
  void initState() {
    super.initState();
    final init = widget.initialProfile;

    String initialName = init?.name ?? '';
    if (initialName.isEmpty) {
      final authState = ref.read(authStateProvider).valueOrNull;
      if (authState?.pubkey != null) {
        final kind0Profile = ref.read(userProfileProvider(authState!.pubkey!)).valueOrNull;
        if (kind0Profile != null) {
          if (kind0Profile.displayName != null && kind0Profile.displayName!.trim().isNotEmpty) {
            initialName = kind0Profile.displayName!.trim();
          } else if (kind0Profile.name != null && kind0Profile.name!.trim().isNotEmpty) {
            initialName = kind0Profile.name!.trim();
          }
        }
      }
    }

    _nameController = TextEditingController(text: initialName);
    _contentController = TextEditingController(text: init?.content ?? '');
    _originCityController = TextEditingController(text: init?.originCity ?? '');
    _originCountry = init?.originCountry;
    _homeCityController = TextEditingController(text: init?.homeCity ?? '');
    _homeCountry = init?.homeCountry;
    _currentCityController = TextEditingController(text: init?.currentCity ?? '');
    _currentCountry = init?.currentCountry;
    _occupationController = TextEditingController(text: init?.occupation ?? '');
    _educationController = TextEditingController(text: init?.education ?? '');
    _birthYearController = TextEditingController(
      text: init?.birthYear != null ? init!.birthYear.toString() : '',
    );
    _birthMonth = init?.birthMonth;
    _birthDay = init?.birthDay;
    _gender = init?.gender;

    if (init != null) {
      _languages.addAll(init.languages);
      _interests.addAll(init.interests);
      _externalIdentities.addAll(init.externalIdentities);
      _images.addAll(init.images);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _contentController.dispose();
    _originCityController.dispose();
    _homeCityController.dispose();
    _currentCityController.dispose();
    _occupationController.dispose();
    _educationController.dispose();
    _birthYearController.dispose();
    _customInterestController.dispose();
    super.dispose();
  }

  void _addCustomInterest() {
    final text = _customInterestController.text.trim().toLowerCase().replaceAll('#', '').replaceAll(' ', '_');
    if (text.isNotEmpty && !_interests.contains(text)) {
      setState(() {
        _interests.add(text);
        _customInterestController.clear();
      });
    }
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
    String platform = 'triphopping';
    final userCtrl = TextEditingController();

    const platforms = [
      'triphopping',
      'couchers',
      'trustroots',
      'couchsurfing',
      'warmshowers',
      'bewelcome',
      'github',
    ];

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Link Hospitality & Social Profile'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: platform,
                    decoration: const InputDecoration(labelText: 'Network / Platform'),
                    items: platforms
                        .map((p) => DropdownMenuItem(
                              value: p,
                              child: Text(ExternalIdentity(platform: p, username: '').platformName),
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

  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920,
      maxHeight: 1080,
      imageQuality: 85,
    );
    if (picked == null) return;

    setState(() => _isUploadingImage = true);
    try {
      final bytes = await picked.readAsBytes();
      final uploadService = ref.read(mediaUploadServiceProvider);
      final url = await uploadService.uploadImage(
        bytes: bytes,
        filename: picked.name,
      );
      setState(() {
        _images.add(url);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Photo uploaded to nostr.build successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Photo upload failed: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploadingImage = false);
      }
    }
  }

  void _showAddImageUrlDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Photo by URL'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Photo HTTPS URL',
            hintText: 'https://example.com/travel_photo.jpg',
            prefixIcon: Icon(Icons.link_rounded),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final url = controller.text.trim();
              if (url.isNotEmpty && url.startsWith('http')) {
                setState(() => _images.add(url));
                Navigator.of(ctx).pop();
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Widget _buildCountryDropdown({
    required String label,
    required String? value,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String?>(
      initialValue: value != null && CountryConstants.countryMap.containsKey(value.toUpperCase())
          ? value.toUpperCase()
          : null,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        hintText: 'Select country',
        prefixIcon: const Icon(Icons.public_rounded, size: 20),
      ),
      items: [
        const DropdownMenuItem<String?>(
          value: null,
          child: Text('— None / Unspecified'),
        ),
        ...CountryConstants.sortedCountryEntries.map(
          (e) => DropdownMenuItem<String?>(
            value: e.key,
            child: Text(
              '${e.value} (${e.key})',
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ],
      onChanged: onChanged,
    );
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final authState = ref.read(authStateProvider).valueOrNull;
    if (authState?.pubkey == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be signed in to publish a profile.')),
      );
      return;
    }

    final pubkey = authState!.pubkey!;
    setState(() => _isSaving = true);

    final birthYearInt = int.tryParse(_birthYearController.text.trim());

    final profile = TravelProfile(
      eventId: widget.initialProfile?.eventId ?? '',
      authorPubkey: pubkey,
      name: _nameController.text.trim().isNotEmpty ? _nameController.text.trim() : null,
      content: _contentController.text.trim(),
      createdAt: DateTime.now(),
      gender: _gender,
      birthYear: birthYearInt,
      birthMonth: _birthMonth,
      birthDay: _birthDay,
      originCountry: _originCountry,
      originCity: _originCityController.text.trim().isNotEmpty ? _originCityController.text.trim() : null,
      homeCountry: _homeCountry,
      homeCity: _homeCityController.text.trim().isNotEmpty ? _homeCityController.text.trim() : null,
      currentCountry: _currentCountry,
      currentCity: _currentCityController.text.trim().isNotEmpty ? _currentCityController.text.trim() : null,
      occupation: _occupationController.text.trim().isNotEmpty ? _occupationController.text.trim() : null,
      education: _educationController.text.trim().isNotEmpty ? _educationController.text.trim() : null,
      languages: _languages,
      interests: _interests,
      externalIdentities: _externalIdentities,
      images: _images,
      geohashes: widget.initialProfile?.geohashes ?? const [],
    );

    try {
      final repository = ref.read(profileRepositoryProvider);
      await repository.saveTravelProfile(profile);
      ref.invalidate(userTravelProfileProvider(pubkey));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Travel profile published to Nostr relays successfully!')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving travel profile: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
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
            // --- SECTION 1: Travel Profile Name ---
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
                          'Travel Profile Name',
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Your preferred display name across nostr travel apps.',
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 14),

                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Display Name / Nickname',
                        hintText: 'e.g. Alex Nomad or Maya',
                        prefixIcon: Icon(Icons.person_outline_rounded),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // --- SECTION 2: Travel & Lifestyle Photos (nostr.build) ---
            Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.photo_library_outlined, color: theme.colorScheme.primary),
                        const SizedBox(width: 8),
                        Text(
                          'Travel & Lifestyle Photos',
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Upload photos from your adventures, travels, or hometown. Hosted on nostr.build and published with your Kind 30602 profile.',
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 16),

                    if (_isUploadingImage)
                      Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.4)),
                        ),
                        child: const Row(
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2.5),
                            ),
                            SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                'Uploading photo to nostr.build via NIP-96...',
                                style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),

                    if (_images.isNotEmpty)
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          for (int i = 0; i < _images.length; i++)
                            Stack(
                              children: [
                                Container(
                                  width: 100,
                                  height: 100,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: theme.colorScheme.outlineVariant),
                                    image: DecorationImage(
                                      image: NetworkImage(_images[i]),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: 4,
                                  right: 4,
                                  child: GestureDetector(
                                    onTap: () => setState(() => _images.removeAt(i)),
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withValues(alpha: 0.7),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.close_rounded, color: Colors.white, size: 14),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),

                    if (_images.isNotEmpty) const SizedBox(height: 16),

                    Row(
                      children: [
                        FilledButton.tonalIcon(
                          onPressed: _isUploadingImage ? null : _pickAndUploadImage,
                          icon: const Icon(Icons.add_photo_alternate_rounded, size: 18),
                          label: const Text('Upload Photo'),
                        ),
                        const SizedBox(width: 10),
                        OutlinedButton.icon(
                          onPressed: _isUploadingImage ? null : _showAddImageUrlDialog,
                          icon: const Icon(Icons.link_rounded, size: 18),
                          label: const Text('Add by URL'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // --- SECTION 3: Languages Spoken ---
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

            // --- SECTION 4: Traveler Story & Philosophy ---
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

            // --- SECTION 5: Geography & Locations (Origin, Home, Current) ---
            Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.location_city_rounded, color: theme.colorScheme.primary),
                        const SizedBox(width: 8),
                        Text(
                          'Locations & Roots (Optional)',
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Distinguish where you grew up, where you currently live, and where you are traveling right now.',
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 16),

                    // Origin Hometown
                    Text('1. Hometown / Origin Roots', style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _originCityController,
                            decoration: const InputDecoration(
                              labelText: 'Origin City',
                              hintText: 'e.g. Munich',
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildCountryDropdown(
                            label: 'Origin Country',
                            value: _originCountry,
                            onChanged: (val) => setState(() => _originCountry = val),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Home Base
                    Text('2. Current Home Base (Residence)', style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _homeCityController,
                            decoration: const InputDecoration(
                              labelText: 'Home City',
                              hintText: 'e.g. Lyon',
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildCountryDropdown(
                            label: 'Home Country',
                            value: _homeCountry,
                            onChanged: (val) => setState(() => _homeCountry = val),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Active Travel Location (Nomad)
                    Text('3. Currently Traveling In (On the Road)', style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _currentCityController,
                            decoration: const InputDecoration(
                              labelText: 'Current City',
                              hintText: 'e.g. Oaxaca',
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildCountryDropdown(
                            label: 'Current Country',
                            value: _currentCountry,
                            onChanged: (val) => setState(() => _currentCountry = val),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // --- SECTION 6: Demographics & Birthday ---
            Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.cake_outlined, color: theme.colorScheme.primary),
                        const SizedBox(width: 8),
                        Text(
                          'Demographics & Birthday (Optional)',
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
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
                    const SizedBox(height: 14),

                    // Birth Month & Day
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<int?>(
                            initialValue: _birthMonth,
                            decoration: const InputDecoration(
                              labelText: 'Birth Month',
                              hintText: 'Month',
                            ),
                            items: [
                              const DropdownMenuItem<int?>(value: null, child: Text('— Unspecified')),
                              for (int m = 1; m <= 12; m++)
                                DropdownMenuItem<int?>(
                                  value: m,
                                  child: Text(_monthName(m)),
                                ),
                            ],
                            onChanged: (val) => setState(() => _birthMonth = val),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<int?>(
                            initialValue: _birthDay,
                            decoration: const InputDecoration(
                              labelText: 'Birth Day',
                              hintText: 'Day',
                            ),
                            items: [
                              const DropdownMenuItem<int?>(value: null, child: Text('— Unspecified')),
                              for (int d = 1; d <= 31; d++)
                                DropdownMenuItem<int?>(
                                  value: d,
                                  child: Text(d.toString()),
                                ),
                            ],
                            onChanged: (val) => setState(() => _birthDay = val),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    TextFormField(
                      controller: _occupationController,
                      decoration: const InputDecoration(
                        labelText: 'Occupation / Field',
                        hintText: 'e.g. Software Engineer / Photographer',
                      ),
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _educationController,
                      decoration: const InputDecoration(
                        labelText: 'Education',
                        hintText: 'e.g. B.Sc. Computer Science',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // --- SECTION 7: Interests & Topics ---
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
                    const SizedBox(height: 4),
                    Text(
                      'Select from popular topics or add your own custom passions (e.g. #meetup, #hiking, #nostr).',
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 12),

                    if (_interests.any((i) => !_availableInterests.contains(i))) ...[
                      Text(
                        'Custom Interests',
                        style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _interests
                            .where((i) => !_availableInterests.contains(i))
                            .map((interest) {
                          return Chip(
                            label: Text('#$interest'),
                            deleteIcon: const Icon(Icons.close_rounded, size: 16),
                            onDeleted: () {
                              setState(() => _interests.remove(interest));
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 12),
                    ],

                    Text(
                      'Suggested Topics',
                      style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
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
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _customInterestController,
                            decoration: const InputDecoration(
                              hintText: 'Add custom interest (e.g. salsa_dancing)',
                              isDense: true,
                            ),
                            onSubmitted: (_) => _addCustomInterest(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton.filledTonal(
                          onPressed: _addCustomInterest,
                          icon: const Icon(Icons.add_rounded),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // --- SECTION 8: Linked Hospitality Networks ---
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
                          'Linked Hospitality & Social Profiles',
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const Spacer(),
                        TextButton.icon(
                          onPressed: _addExternalIdentityDialog,
                          icon: const Icon(Icons.add_rounded, size: 18),
                          label: const Text('Link'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Connect your Trustroots, Couchers, Couchsurfing, WarmShowers, or GitHub handles to bring your external reputation to Nostr.',
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 12),

                    if (_externalIdentities.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Text(
                          'No external accounts linked yet.',
                          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
                        ),
                      )
                    else
                      Column(
                        children: _externalIdentities.map((id) {
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: CircleAvatar(
                              backgroundColor: theme.colorScheme.primaryContainer,
                              child: Text(
                                id.platform[0].toUpperCase(),
                                style: TextStyle(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(id.platformName, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('@${id.username}'),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline_rounded),
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
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  String _monthName(int month) {
    const months = [
      'January (01)', 'February (02)', 'March (03)', 'April (04)',
      'May (05)', 'June (06)', 'July (07)', 'August (08)',
      'September (09)', 'October (10)', 'November (11)', 'December (12)',
    ];
    return months[month - 1];
  }
}
