import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/country_constants.dart';
import '../../../core/providers/app_providers.dart';
import '../../../models/travel_profile.dart';
import '../../../models/user_profile.dart';

/// Unified screen to edit both Nostr Identity (Kind 0) and Travel Profile (Kind 30602).
class EditProfileScreen extends ConsumerStatefulWidget {
  final UserProfile? currentProfile;
  final TravelProfile? initialTravelProfile;

  const EditProfileScreen({
    super.key,
    this.currentProfile,
    this.initialTravelProfile,
  });

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  // Kind 0 controllers
  late TextEditingController _displayNameController;
  late TextEditingController _nameController;
  late TextEditingController _aboutController;
  late TextEditingController _pictureController;
  late TextEditingController _bannerController;
  late TextEditingController _nip05Controller;
  late TextEditingController _websiteController;

  // NIP-24 Birthday controllers (Kind 0)
  late TextEditingController _birthYearController;
  int? _birthMonth;
  int? _birthDay;

  // Kind 30602 controllers
  bool _useCustomTravelName = false;
  late TextEditingController _travelNameController;
  late TextEditingController _contentController;
  late TextEditingController _originCityController;
  String? _originCountry;
  late TextEditingController _homeCityController;
  String? _homeCountry;
  late TextEditingController _currentCityController;
  String? _currentCountry;
  late TextEditingController _occupationController;
  late TextEditingController _educationController;
  String? _gender;

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

    final myPubkey = ref.read(authStateProvider).valueOrNull?.pubkey;
    final k0 = widget.currentProfile ??
        (myPubkey != null ? ref.read(userProfileProvider(myPubkey)).valueOrNull : null);
    final k30602 = widget.initialTravelProfile ??
        (myPubkey != null ? ref.read(userTravelProfileProvider(myPubkey)).valueOrNull : null);

    // Kind 0 Identity
    _displayNameController = TextEditingController(text: k0?.displayName ?? '');
    _nameController = TextEditingController(text: k0?.name ?? '');
    _aboutController = TextEditingController(text: k0?.about ?? '');
    _pictureController = TextEditingController(text: k0?.picture ?? '');
    _bannerController = TextEditingController(text: k0?.banner ?? '');
    _nip05Controller = TextEditingController(text: k0?.nip05 ?? '');
    _websiteController = TextEditingController(text: k0?.website ?? '');

    // NIP-24 Birthday
    _birthYearController = TextEditingController(
      text: k0?.birthYear != null ? k0!.birthYear.toString() : '',
    );
    _birthMonth = k0?.birthMonth;
    _birthDay = k0?.birthDay;

    // Kind 30602 Travel Name
    final travelName = k30602?.name;
    final primaryK0Name = k0?.bestName;
    if (travelName != null &&
        travelName.trim().isNotEmpty &&
        travelName.trim().toLowerCase() != primaryK0Name?.trim().toLowerCase()) {
      _useCustomTravelName = true;
      _travelNameController = TextEditingController(text: travelName.trim());
    } else {
      _useCustomTravelName = false;
      _travelNameController = TextEditingController();
    }

    // Kind 30602 Travel Details
    _contentController = TextEditingController(text: k30602?.content ?? '');
    _originCityController = TextEditingController(text: k30602?.originCity ?? '');
    _originCountry = k30602?.originCountry;
    _homeCityController = TextEditingController(text: k30602?.homeCity ?? '');
    _homeCountry = k30602?.homeCountry;
    _currentCityController = TextEditingController(text: k30602?.currentCity ?? '');
    _currentCountry = k30602?.currentCountry;
    _occupationController = TextEditingController(text: k30602?.occupation ?? '');
    _educationController = TextEditingController(text: k30602?.education ?? '');
    _gender = k30602?.gender;

    if (k30602 != null) {
      _languages.addAll(k30602.languages);
      _interests.addAll(k30602.interests);
      _externalIdentities.addAll(k30602.externalIdentities);
      _images.addAll(k30602.images);
    }
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _nameController.dispose();
    _aboutController.dispose();
    _pictureController.dispose();
    _bannerController.dispose();
    _nip05Controller.dispose();
    _websiteController.dispose();
    _birthYearController.dispose();

