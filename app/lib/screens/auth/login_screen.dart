import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/constants.dart';
import '../../app/theme.dart';
import '../../providers/auth_provider.dart';
import '../../services/github_oauth.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tokenController = TextEditingController();
  bool _loading = false;
  bool _obscureToken = true;
  bool _showManualToken = false;

  // Device Flow state (mobile only)
  String? _userCode;

  Future<void> _loginWithOAuth() async {
    if (AppConstants.githubClientId.isEmpty) {
      setState(() => _showManualToken = true);
      return;
    }

    if (kIsWeb) {
      // Web: redirect-based OAuth — open GitHub authorize page
      // User will be redirected back with ?code=xxx
      final uri = Uri.parse(
        'https://github.com/login/oauth/authorize'
        '?client_id=${AppConstants.githubClientId}'
        '&scope=repo',
      );
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      // After authorizing, user needs to paste the token manually
      // (since we don't have a backend to exchange the code)
      if (mounted) {
        setState(() => _showManualToken = true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'After authorizing on GitHub, create a token at github.com/settings/tokens and paste it below.',
            ),
            duration: Duration(seconds: 8),
          ),
        );
      }
      return;
    }

    // Mobile: Device Flow (no CORS issue)
    setState(() => _loading = true);
    try {
      final oauth = GitHubOAuth();
      final deviceData = await oauth.requestDeviceCode();

      setState(() {
        _userCode = deviceData['user_code'] as String;
      });

      final verificationUri =
          deviceData['verification_uri'] as String;
      final uri = Uri.parse(verificationUri);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }

      final token = await oauth.pollForToken(
        deviceCode: deviceData['device_code'] as String,
        interval: deviceData['interval'] as int,
        expiresIn: deviceData['expires_in'] as int,
      );

      await ref.read(authStateProvider.notifier).loginWithToken(token);
      if (mounted) context.go('/home/browse');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: AppColors.brownDark,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
          _userCode = null;
        });
      }
    }
  }

  Future<void> _loginWithToken() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await ref
          .read(authStateProvider.notifier)
          .loginWithToken(_tokenController.text.trim());
      if (mounted) context.go('/home/browse');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Invalid GitHub token'),
            backgroundColor: AppColors.brownDark,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _tokenController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned(
            top: -60,
            right: -40,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.coral.withOpacity(0.12),
              ),
            ),
          ),
          Positioned(
            bottom: 80,
            left: -60,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.brown.withOpacity(0.08),
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(28),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: AppColors.coral,
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.coral.withOpacity(0.35),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.smart_toy_outlined,
                          color: Colors.white,
                          size: 34,
                        ),
                      ),
                      const SizedBox(height: 28),
                      Text('Welcome to Gofer.ai',
                          style: Theme.of(context).textTheme.displayLarge),
                      const SizedBox(height: 6),
                      Text(
                        'Connect with GitHub to hire AI workers and post tasks',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 40),

                      // Device Flow code display (mobile only)
                      if (_userCode != null) ...[
                        Card(
                          color: AppColors.coral.withOpacity(0.05),
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              children: [
                                const Text('Enter this code on GitHub:',
                                    style: TextStyle(fontSize: 14)),
                                const SizedBox(height: 12),
                                GestureDetector(
                                  onTap: () {
                                    Clipboard.setData(
                                        ClipboardData(text: _userCode!));
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text('Code copied!')),
                                    );
                                  },
                                  child: Text(
                                    _userCode!,
                                    style: const TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 4,
                                      color: AppColors.coral,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text('Tap to copy',
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: AppColors.brownLight)),
                                const SizedBox(height: 16),
                                const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2),
                                ),
                                const SizedBox(height: 8),
                                const Text('Waiting for authorization...',
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: AppColors.brownLight)),
                              ],
                            ),
                          ),
                        ),
                      ] else if (!_showManualToken) ...[
                        // Primary button
                        SizedBox(
                          height: 52,
                          child: FilledButton.icon(
                            onPressed: _loading ? null : _loginWithOAuth,
                            icon: _loading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: Colors.white),
                                  )
                                : const Icon(Icons.login),
                            label: const Text('Connect with GitHub'),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Center(
                          child: TextButton(
                            onPressed: () =>
                                setState(() => _showManualToken = true),
                            child: const Text(
                              'Use personal access token instead',
                              style: TextStyle(
                                  fontSize: 13, color: AppColors.brownLight),
                            ),
                          ),
                        ),
                      ],

                      // Manual token input
                      if (_showManualToken && _userCode == null) ...[
                        Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              TextFormField(
                                controller: _tokenController,
                                decoration: InputDecoration(
                                  labelText: 'GitHub Personal Access Token',
                                  prefixIcon: const Icon(Icons.key_outlined,
                                      color: AppColors.brownLight),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscureToken
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                      color: AppColors.brownLight,
                                    ),
                                    onPressed: () => setState(
                                        () => _obscureToken = !_obscureToken),
                                  ),
                                  helperText:
                                      'Create at github.com/settings/tokens\nRequired scope: repo',
                                  helperMaxLines: 2,
                                ),
                                obscureText: _obscureToken,
                                validator: (v) => v == null || v.isEmpty
                                    ? 'Enter your GitHub token'
                                    : null,
                              ),
                              const SizedBox(height: 20),
                              SizedBox(
                                height: 52,
                                child: FilledButton.icon(
                                  onPressed: _loading ? null : _loginWithToken,
                                  icon: _loading
                                      ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white),
                                        )
                                      : const Icon(Icons.login),
                                  label: const Text('Connect'),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Center(
                                child: TextButton(
                                  onPressed: () =>
                                      setState(() => _showManualToken = false),
                                  child: const Text(
                                    'Back to GitHub login',
                                    style: TextStyle(
                                        fontSize: 13,
                                        color: AppColors.brownLight),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 20),
                      Text(
                        'Your credentials are stored locally and never sent to our servers.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: AppColors.brownLight),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
