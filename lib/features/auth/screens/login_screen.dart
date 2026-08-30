import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/app_providers.dart';

/// Screen for Nostr authentication, importing nsec, or generating a fresh keypair.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _keyController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _keyController.dispose();
    super.dispose();
  }

  void _loginWithKey() async {
    final rawKey = _keyController.text.trim();
    if (rawKey.isEmpty) {
      setState(() => _errorMessage = 'Please enter your nsec or hex private key');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await ref.read(authStateProvider.notifier).loginWithPrivateKey(rawKey);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Authenticated with Nostr keypair!')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Invalid key. Please check your nsec or hex private key.';
          _isLoading = false;
        });
      }
    }
  }

  void _generateNewAccount() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await ref.read(authStateProvider.notifier).generateNewAccount();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('New Nostr keypair generated!')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to generate keypair: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nostr Identity'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.vpn_key_outlined,
                    size: 48,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              Center(
                child: Text(
                  'Sign In with Nostr',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'No passwords or centralized accounts. Your cryptographic keypair is your sovereign travel passport.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(height: 32),

              Text(
                'Enter Private Key (nsec / hex)',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _keyController,
                obscureText: true,
                decoration: InputDecoration(
                  hintText: 'nsec1... or 64-char hex key',
                  prefixIcon: const Icon(Icons.key_rounded),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.content_paste_rounded, size: 20),
                    tooltip: 'Paste from clipboard',
                    onPressed: () async {
                      final data = await Clipboard.getData(Clipboard.kTextPlain);
                      if (data?.text != null) {
                        _keyController.text = data!.text!.trim();
                      }
                    },
                  ),
                ),
              ),

              if (_errorMessage != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.errorContainer.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline_rounded, size: 18, color: theme.colorScheme.error),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(color: theme.colorScheme.error, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton(
                  onPressed: _isLoading ? null : _loginWithKey,
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Sign In with Key',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ),

              const SizedBox(height: 24),
              Row(
                children: [
                  const Expanded(child: Divider()),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'OR',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                    ),
                  ),
                  const Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: _isLoading ? null : _generateNewAccount,
                  icon: const Icon(Icons.add_circle_outline_rounded),
                  label: const Text(
                    'Generate New Nostr Identity',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                ),
              ),

              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.shield_outlined,
                      size: 20,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Your private key never leaves this device and is stored encrypted in platform secure hardware storage.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