    _travelNameController.dispose();
    _contentController.dispose();
    _originCityController.dispose();
    _homeCityController.dispose();
    _currentCityController.dispose();
    _occupationController.dispose();
    _educationController.dispose();
    _customInterestController.dispose();
    super.dispose();
  }

  int? get _previewAge {
    final year = int.tryParse(_birthYearController.text.trim());
    if (year == null || year < 1900 || year > DateTime.now().year) return null;
    final now = DateTime.now();
    int age = now.year - year;
    if (_birthMonth != null) {
      final day = _birthDay ?? 1;
      if (now.month < _birthMonth! || (now.month == _birthMonth! && now.day < day)) {
        age -= 1;
      }
    }
    return age >= 0 ? age : null;
  }

  Widget _buildProtocolBadge(String text) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
          width: 0.5,
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required String protocolBadge,
    required String subtitle,
    required List<Widget> children,
  }) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 24),
      elevation: 0,
      color: theme.colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.35),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
                _buildProtocolBadge(protocolBadge),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 18),
            ...children,
          ],
        ),
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

  Future<void> _pickAndUploadPhoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, maxWidth: 1600);
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
          const SnackBar(content: Text('Photo uploaded successfully!')),
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
            labelText: 'Photo URL',
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
              title: const Text('Link Travel Profile'),
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
                      hintText: 'e.g. your_handle',
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
                    final u = userCtrl.text.trim();
                    if (u.isNotEmpty) {
                      setState(() {
                        _externalIdentities.removeWhere((e) => e.platform == platform);
                        _externalIdentities.add(ExternalIdentity(platform: platform, username: u));
                      });
                      Navigator.of(ctx).pop();
                    }
                  },
                  child: const Text('Link'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _saveAll() async {
    if (!_formKey.currentState!.validate()) return;

    final authState = ref.read(authStateProvider).valueOrNull;
    if (authState?.pubkey == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be signed in to save your profile.')),
      );
      return;
    }

    final pubkey = authState!.pubkey!;
    setState(() => _isSaving = true);

    try {
      final repo = ref.read(profileRepositoryProvider);

      // --- 1. Kind 0 UserProfile ---
      final baseKind0 = widget.currentProfile ??
          ref.read(currentUserProfileProvider).valueOrNull ??
          ref.read(userProfileProvider(pubkey)).valueOrNull ??
          UserProfile(pubkey: pubkey);

      final birthYearInt = int.tryParse(_birthYearController.text.trim());

      final updatedKind0 = baseKind0.copyWith(
        displayName: _displayNameController.text.trim().isNotEmpty
            ? _displayNameController.text.trim()
            : null,
        name: _nameController.text.trim().isNotEmpty ? _nameController.text.trim() : null,
        about: _aboutController.text.trim().isNotEmpty ? _aboutController.text.trim() : null,
        picture: _pictureController.text.trim().isNotEmpty ? _pictureController.text.trim() : null,
        banner: _bannerController.text.trim().isNotEmpty ? _bannerController.text.trim() : null,
        nip05: _nip05Controller.text.trim().isNotEmpty ? _nip05Controller.text.trim() : null,
        website: _websiteController.text.trim().isNotEmpty ? _websiteController.text.trim() : null,
        birthYear: birthYearInt,
        birthMonth: _birthMonth,
        birthDay: _birthDay,
      );

      // --- 2. Kind 30602 TravelProfile ---
      final baseKind30602 = widget.initialTravelProfile ??
          ref.read(userTravelProfileProvider(pubkey)).valueOrNull;

      final resolvedTravelName = _useCustomTravelName &&
              _travelNameController.text.trim().isNotEmpty
          ? _travelNameController.text.trim()
          : (updatedKind0.displayName ?? updatedKind0.name);

      final updatedKind30602 = TravelProfile(
        eventId: baseKind30602?.eventId ?? '',
        authorPubkey: pubkey,
        name: resolvedTravelName,
        content: _contentController.text.trim(),
        createdAt: DateTime.now(),
        gender: _gender,
        originCountry: _originCountry,
        originCity: _originCityController.text.trim().isNotEmpty
            ? _originCityController.text.trim()
            : null,
        homeCountry: _homeCountry,
        homeCity: _homeCityController.text.trim().isNotEmpty
            ? _homeCityController.text.trim()
            : null,
        currentCountry: _currentCountry,
        currentCity: _currentCityController.text.trim().isNotEmpty
            ? _currentCityController.text.trim()
            : null,
        occupation: _occupationController.text.trim().isNotEmpty
            ? _occupationController.text.trim()
            : null,
        education: _educationController.text.trim().isNotEmpty
            ? _educationController.text.trim()
            : null,
        languages: _languages,
        interests: _interests,
        externalIdentities: _externalIdentities,
        images: _images,
        geohashes: baseKind30602?.geohashes ?? const [],
      );

      // Save both in background to relays
      await repo.saveProfile(updatedKind0);
      await repo.saveTravelProfile(updatedKind30602);

      ref.invalidate(currentUserProfileProvider);
      ref.invalidate(userProfileProvider(pubkey));
      ref.invalidate(userTravelProfileProvider(pubkey));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile and travel passport updated on Nostr relays!'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop(true);
        } else {
          context.go('/profile');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving profile: $e'),
            behavior: SnackBarBehavior.floating,
          ),
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        leading: BackButton(
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              context.go('/profile');
            }
          },
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: FilledButton(
              onPressed: _isSaving ? null : _saveAll,
              child: _isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Save'),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- 1. Nostr Identity Section (Kind 0) ---
              _buildSectionCard(
                title: 'Nostr Identity',
                protocolBadge: 'Kind 0',
                subtitle: 'Your universal Nostr metadata across all social & hospitality clients.',
                children: [
                  TextFormField(
                    controller: _displayNameController,
                    decoration: const InputDecoration(
                      labelText: 'Display Name',
                      hintText: 'e.g. Alice Traveler',
                      prefixIcon: Icon(Icons.badge_outlined),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 14),

                  // Collapsible travel / trail name option
                  if (!_useCustomTravelName) ...[
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: () => setState(() => _useCustomTravelName = true),
                        icon: const Icon(Icons.tune_rounded, size: 16),
                        label: const Text(
                          'Use a different travel nickname or trail name',
                          style: TextStyle(fontSize: 13),
                        ),
                      ),
                    ),
                  ] else ...[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _travelNameController,
                            decoration: InputDecoration(
                              labelText: 'Travel / Trail Name',
                              hintText: 'e.g. Alice on the Road',
                              prefixIcon: const Icon(Icons.explore_outlined),
                              helperText: 'Displayed on your hospitality passport (Kind 30602)',
                              suffix: _buildProtocolBadge('Kind 30602'),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, size: 20),
                          tooltip: 'Reset to match display name',
                          onPressed: () {
                            setState(() {
                              _useCustomTravelName = false;
                              _travelNameController.clear();
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                  ],

                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Username (handle)',
                      hintText: 'e.g. alice',
                      prefixIcon: Icon(Icons.alternate_email_rounded),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _aboutController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Social Bio (About)',
                      hintText: 'Short bio seen across Nostr clients...',
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _pictureController,
                    decoration: const InputDecoration(
                      labelText: 'Avatar Image URL',
                      hintText: 'https://...',
                      prefixIcon: Icon(Icons.account_circle_outlined),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _bannerController,
                    decoration: const InputDecoration(
                      labelText: 'Banner Image URL',
                      hintText: 'https://...',
                      prefixIcon: Icon(Icons.panorama_outlined),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _nip05Controller,
                    decoration: const InputDecoration(
                      labelText: 'NIP-05 Verification',
                      hintText: 'alice@domain.com',
                      prefixIcon: Icon(Icons.verified_user_outlined),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _websiteController,
                    decoration: const InputDecoration(
                      labelText: 'Website',
                      hintText: 'https://...',
                      prefixIcon: Icon(Icons.language_rounded),
                    ),
                  ),
                ],
              ),

              // --- 2. Demographics & Age (NIP-24 in Kind 0 & Kind 30602) ---
              _buildSectionCard(
                title: 'Demographics & Age',
                protocolBadge: 'NIP-24 (Kind 0) & Kind 30602',
                subtitle: 'Birthdate is stored in Kind 0 per NIP-24. Each field is optional.',
                children: [
                  Row(
                    children: [
                      // Birth Year
                      Expanded(
                        flex: 3,
                        child: TextFormField(
                          controller: _birthYearController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Birth Year',
                            hintText: 'YYYY',
                            prefixIcon: Icon(Icons.cake_outlined, size: 20),
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Birth Month
                      Expanded(
                        flex: 3,
                        child: DropdownButtonFormField<int?>(
                          initialValue: _birthMonth,
                          decoration: const InputDecoration(
                            labelText: 'Month',
                          ),
                          items: [
                            const DropdownMenuItem<int?>(value: null, child: Text('—')),
                            ...List.generate(12, (i) {
                              final m = i + 1;
                              const names = [
                                'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                                'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
                              ];
                              return DropdownMenuItem<int?>(
                                value: m,
                                child: Text(names[i]),
                              );
                            }),
                          ],
                          onChanged: (val) => setState(() => _birthMonth = val),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Birth Day
                      Expanded(
                        flex: 2,
                        child: DropdownButtonFormField<int?>(
                          initialValue: _birthDay,
                          decoration: const InputDecoration(
                            labelText: 'Day',
                          ),
                          items: [
                            const DropdownMenuItem<int?>(value: null, child: Text('—')),
                            ...List.generate(31, (i) {
                              final d = i + 1;
                              return DropdownMenuItem<int?>(
                                value: d,
                                child: Text('$d'),
                              );
                            }),
                          ],
                          onChanged: (val) => setState(() => _birthDay = val),
                        ),
                      ),
                    ],
                  ),

                  if (_previewAge != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline_rounded,
                              size: 16, color: theme.colorScheme.primary),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Calculated age: ~$_previewAge years old (dynamic NIP-24 privacy)',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),

                  // Gender dropdown (Kind 30602)
                  DropdownButtonFormField<String?>(
                    initialValue: _gender,
                    decoration: InputDecoration(
                      labelText: 'Gender',
                      prefixIcon: const Icon(Icons.person_outline_rounded),
                      suffix: _buildProtocolBadge('Kind 30602'),
                    ),
                    items: const [
                      DropdownMenuItem<String?>(value: null, child: Text('— Unspecified')),
                      DropdownMenuItem<String?>(value: 'female', child: Text('Female')),
                      DropdownMenuItem<String?>(value: 'male', child: Text('Male')),
                      DropdownMenuItem<String?>(value: 'non-binary', child: Text('Non-binary')),
                      DropdownMenuItem<String?>(value: 'other', child: Text('Other')),
                    ],
                    onChanged: (val) => setState(() => _gender = val),
                  ),
                ],
              ),

              // --- 3. Travel Story & Photos (Kind 30602) ---
              _buildSectionCard(
                title: 'Travel Story & Community Bio',
                protocolBadge: 'Kind 30602',
                subtitle: 'Share your lifestyle, travel philosophy, photos, and background.',
                children: [
                  TextFormField(
                    controller: _contentController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Travel Philosophy & Bio',
                      hintText: 'Tell hosts and fellow travelers about your adventures, values, and what you hope to experience...',
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Travel Photos
                  Row(
                    children: [
                      Text(
                        'Travel & Community Photos (${_images.length})',
                        style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: _showAddImageUrlDialog,
                        icon: const Icon(Icons.link, size: 16),
                        label: const Text('Add URL'),
                      ),
                      IconButton(
                        onPressed: _isUploadingImage ? null : _pickAndUploadPhoto,
                        icon: _isUploadingImage
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.add_photo_alternate_outlined),
                        tooltip: 'Upload photo',
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  if (_images.isNotEmpty)
                    SizedBox(
                      height: 90,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _images.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (ctx, i) {
                          return Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  _images[i],
                                  width: 90,
                                  height: 90,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    width: 90,
                                    height: 90,
                                    color: theme.colorScheme.surfaceContainerHighest,
                                    child: const Icon(Icons.broken_image),
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 2,
                                right: 2,
                                child: GestureDetector(
                                  onTap: () => setState(() => _images.removeAt(i)),
                                  child: Container(
                                    decoration: const BoxDecoration(
                                      color: Colors.black54,
                                      shape: BoxShape.circle,
                                    ),
                                    padding: const EdgeInsets.all(3),
                                    child: const Icon(Icons.close, size: 14, color: Colors.white),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6.0),
                      child: Text(
                        'No travel photos added yet.',
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
                      ),
                    ),

                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _occupationController,
                    decoration: const InputDecoration(
                      labelText: 'Occupation / Work',
                      hintText: 'e.g. Digital Nomad / Software / Carpenter',
                      prefixIcon: Icon(Icons.work_outline_rounded),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _educationController,
                    decoration: const InputDecoration(
                      labelText: 'Education',
                      hintText: 'e.g. Self-taught, University of Arts...',
                      prefixIcon: Icon(Icons.school_outlined),
                    ),
                  ),
                ],
              ),

              // --- 4. Locations & Mobility (Kind 30602) ---
              _buildSectionCard(
                title: 'Locations & Mobility',
                protocolBadge: 'Kind 30602',
                subtitle: 'Country and city areas. Exact coordinates are never published.',
                children: [
                  Text(
                    'Current Active Location',
                    style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  _buildCountryDropdown(
                    label: 'Current Country',
                    value: _currentCountry,
                    onChanged: (val) => setState(() => _currentCountry = val),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _currentCityController,
                    decoration: const InputDecoration(
                      labelText: 'Current City',
                      hintText: 'e.g. Oaxaca',
                      prefixIcon: Icon(Icons.explore_outlined),
                    ),
                  ),

                  const SizedBox(height: 16),
                  Text(
                    'Home Base',
                    style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  _buildCountryDropdown(
                    label: 'Home Country',
                    value: _homeCountry,
                    onChanged: (val) => setState(() => _homeCountry = val),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _homeCityController,
                    decoration: const InputDecoration(
                      labelText: 'Home City',
                      hintText: 'e.g. Lyon',
                      prefixIcon: Icon(Icons.place_outlined),
                    ),
                  ),

                  const SizedBox(height: 16),
                  Text(
                    'Origin / Hometown',
                    style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  _buildCountryDropdown(
                    label: 'Origin Country',
                    value: _originCountry,
                    onChanged: (val) => setState(() => _originCountry = val),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _originCityController,
                    decoration: const InputDecoration(
                      labelText: 'Origin City',
                      hintText: 'e.g. Munich',
                      prefixIcon: Icon(Icons.flight_takeoff_rounded),
                    ),
                  ),
                ],
              ),

              // --- 5. Languages Spoken (Kind 30602) ---
              _buildSectionCard(
                title: 'Languages Spoken',
                protocolBadge: 'Kind 30602',
                subtitle: 'Indicate languages you speak and your proficiency.',
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ..._languages.map((l) {
                        return Chip(
                          label: Text(l.displayName),
                          onDeleted: () => setState(() => _languages.remove(l)),
                        );
                      }),
                      ActionChip(
                        avatar: const Icon(Icons.add, size: 16),
                        label: const Text('Add Language'),
                        onPressed: _addLanguageDialog,
                      ),
                    ],
                  ),
                ],
              ),

              // --- 6. Interests & Topics (Kind 30602) ---
              _buildSectionCard(
                title: 'Interests & Activities',
                protocolBadge: 'Kind 30602',
                subtitle: 'Helps matching with hosts and travelers with shared passions.',
                children: [
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: _availableInterests.map((interest) {
                      final selected = _interests.contains(interest);
                      return FilterChip(
                        label: Text('#$interest'),
                        selected: selected,
                        onSelected: (val) {
                          setState(() {
                            if (val) {
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
                            labelText: 'Add custom interest / hashtag',
                            hintText: 'e.g. permaculture',
                            isDense: true,
                          ),
                          onSubmitted: (_) {
                            final text = _customInterestController.text
                                .trim()
                                .toLowerCase()
                                .replaceAll('#', '')
                                .replaceAll(' ', '_');
                            if (text.isNotEmpty && !_interests.contains(text)) {
                              setState(() {
                                _interests.add(text);
                                _customInterestController.clear();
                              });
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filledTonal(
                        icon: const Icon(Icons.add_rounded),
                        onPressed: () {
                          final text = _customInterestController.text
                              .trim()
                              .toLowerCase()
                              .replaceAll('#', '')
                              .replaceAll(' ', '_');
                          if (text.isNotEmpty && !_interests.contains(text)) {
                            setState(() {
                              _interests.add(text);
                              _customInterestController.clear();
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),

              // --- 7. Linked Hospitality Networks (NIP-39 & Kind 30602) ---
              _buildSectionCard(
                title: 'Linked Travel Networks',
                protocolBadge: 'NIP-39 & Kind 30602',
                subtitle: 'Show established trust by linking your existing hospitality profiles.',
                children: [
                  if (_externalIdentities.isNotEmpty)
                    Column(
                      children: _externalIdentities.map((id) {
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.verified_outlined),
                          title: Text(id.platformName),
                          subtitle: Text(id.username),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, size: 20),
                            onPressed: () => setState(() => _externalIdentities.remove(id)),
                          ),
                        );
                      }).toList(),
                    ),
                  OutlinedButton.icon(
                    onPressed: _addExternalIdentityDialog,
                    icon: const Icon(Icons.add_link_rounded, size: 18),
                    label: const Text('Link Network Profile'),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton.icon(
                  onPressed: _isSaving ? null : _saveAll,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.check_circle_outline_rounded),
                  label: Text(
                    _isSaving ? 'Publishing to Relays...' : 'Save Profile & Travel Passport',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
