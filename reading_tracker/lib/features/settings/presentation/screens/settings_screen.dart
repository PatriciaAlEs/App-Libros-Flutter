import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/branding/branding.dart';
import '../../../../core/design_system/design_system.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_theme_controller.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedTheme = ref.watch(appThemeControllerProvider);
    final controller = ref.read(appThemeControllerProvider.notifier);

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            132,
          ),
          children: [
            AppBrandHeader(
              onTap: () =>
                  Navigator.pushNamedAndRemoveUntil(context, '/', (_) => false),
            ),
            const SizedBox(height: AppSpacing.xl),
            const _ProfileHero(),
            const SizedBox(height: AppSpacing.lg),
            _ThemePreferenceCard(
              selectedTheme: selectedTheme,
              onChanged: controller.setTheme,
            ),
            const SizedBox(height: AppSpacing.lg),
            const _PreferencesAction(),
          ],
        ),
      ),
    );
  }
}

class _ProfileHero extends StatelessWidget {
  const _ProfileHero();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 26, 24, 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primary,
            Color.lerp(theme.colorScheme.primary, Colors.black, 0.26)!,
          ],
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: AppShadows.soft(theme.colorScheme.primary),
      ),
      child: Row(
        children: [
          Container(
            width: 70,
            height: 70,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.20)),
            ),
            child: const Icon(AppIcons.profile, color: Colors.white, size: 32),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Perfil y preferencias',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Preferencias, estilo visual y detalles personales de ReadPp.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.78),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ThemePreferenceCard extends StatelessWidget {
  const _ThemePreferenceCard({
    required this.selectedTheme,
    required this.onChanged,
  });

  final ReadingTrackerTheme selectedTheme;
  final ValueChanged<ReadingTrackerTheme> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.palette_outlined, color: theme.colorScheme.primary),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Estilo visual',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Elige la paleta que mejor acompaña tu lectura.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          for (final option in ReadingTrackerTheme.values) ...[
            _ThemePreviewOption(
              option: option,
              isSelected: option == selectedTheme,
              onTap: () => onChanged(option),
            ),
            if (option != ReadingTrackerTheme.values.last)
              const SizedBox(height: AppSpacing.md),
          ],
        ],
      ),
    );
  }
}

class _ThemePreviewOption extends StatelessWidget {
  const _ThemePreviewOption({
    required this.option,
    required this.isSelected,
    required this.onTap,
  });

  final ReadingTrackerTheme option;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: isSelected
                ? option.accent.withValues(alpha: 0.18)
                : theme.colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.54,
                  ),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: isSelected
                  ? option.primary.withValues(alpha: 0.54)
                  : theme.colorScheme.primary.withValues(alpha: 0.08),
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              _ThemePreviewSwatch(option: option),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      option.label,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      option == ReadingTrackerTheme.burgundy
                          ? 'Editorial cálido y protagonista.'
                          : 'Calma visual para lectura pausada.',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 26,
                height: 26,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? option.primary : Colors.transparent,
                  border: Border.all(
                    color: isSelected
                        ? option.primary
                        : theme.colorScheme.outlineVariant,
                  ),
                ),
                child: isSelected
                    ? const Icon(
                        Icons.check_rounded,
                        size: 17,
                        color: Colors.white,
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ThemePreviewSwatch extends StatelessWidget {
  const _ThemePreviewSwatch({required this.option});

  final ReadingTrackerTheme option;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 62,
      height: 48,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: option.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: option.primary.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: option.primary,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(width: 5),
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: option.accent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 5),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: option.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: option.primary.withValues(alpha: 0.10),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PreferencesAction extends StatelessWidget {
  const _PreferencesAction();

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () => _showComingSoon(context),
      icon: const Icon(Icons.auto_awesome_rounded),
      label: const Text('Ajustes y preferencias'),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 18),
      ),
    );
  }

  void _showComingSoon(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Text('💅', style: TextStyle(fontSize: 34)),
        title: const Text('Próximamente'),
        content: const Text(
          'Seguimos trabajando en nuevas funciones para lectoras.',
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }
}
