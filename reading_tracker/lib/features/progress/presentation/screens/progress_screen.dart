import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/branding/branding.dart';
import '../../../../core/design_system/design_system.dart';
import '../../../../core/preferences/reader_profile_controller.dart';
import '../../../books/domain/entities/book.dart';
import '../../../books/domain/enums/book_status.dart';
import '../../../books/presentation/providers/books_provider.dart';
import '../../../reading_sessions/domain/entities/reading_session.dart';
import '../../../reading_sessions/presentation/providers/reading_sessions_provider.dart';
import '../../../stats/domain/entities/statistics_summary.dart';
import '../../../stats/presentation/providers/statistics_summary_provider.dart';

class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final readerProfile = ref.watch(readerProfileControllerProvider);
    final summaryAsync = ref.watch(statisticsSummaryProvider);
    final books = ref.watch(booksProvider).valueOrNull ?? const <Book>[];
    final sessionsAsync = ref.watch(
      readingSessionsForRangeProvider(_recentRange()),
    );

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                theme.scaffoldBackgroundColor,
                theme.colorScheme.primaryContainer.withValues(alpha: 0.10),
                theme.scaffoldBackgroundColor,
              ],
              stops: const [0, 0.40, 1],
            ),
          ),
          child: summaryAsync.when(
            loading: () => const _ProgressLoadingState(),
            error: (error, _) => const _ProgressErrorState(),
            data: (summary) {
              final activeBook = _activeReadingBook(books);
              final sessions = sessionsAsync.valueOrNull ?? const [];

              return ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.md,
                  AppSpacing.lg,
                  128,
                ),
                children: [
                  _ProgressHeader(readerProfile: readerProfile),
                  const SizedBox(height: AppSpacing.xxl),
                  _ProgressHero(summary: summary, activeBook: activeBook),
                  const SizedBox(height: AppSpacing.xl),
                  _ReadingChallengeCard(
                    summary: summary,
                    onTap: () => Navigator.pushNamed(context, '/stats'),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  _ReadingActivityCard(
                    sessions: sessions,
                    isLoading: sessionsAsync.isLoading,
                    onCalendarTap: () =>
                        Navigator.pushNamed(context, '/calendar'),
                    onRegisterTap: () =>
                        Navigator.pushNamed(context, '/session/add'),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  _QuickAccessSection(
                    onStatsTap: () => Navigator.pushNamed(context, '/stats'),
                    onCalendarTap: () =>
                        Navigator.pushNamed(context, '/calendar'),
                    onSessionTap: () =>
                        Navigator.pushNamed(context, '/session/add'),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ProgressHeader extends StatelessWidget {
  const _ProgressHeader({required this.readerProfile});

  final ReaderProfile readerProfile;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppBrandHeader(
          readerProfile: readerProfile,
          onTap: () {
            Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
          },
          onProfileTap: () => Navigator.pushNamed(context, '/settings'),
          onAddBookTap: () => Navigator.pushNamed(context, '/book/add'),
          onCalendarTap: () => Navigator.pushNamed(context, '/calendar'),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'Sigue tu ritmo, tus retos y tu actividad lectora.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.primary.withValues(alpha: 0.72),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _ProgressLoadingState extends StatelessWidget {
  const _ProgressLoadingState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        128,
      ),
      children: [
        Container(
          height: 104,
          decoration: BoxDecoration(
            color: theme.colorScheme.surface.withValues(alpha: 0.62),
            borderRadius: BorderRadius.circular(26),
          ),
        ),
        const SizedBox(height: AppSpacing.xxl),
        Container(
          height: 210,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(32),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        for (var index = 0; index < 3; index++) ...[
          Container(
            height: 130,
            decoration: BoxDecoration(
              color: theme.colorScheme.surface.withValues(alpha: 0.66),
              borderRadius: BorderRadius.circular(28),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ],
    );
  }
}

class _ProgressErrorState extends StatelessWidget {
  const _ProgressErrorState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(26, 28, 26, 26),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface.withValues(alpha: 0.76),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: theme.colorScheme.primary.withValues(alpha: 0.08),
            ),
            boxShadow: AppShadows.soft(theme.colorScheme.primary),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(AppIcons.chart, color: theme.colorScheme.primary, size: 36),
              const SizedBox(height: 16),
              Text(
                'No pudimos cargar tu progreso',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Tus datos siguen guardados. Vuelve a intentarlo en unos segundos.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProgressHero extends StatelessWidget {
  const _ProgressHero({required this.summary, required this.activeBook});

  final StatisticsSummary summary;
  final Book? activeBook;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final dark = Color.lerp(primary, Colors.black, 0.30)!;
    final accent = theme.colorScheme.secondary;
    final year = DateTime.now().year;

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [primary, dark],
        ),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: dark.withValues(alpha: 0.28),
            blurRadius: 44,
            offset: const Offset(0, 24),
          ),
          BoxShadow(
            color: accent.withValues(alpha: 0.16),
            blurRadius: 26,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'RESUMEN LECTOR',
            style: theme.textTheme.labelSmall?.copyWith(
              color: accent.withValues(alpha: 0.96),
              letterSpacing: 2.6,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: _HeroMetric(
                  value: '${summary.currentStreakDays}',
                  label: 'racha',
                ),
              ),
              Expanded(
                child: _HeroMetric(
                  value: '${summary.completedThisYear}',
                  label: 'libros $year',
                ),
              ),
              Expanded(
                child: _HeroMetric(
                  value: _compactNumber(summary.totalPagesRead),
                  label: 'páginas',
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Row(
              children: [
                Icon(AppIcons.book, color: accent, size: 22),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Lectura activa',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: accent.withValues(alpha: 0.92),
                          letterSpacing: 1.4,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        activeBook == null
                            ? 'Sin lectura activa por ahora'
                            : activeBook!.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onPrimary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
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

class _HeroMetric extends StatelessWidget {
  const _HeroMetric({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            value,
            maxLines: 1,
            style: GoogleFonts.cormorantGaramond(
              textStyle: theme.textTheme.headlineSmall?.copyWith(
                color: theme.colorScheme.onPrimary,
                fontSize: 40,
                fontWeight: FontWeight.w800,
                height: 0.92,
              ),
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onPrimary.withValues(alpha: 0.74),
          ),
        ),
      ],
    );
  }
}

class _ReadingChallengeCard extends StatelessWidget {
  const _ReadingChallengeCard({required this.summary, required this.onTap});

  final StatisticsSummary summary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final goal = summary.annualReadingGoal;
    final year = DateTime.now().year;
    final rawProgress = summary.annualGoalProgress ?? 0;
    final progress = (rawProgress / 100).clamp(0, 1).toDouble();
    final percent = rawProgress.clamp(0, 100).round();

    return _EditorialSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Reto lector $year',
                  style: GoogleFonts.cormorantGaramond(
                    textStyle: theme.textTheme.headlineSmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      height: 1,
                    ),
                  ),
                ),
              ),
              _SoftBadge(text: goal == null ? 'Sin reto' : '$percent%'),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            goal == null
                ? 'Configura tu objetivo anual para seguir el avance de tu año lector.'
                : '${summary.completedThisYear} / $goal libros completados',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.md),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: goal == null ? 0 : progress,
              minHeight: 7,
              backgroundColor: theme.colorScheme.primaryContainer.withValues(
                alpha: 0.42,
              ),
              color: theme.colorScheme.secondary,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          OutlinedButton.icon(
            onPressed: onTap,
            icon: Icon(goal == null ? AppIcons.flag : AppIcons.chart, size: 18),
            label: Text(goal == null ? 'Configurar reto' : 'Ver estadísticas'),
          ),
        ],
      ),
    );
  }
}

class _ReadingActivityCard extends StatelessWidget {
  const _ReadingActivityCard({
    required this.sessions,
    required this.isLoading,
    required this.onCalendarTap,
    required this.onRegisterTap,
  });

  final List<ReadingSession> sessions;
  final bool isLoading;
  final VoidCallback onCalendarTap;
  final VoidCallback onRegisterTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final recent = [...sessions]..sort((a, b) => b.date.compareTo(a.date));

    return _EditorialSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Actividad lectora',
            style: GoogleFonts.cormorantGaramond(
              textStyle: theme.textTheme.headlineSmall?.copyWith(
                color: theme.colorScheme.primary,
                fontSize: 28,
                fontWeight: FontWeight.w700,
                height: 1,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Calendario y sesiones para entender tu ritmo real.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: _InlineAction(
                  icon: AppIcons.calendar,
                  label: 'Calendario',
                  onTap: onCalendarTap,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _InlineAction(
                  icon: AppIcons.add,
                  label: 'Registrar',
                  onTap: onRegisterTap,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          if (isLoading)
            const LinearProgressIndicator(minHeight: 2)
          else if (recent.isEmpty)
            Text(
              'Aún no hay sesiones recientes registradas.',
              style: theme.textTheme.bodySmall,
            )
          else
            for (final session in recent.take(3))
              _SessionPreview(session: session),
        ],
      ),
    );
  }
}

class _InlineAction extends StatelessWidget {
  const _InlineAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.surface.withValues(alpha: 0.94),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: theme.colorScheme.primary.withValues(alpha: 0.12),
            ),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.primary.withValues(alpha: 0.06),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: theme.colorScheme.primary, size: 18),
              const SizedBox(width: AppSpacing.xs),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SessionPreview extends StatelessWidget {
  const _SessionPreview({required this.session});

  final ReadingSession session;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final value = [
      if (session.pagesRead > 0) '${session.pagesRead} pág.',
      if (session.minutes > 0) '${session.minutes} min',
    ].join(' · ');

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: theme.colorScheme.secondary,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              value.isEmpty ? 'Sesión registrada' : value,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            _humanDate(session.date),
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.primary.withValues(alpha: 0.70),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickAccessSection extends StatelessWidget {
  const _QuickAccessSection({
    required this.onStatsTap,
    required this.onCalendarTap,
    required this.onSessionTap,
  });

  final VoidCallback onStatsTap;
  final VoidCallback onCalendarTap;
  final VoidCallback onSessionTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Accesos rápidos',
          style: GoogleFonts.cormorantGaramond(
            textStyle: theme.textTheme.headlineSmall?.copyWith(
              color: theme.colorScheme.primary,
              fontSize: 28,
              fontWeight: FontWeight.w700,
              height: 1,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        _QuickAccessCard(
          icon: AppIcons.chart,
          title: 'Estadísticas',
          description: 'Resumen completo de biblioteca, ritmo y valoración.',
          onTap: onStatsTap,
        ),
        const SizedBox(height: AppSpacing.md),
        _QuickAccessCard(
          icon: AppIcons.calendar,
          title: 'Calendario',
          description: 'Explora tus días activos y sesiones registradas.',
          onTap: onCalendarTap,
        ),
        const SizedBox(height: AppSpacing.md),
        _QuickAccessCard(
          icon: AppIcons.add,
          title: 'Registrar sesión',
          description: 'Añade páginas, minutos y notas a una lectura activa.',
          onTap: onSessionTap,
        ),
      ],
    );
  }
}

class _QuickAccessCard extends StatelessWidget {
  const _QuickAccessCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: theme.colorScheme.primary.withValues(alpha: 0.16),
            ),
            boxShadow: AppShadows.editorial(theme.colorScheme.primary),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.colorScheme.secondary.withValues(alpha: 0.28),
                ),
                child: Icon(icon, color: theme.colorScheme.primary, size: 21),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(description, style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: theme.colorScheme.primary.withValues(alpha: 0.58),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EditorialSurface extends StatelessWidget {
  const _EditorialSurface({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.90),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.16),
        ),
        boxShadow: AppShadows.editorial(theme.colorScheme.primary),
      ),
      child: child,
    );
  }
}

