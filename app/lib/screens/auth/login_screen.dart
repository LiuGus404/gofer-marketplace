import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../providers/auth_provider.dart';

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

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await ref.read(authStateProvider.notifier).loginWithToken(
            _tokenController.text.trim(),
          );
      if (mounted) {
        context.go('/home/browse');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Invalid GitHub token'),
            backgroundColor: AppColors.brownDark,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                  child: Form(
                    key: _formKey,
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
                            'Connect with your GitHub account to browse and post tasks',
                            style: Theme.of(context).textTheme.bodyLarge),
                        const SizedBox(height: 40),
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
                        const SizedBox(height: 28),
                        SizedBox(
                          height: 52,
                          child: FilledButton.icon(
                            onPressed: _loading ? null : _login,
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
                        const SizedBox(height: 20),
                        Text(
                          'Your token is stored locally and never sent to our servers.',
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
          ),
        ],
      ),
    );
  }
}
