import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/app_providers.dart';
import '../../../models/user_profile.dart';

/// Screen to edit standard Nostr Kind 0 user metadata.
class EditProfileScreen extends ConsumerStatefulWidget {
  final UserProfile currentProfile;

  const EditProfileScreen({
    super.key,
    required this.currentProfile,
  });

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _displayNameController;
  late TextEditingController _aboutController;
  late TextEditingController _pictureController;
  late TextEditingController _bannerController;
  late TextEditingController _nip05Controller;
  late TextEditingController _websiteController;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final p = widget.currentProfile;
    _nameController = TextEditingController(text: p.name ?? '');
    _displayNameController = TextEditingController(text: p.displayName ?? '');
    _aboutController = TextEditingController(text: p.about ?? '');
    _pictureController = TextEditingController(text: p.picture ?? '');
    _bannerController = TextEditingController(text: p.banner ?? '');
    _nip05Controller = TextEditingController(text: p.nip05 ?? '');
    _websiteController = TextEditingController(text: p.website ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _displayNameController.dispose();
    _aboutController.dispose();
    _pictureController.dispose();
    _bannerController.dispose();
    _nip05Controller.dispose();
    _websiteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Nostr Profile'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Kind 0 Metadata',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Your profile is standard Nostr metadata. Edits are published across open relays and preserve existing custom fields.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),

              Text(
                'Display Name',
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _displayNameController,
                decoration: const InputDecoration(
                  hintText: 'e.g. Alice Traveler',
                  prefixIcon: Icon(Icons.badge_outlined),
                ),
              ),
              const SizedBox(height: 20),

              Text(
                'Username (name)',
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  hintText: 'e.g. alice',
                  prefixIcon: Icon(Icons.alternate_email_rounded),
                ),
              ),
              const SizedBox(height: 20),

              Text(
                'About (Bio)',
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _aboutController,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: 'Tell other hosts and travelers about yourself...',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 20),

              Text(
                'Profile Picture URL',
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _pictureController,
                decoration: const InputDecoration(
                  hintText: 'https://example.com/avatar.jpg',
                  prefixIcon: Icon(Icons.image_outlined),
                ),
              ),
              const SizedBox(height: 20),

              Text(
                'Banner Image URL',
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _bannerController,
                decoration: const InputDecoration(
                  hintText: 'https://example.com/banner.jpg',
                  prefixIcon: Icon(Icons.panorama_outlined),
                ),
              ),
              const SizedBox(height: 20),

              Text(
                'NIP-05 Identifier',
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nip05Controller,
                decoration: const InputDecoration(
                  hintText: 'alice@domain.com',
                  prefixIcon: Icon(Icons.verified_user_outlined),
                ),
              ),
              const SizedBox(height: 20),

              Text(
                'Website',
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _websiteController,
                decoration: const InputDecoration(
                  hintText: 'https://mywebsite.org',
                  prefixIcon: Icon(Icons.language_rounded),
                ),
              ),
              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton(
                  onPressed: _isSaving ? null : _saveProfile,
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Save Profile',
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

  void _saveProfile() async {
    setState(() => _isSaving = true);

    try {
      final updated = widget.currentProfile.copyWith(
        name: _nameController.text.trim(),
        displayName: _displayNameController.text.trim(),
        about: _aboutController.text.trim(),
        picture: _pictureController.text.trim(),
        banner: _bannerController.text.trim(),
        nip05: _nip05Controller.text.trim(),
        website: _websiteController.text.trim(),
      );

      final repo = ref.read(profileRepositoryProvider);
      await repo.saveProfile(updated);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated on Nostr relays!')),
        );
        ref.invalidate(currentUserProfileProvider);
        ref.invalidate(userProfileProvider(widget.currentProfile.pubkey));
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating profile: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }
}