class _SoftBadge extends StatelessWidget {
  const _SoftBadge({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.14),
        ),
      ),
      child: Text(
        text,
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

Book? _activeReadingBook(List<Book> books) {
  final reading = books
      .where((book) => book.status == BookStatus.reading)
      .toList();
  if (reading.isEmpty) return null;
  reading.sort((a, b) {
    final aDate = a.updatedAt ?? a.startDate ?? a.createdAt;
    final bDate = b.updatedAt ?? b.startDate ?? b.createdAt;
    return bDate.compareTo(aDate);
  });
  return reading.first;
}

DateRange _recentRange() {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  return DateRange(
    start: today.subtract(const Duration(days: 30)),
    end: today.add(const Duration(days: 1)),
  );
}

String _compactNumber(int value) {
  if (value >= 1000) {
    final compact = value / 1000;
    return '${compact.toStringAsFixed(compact >= 10 ? 0 : 1)}k';
  }
  return '$value';
}

String _humanDate(DateTime date) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(date.year, date.month, date.day);
  final difference = today.difference(day).inDays;
  if (difference == 0) return 'Hoy';
  if (difference == 1) return 'Ayer';
  if (difference > 1 && difference < 7) return 'Hace $difference días';

  const months = [
    'ene',
    'feb',
    'mar',
    'abr',
    'may',
    'jun',
    'jul',
    'ago',
    'sep',
    'oct',
    'nov',
    'dic',
  ];
  return '${date.day} ${months[date.month - 1]}';
}
