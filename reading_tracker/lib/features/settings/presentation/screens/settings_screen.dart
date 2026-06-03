import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_theme_controller.dart';
import '../../../stats/domain/entities/statistics_summary.dart';
import '../../../stats/presentation/providers/statistics_summary_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedTheme = ref.watch(appThemeControllerProvider);
    final controller = ref.read(appThemeControllerProvider.notifier);
    final summary =
        ref.watch(statisticsSummaryProvider).valueOrNull ??
        const StatisticsSummary.empty();

    return Scaffold(
      appBar: AppBar(title: const Text('Perfil')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 112),
        children: [
          _ProfileHero(summary: summary),
          const SizedBox(height: AppSpacing.lg),
          _ProfileMetrics(summary: summary),
          const SizedBox(height: AppSpacing.lg),
          _ThemePreferenceCard(
            selectedTheme: selectedTheme,
            onChanged: controller.setTheme,
          ),
          const SizedBox(height: AppSpacing.lg),
          const _ComingSoonCard(),
        ],
      ),
    );
  }
}

class _ProfileHero extends StatelessWidget {
  const _ProfileHero({required this.summary});

  final StatisticsSummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final goal = summary.annualReadingGoal;
    final goalText = goal == null
        ? 'Reto lector pendiente'
        : '${summary.completedThisYear}/$goal libros este año';

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
                  'Daniela',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  goalText,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.78),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                _ProfileHeroPill(
                  icon: AppIcons.fire,
                  label: '${summary.currentStreakDays} días de racha',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileHeroPill extends StatelessWidget {
  const _ProfileHeroPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: 7),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileMetrics extends StatelessWidget {
  const _ProfileMetrics({required this.summary});

  final StatisticsSummary summary;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: AppSpacing.md,
      crossAxisSpacing: AppSpacing.md,
      childAspectRatio: 1.35,
      children: [
        _ProfileMetricCard(
          icon: AppIcons.library,
          value: '${summary.totalBooks}',
          label: 'Libros registrados',
        ),
        _ProfileMetricCard(
          icon: AppIcons.pages,
          value: _compactNumber(summary.totalPagesRead),
          label: 'Páginas leídas',
        ),
        _ProfileMetricCard(
          icon: AppIcons.book,
          value: '${summary.currentlyReadingCount}',
          label: 'Lecturas activas',
        ),
        _ProfileMetricCard(
          icon: AppIcons.star,
          value: summary.averageRating == null
              ? '-'
              : summary.averageRating!.toStringAsFixed(1),
          label: 'Rating medio',
        ),
      ],
    );
  }

  String _compactNumber(int value) {
    if (value >= 1000) {
      final compact = value / 1000;
      return '${compact.toStringAsFixed(compact >= 10 ? 0 : 1)}k';
    }
    return '$value';
  }
}

class _ProfileMetricCard extends StatelessWidget {
  const _ProfileMetricCard({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.08),
        ),
        boxShadow: AppShadows.editorial(theme.colorScheme.primary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: theme.colorScheme.primary, size: 24),
          const Spacer(),
          Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
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
                  fontWeight: FontWeight.w900,
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
          SegmentedButton<ReadingTrackerTheme>(
            segments: ReadingTrackerTheme.values
                .map(
                  (theme) => ButtonSegment(
                    value: theme,
                    label: Text(theme.label),
                  ),
                )
                .toList(),
            selected: {selectedTheme},
            onSelectionChanged: (selection) => onChanged(selection.first),
          ),
        ],
      ),
    );
  }
}

class _ComingSoonCard extends StatelessWidget {
  const _ComingSoonCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.07),
        ),
      ),
      child: Row(
        children: [
          Icon(AppIcons.bookmark, color: theme.colorScheme.primary),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              'Preferencias personales y perfil editable llegarán en una próxima fase.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
