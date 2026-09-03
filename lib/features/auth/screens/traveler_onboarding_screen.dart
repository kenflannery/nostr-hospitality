import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/user_profile.dart';
import '../../profile/screens/travel_profile_editor_screen.dart';

/// Friendly, educational onboarding flow for travelers new to Nostr and decentralized hospitality.
class TravelerOnboardingScreen extends ConsumerStatefulWidget {
  const TravelerOnboardingScreen({super.key});

  @override
  ConsumerState<TravelerOnboardingScreen> createState() => _TravelerOnboardingScreenState();
}

class _TravelerOnboardingScreenState extends ConsumerState<TravelerOnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _aboutController = TextEditingController();

  int _currentStep = 0;
  bool _isGenerating = false;
  bool _hasSavedNsec = false;
  bool _obscureNsec = true;
  String? _npub;
  String? _nsec;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _aboutController.dispose();
    super.dispose();
  }

  void _generateKeys() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isGenerating = true;
      _errorMessage = null;
    });

    try {
      await ref.read(authStateProvider.notifier).generateNewAccount();
      final auth = ref.read(authRepositoryProvider);
      final pubkey = auth.currentState.pubkey;

      if (pubkey != null) {
        // Publish initial Kind 0 metadata event with user's entered name & about
        final enteredName = _nameController.text.trim();
        final enteredAbout = _aboutController.text.trim();

        final initialProfile = UserProfile(
          pubkey: pubkey,
          name: enteredName,
          displayName: enteredName,
          about: enteredAbout.isNotEmpty ? enteredAbout : null,
        );

        try {
          await ref.read(profileRepositoryProvider).saveProfile(initialProfile);
          ref.invalidate(userProfileProvider(pubkey));
        } catch (_) {
          // Local state already updated; network publish may retry
        }
      }

      setState(() {
        _npub = auth.currentState.npub;
        _nsec = auth.activeNsec;
        _currentStep = 1;
        _isGenerating = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to generate sovereign passport: $e';
        _isGenerating = false;
      });
    }
  }

  void _proceedToProfile() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => const TravelProfileEditorScreen(),
      ),
      (route) => route.isFirst,
    );
  }

  void _finishAndExplore() {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Nostr Passport'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: _currentStep == 0
              ? _buildWelcomeStep(context, theme)
              : _buildKeyBackupStep(context, theme),
        ),
      ),
    );
  }

  Widget _buildWelcomeStep(BuildContext context, ThemeData theme) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withValues(alpha: 0.35),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.luggage_rounded,
                size: 56,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(height: 24),

          Text(
            'Welcome to Hospitality Libre',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'A global, community-driven hospitality network built on open protocols. You own your identity, reputation, and connections.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),

          // User Name Input Card
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: theme.colorScheme.outlineVariant),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.badge_outlined, size: 20, color: theme.colorScheme.primary),
                      const SizedBox(width: 8),
                      Text(
                        'Your Passport Identity',
                        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Display Name *',
                      hintText: 'e.g. Alex, Maya',
                      prefixIcon: Icon(Icons.person_outline_rounded, size: 20),
                    ),
                    textCapitalization: TextCapitalization.words,
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Please enter your display name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _aboutController,
                    decoration: const InputDecoration(
                      labelText: 'Universal Nostr Bio (optional)',
                      hintText: 'A short sentence or two introducing yourself across Nostr apps...',
                      prefixIcon: Icon(Icons.info_outline_rounded, size: 20),
                      helperText: 'Visible across all Nostr clients. Feel free to keep it a sentence or two!',
                    ),
                    maxLines: 2,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          _buildFeatureRow(
            theme,
            icon: Icons.vpn_key_rounded,
            title: 'Your Keys = Your Passport',
            description:
                'No email, password, or corporate servers required. You are identified by a cryptographic keypair.',
          ),
          const SizedBox(height: 14),
          _buildFeatureRow(
            theme,
            icon: Icons.star_border_rounded,
            title: 'Portable Reputation',
            description:
                'References and reviews travel with you everywhere across any client in the Nostr universe.',
          ),
          const SizedBox(height: 14),
          _buildFeatureRow(
            theme,
            icon: Icons.shield_outlined,
            title: 'Censorship-Resistant',
            description:
                'No single company can ban your profile, delete your reviews, or sell your personal travel data.',
          ),
          const SizedBox(height: 28),

          if (_errorMessage != null)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppTheme.negativeRed.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _errorMessage!,
                style: const TextStyle(color: AppTheme.negativeRed),
              ),
            ),

          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton.icon(
              onPressed: _isGenerating ? null : _generateKeys,
              icon: _isGenerating
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.flight_takeoff_rounded),
              label: Text(
                _isGenerating ? 'Creating Passport...' : 'Generate My Digital Passport',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKeyBackupStep(BuildContext context, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.positiveGreen.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle_outline_rounded,
              size: 48,
              color: AppTheme.positiveGreen,
            ),
          ),
        ),
        const SizedBox(height: 20),

        Center(
          child: Text(
            'Passport Created Successfully!',
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Please take 30 seconds to save your secret key. You will need it to log back in or restore your account on another device.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            height: 1.4,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),

        // Public Key (npub) Card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.person_pin_rounded, size: 20, color: theme.colorScheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      'Public Passport ID (npub)',
                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Your public travel address. Share this freely with hosts, guests, and friends.',
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _npub ?? '',
                          style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy_rounded, size: 18),
                        tooltip: 'Copy npub',
                        onPressed: () {
                          if (_npub != null) {
                            Clipboard.setData(ClipboardData(text: _npub!));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Public ID (npub) copied!')),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Secret Key (nsec) Card
        Card(
          color: theme.colorScheme.errorContainer.withValues(alpha: 0.18),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.lock_rounded, size: 20, color: AppTheme.negativeRed),
                    const SizedBox(width: 8),
                    Text(
                      'Secret Recovery Key (nsec)',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.negativeRed,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Your master private key. NEVER share this with anyone! If lost, your account cannot be recovered.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: theme.colorScheme.outlineVariant),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _obscureNsec ? '•' * 32 : (_nsec ?? ''),
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                            color: _obscureNsec ? Colors.grey : null,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          _obscureNsec ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          size: 18,
                        ),
                        tooltip: _obscureNsec ? 'Show key' : 'Hide key',
                        onPressed: () => setState(() => _obscureNsec = !_obscureNsec),
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy_rounded, size: 18),
                        tooltip: 'Copy secret key',
                        onPressed: () {
                          if (_nsec != null) {
                            Clipboard.setData(ClipboardData(text: _nsec!));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Secret key (nsec) copied! Save it in a safe place.'),
                              ),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Confirmation Checkbox
        CheckboxListTile(
          value: _hasSavedNsec,
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          title: Text(
            'I have safely saved my secret recovery key (nsec)',
            style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          onChanged: (val) => setState(() => _hasSavedNsec = val ?? false),
        ),
        const SizedBox(height: 24),

        // Direct CTA to complete profile
        SizedBox(
          width: double.infinity,
          height: 52,
          child: FilledButton.icon(
            onPressed: _hasSavedNsec ? _proceedToProfile : null,
            icon: const Icon(Icons.person_add_alt_1_rounded),
            label: const Text(
              'Set Up Travel Profile (Kind 30602)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton(
            onPressed: _hasSavedNsec ? _finishAndExplore : null,
            child: const Text('Explore Hospitality Libre'),
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureRow(
    ThemeData theme, {
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 20, color: theme.colorScheme.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
