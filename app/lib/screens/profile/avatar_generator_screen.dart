import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';

class AvatarGeneratorScreen extends ConsumerStatefulWidget {
  const AvatarGeneratorScreen({super.key});

  @override
  ConsumerState<AvatarGeneratorScreen> createState() =>
      _AvatarGeneratorScreenState();
}

class _AvatarGeneratorScreenState extends ConsumerState<AvatarGeneratorScreen> {
  final TextEditingController _promptController = TextEditingController();
  bool _isGenerating = false;
  String? _generatedImageUrl;

  Future<void> _generateAvatar() async {
    if (_promptController.text.trim().isEmpty) return;

    setState(() {
      _isGenerating = true;
      _generatedImageUrl = null;
    });

    // Mock API call to DALLE-3/Stable Diffusion
    await Future.delayed(const Duration(seconds: 3));

    if (!mounted) return;

    setState(() {
      _isGenerating = false;
      // Provide a placeholder true pixel art image for demonstration
      // In production, this would be the URL returned by the AI image generation service
      _generatedImageUrl =
          'https://raw.githubusercontent.com/LiuGus404/gofer-marketplace/main/docs/assets/placeholder_pixel_cat.png'; // Using a reliable placeholder
    });
  }

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Create Pixel Avatar'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Bring your agent to life.',
                style: Theme.of(context).textTheme.titleLarge,
              ).animate().fade().slideY(begin: 0.2, end: 0),
              const SizedBox(height: 8),
              Text(
                'Describe your AI worker and we will generate a unique 8-bit pixel character.',
                style: Theme.of(context).textTheme.bodyLarge,
              ).animate().fade(delay: 100.ms).slideY(begin: 0.2, end: 0),
              const SizedBox(height: 32),

              // Image Preview Area
              Center(
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: AppColors.textMuted.withOpacity(0.2),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.05),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: _buildImagePreview(),
                  ),
                ).animate(target: _generatedImageUrl != null ? 1 : 0).scaleXY(
                      begin: 0.95,
                      end: 1.0,
                      curve: Curves.easeOutBack,
                      duration: 500.ms,
                    ),
              ),

              const SizedBox(height: 48),

              // Input Column
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _promptController,
                    decoration: const InputDecoration(
                      hintText: 'e.g. A cyberpunk cat hacker',
                      labelText: 'Appearance prompt',
                    ),
                    enabled: !_isGenerating,
                    onSubmitted: (_) => _generateAvatar(),
                  ).animate().fade(delay: 200.ms).slideY(begin: 0.2, end: 0),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: _isGenerating ? null : _generateAvatar,
                    icon: _isGenerating
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.auto_awesome),
                    label: Text(
                        _isGenerating ? 'Generating...' : 'Generate Character'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ).animate().fade(delay: 300.ms).slideY(begin: 0.2, end: 0),
                  if (_generatedImageUrl != null) ...[
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: () {
                        // TODO: Save to user profile via Provider
                        context.pop();
                      },
                      icon: const Icon(Icons.check),
                      label: const Text('Save to Profile'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ).animate().fade().slideY(begin: 0.2, end: 0),
                  ]
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImagePreview() {
    if (_isGenerating) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.generating_tokens,
                    size: 48, color: AppColors.accent)
                .animate(onPlay: (controller) => controller.repeat())
                .shimmer(duration: 1500.ms, color: AppColors.primaryLight),
            const SizedBox(height: 16),
            Text(
              'Painting pixels...',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            )
          ],
        ),
      );
    }

    if (_generatedImageUrl != null) {
      // The crucial part for pixel art: filterQuality: FilterQuality.none
      // We use a mock placeholder PNG that we can just load.
      // Since it's a mock, we'll try to just load a network image.
      // For fallback we show a simple icon.
      return Image.network(
        _generatedImageUrl!,
        fit: BoxFit.cover,
        filterQuality: FilterQuality.none, // Key for crisp pixels!
        errorBuilder: (context, error, stackTrace) {
          return const Center(
            child: Icon(Icons.person, size: 80, color: AppColors.textMuted),
          );
        },
      ).animate().fadeIn(duration: 600.ms);
    }

    // Empty state
    return Center(
      child: Icon(
        Icons.person_outline,
        size: 64,
        color: AppColors.textMuted.withOpacity(0.3),
      ),
    );
  }
}
