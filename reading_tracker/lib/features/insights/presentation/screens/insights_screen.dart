import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/branding/branding.dart';
import '../../../../core/design_system/design_system.dart';
import '../../../../core/preferences/reader_profile_controller.dart';
import '../../domain/entities/reading_insights_summary.dart';
import '../providers/reading_insights_summary_provider.dart';

class InsightsScreen extends ConsumerWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(readingInsightsSummaryProvider);
    final readerProfile = ref.watch(readerProfileControllerProvider);
    final theme = Theme.of(context);

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
                theme.colorScheme.primaryContainer.withValues(alpha: 0.16),
                theme.scaffoldBackgroundColor,
              ],
              stops: const [0, 0.42, 1],
            ),
          ),
          child: summaryAsync.when(
            loading: () => const _InsightsLoadingState(),
            error: (error, _) => _InsightsErrorState(
              onRetry: () => ref.invalidate(readingInsightsSummaryProvider),
            ),
            data: (summary) {
              if (!summary.hasAnyInsight) {
                return const _InsightsEmptyState();
              }

              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 132),
                children: [
                  _InsightsHeader(readerProfile: readerProfile),
                  const SizedBox(height: AppSpacing.xl),
                  _InsightsHero(summary: summary),
                  const SizedBox(height: AppSpacing.lg),
                  _InsightMetrics(summary: summary),
                  const SizedBox(height: AppSpacing.lg),
                  _PrimaryInsightPanel(summary: summary),
                  const SizedBox(height: AppSpacing.xxl),
                  _SectionTitle(
                    eyebrow: 'LECTURA PERSONAL',
                    title: 'Tu perfil lector',
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _InsightGrid(
                    children: [
                      _InsightCard(
                        icon: AppIcons.profile,
                        title: 'Autor favorito',
                        value: summary.mostReadAuthor ?? 'Sin datos',
                        subtitle: _formatPages(summary.mostReadAuthorPages),
                      ),
                      _InsightCard(
                        icon: AppIcons.bookmark,
                        title: 'Género favorito',
                        value: summary.favoriteGenre ?? 'Sin datos',
                        subtitle: summary.favoriteGenre == null
                            ? 'Sin géneros registrados'
                            : _formatPages(summary.favoriteGenrePages),
                      ),
                      _InsightCard(
                        icon: AppIcons.pages,
                        title: 'Libro más largo',
                        value: summary.longestBookTitle ?? 'Sin datos',
                        subtitle: summary.longestBookPages == null
                            ? 'Sin libros completados con páginas'
                            : '${summary.longestBookPages} páginas',
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  _SectionTitle(
                    eyebrow: 'MEJORES LECTURAS',
                    title: 'Lecturas destacadas',
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _RatedBooksCard(books: summary.topRatedBooks),
                  const SizedBox(height: AppSpacing.xxl),
                  _SectionTitle(eyebrow: 'PATRONES', title: 'Curiosidades'),
                  const SizedBox(height: AppSpacing.md),
                  _InsightGrid(
                    children: [
                      _InsightCard(
                        icon: AppIcons.book,
                        title: 'Libro más largo',
                        value: summary.longestBookTitle ?? 'Sin datos',
                        subtitle: summary.longestBookPages == null
                            ? 'Sin libros completados con páginas'
                            : '${summary.longestBookPages} pag.',
                      ),
                      _InsightCard(
                        icon: AppIcons.calendar,
                        title: 'Mes con más lectura',
                        value: summary.mostActiveMonth == null
                            ? 'Sin datos'
                            : _formatMonth(summary.mostActiveMonth!),
                        subtitle: _formatActivity(
                          pages: summary.mostActiveMonthPages,
                          minutes: summary.mostActiveMonthMinutes,
                        ),
                      ),
                      _InsightCard(
                        icon: AppIcons.time,
                        title: 'Franja habitual',
                        value: summary.usualReadingTimeSlot ?? 'Sin datos',
                        subtitle: summary.usualReadingTimeSlot == null
                            ? 'Aún no hay sesiones registradas'
                            : _formatCount(
                                summary.usualReadingTimeSlotSessions,
                                'sesión',
                              ),
                      ),
                      _InsightCard(
                        icon: AppIcons.fire,
                        title: 'Día más activo',
                        value: summary.mostActiveDay == null
                            ? 'Sin datos'
                            : _formatDate(summary.mostActiveDay!),
                        subtitle: _formatActivity(
                          pages: summary.mostActiveDayPages,
                          minutes: summary.mostActiveDayMinutes,
                        ),
                      ),
                    ],
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

class _InsightsHeader extends StatelessWidget {
  const _InsightsHeader({required this.readerProfile});

  final ReaderProfile readerProfile;

  @override
  Widget build(BuildContext context) {
    return AppBrandHeader(
      readerProfile: readerProfile,
      onTap: () =>
          Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false),
    );
  }
}

class _InsightsHero extends StatelessWidget {
  const _InsightsHero({required this.summary});

  final ReadingInsightsSummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final headline =
        summary.favoriteGenre ?? summary.mostReadAuthor ?? 'Tu ritmo';
    final caption = summary.favoriteGenre != null
        ? '${summary.favoriteGenrePages} páginas en tu género más leído'
        : summary.mostReadAuthor != null
        ? '${summary.mostReadAuthorPages} páginas con tu autor favorito'
        : 'Cada sesión empieza a dibujar tu mapa lector';

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 26, 24, 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primary,
            Color.lerp(theme.colorScheme.primary, Colors.black, 0.30)!,
          ],
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: AppShadows.soft(theme.colorScheme.primary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Insights',
            style: GoogleFonts.cormorantGaramond(
              textStyle: theme.textTheme.displaySmall?.copyWith(
                color: Colors.white,
                fontSize: 39,
                fontWeight: FontWeight.w700,
                height: 1.02,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Patrones, gustos y señales de tu vida lectora.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.78),
              height: 1.35,
            ),
          ),
          const SizedBox(height: 28),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
            ),
            child: Row(
              children: [
                const Icon(AppIcons.star, color: Colors.white, size: 28),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        headline,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.cormorantGaramond(
                          textStyle: theme.textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontSize: 27,
                            fontWeight: FontWeight.w700,
                            height: 1.05,
                          ),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        caption,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.76),
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

class _InsightMetrics extends StatelessWidget {
  const _InsightMetrics({required this.summary});

  final ReadingInsightsSummary summary;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _MetricPill(
            icon: AppIcons.book,
            value: '${summary.completedBooksThisYear}',
            label: 'Terminados',
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _MetricPill(
            icon: AppIcons.fire,
            value: '${summary.bestStreakDays}',
            label: 'Mejor racha',
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _MetricPill(
            icon: AppIcons.pages,
            value: summary.averagePagesPerSession == null
                ? '-'
                : summary.averagePagesPerSession!.round().toString(),
            label: 'Pag./sesión',
          ),
        ),
      ],
    );
  }
}

class _PrimaryInsightPanel extends StatelessWidget {
  const _PrimaryInsightPanel({required this.summary});

  final ReadingInsightsSummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final insight = _primaryInsight();

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.08),
        ),
        boxShadow: AppShadows.editorial(theme.colorScheme.primary),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: theme.colorScheme.secondary.withValues(alpha: 0.24),
              shape: BoxShape.circle,
            ),
            child: Icon(insight.icon, color: theme.colorScheme.primary),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  insight.label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.4,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  insight.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  insight.subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  ({IconData icon, String label, String title, String subtitle})
  _primaryInsight() {
    if (summary.hasFinishPrediction) {
      return (
        icon: AppIcons.calendar,
        label: 'PRÓXIMO HITO',
        title: summary.finishPredictionBookTitle!,
        subtitle:
            '${summary.finishPredictionRemainingPages} páginas restantes · ${summary.finishPredictionDaysRemaining} días estimados',
      );
    }

    if (summary.topRatedBookTitle != null) {
      return (
        icon: AppIcons.star,
        label: 'MEJOR LECTURA',
        title: summary.topRatedBookTitle!,
        subtitle: summary.topRatedBookRating == null
            ? 'Una de tus lecturas destacadas'
            : '${summary.topRatedBookRating!.toStringAsFixed(1)} / 5 de valoración',
      );
    }

    if (summary.longestBookTitle != null) {
      return (
        icon: AppIcons.book,
        label: 'LECTURA MÁS EXTENSA',
        title: summary.longestBookTitle!,
        subtitle: summary.longestBookPages == null
            ? 'Tu libro completado más largo'
            : '${summary.longestBookPages} páginas',
      );
    }

    return (
      icon: AppIcons.insightsNav,
      label: 'DESCUBRIMIENTO',
      title:
          summary.favoriteGenre ?? summary.mostReadAuthor ?? 'Tu mapa lector',
      subtitle: 'Tus sesiones empiezan a revelar patrones personales.',
    );
  }
}

class _MetricPill extends StatelessWidget {
  const _MetricPill({
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.08),
        ),
        boxShadow: AppShadows.editorial(theme.colorScheme.primary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: theme.colorScheme.primary, size: 20),
          const SizedBox(height: AppSpacing.sm),
          Text(
            value,
            style: GoogleFonts.cormorantGaramond(
              textStyle: theme.textTheme.titleLarge?.copyWith(
                color: theme.colorScheme.primary,
                fontSize: 29,
                fontWeight: FontWeight.w700,
                height: 1,
              ),
            ),
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.eyebrow, required this.title});

  final String eyebrow;
  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          eyebrow,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.primary.withValues(alpha: 0.72),
            fontWeight: FontWeight.w800,
            letterSpacing: 2.4,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          title,
          style: GoogleFonts.cormorantGaramond(
            textStyle: theme.textTheme.headlineSmall?.copyWith(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              height: 1.08,
            ),
          ),
        ),
      ],
    );
  }
}

class _InsightGrid extends StatelessWidget {
  const _InsightGrid({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth >= 640
            ? (constraints.maxWidth - 24) / 3
            : constraints.maxWidth >= 380
            ? (constraints.maxWidth - 12) / 2
            : constraints.maxWidth;

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final child in children) SizedBox(width: width, child: child),
          ],
        );
      },
    );
  }
}

class _InsightCard extends StatelessWidget {
  const _InsightCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String value;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      constraints: const BoxConstraints(minHeight: 168),
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
          Icon(icon, color: theme.colorScheme.primary, size: 23),
          const SizedBox(height: AppSpacing.md),
          Text(
            title,
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            subtitle,
            maxLines: 2,
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

class _RatedBooksCard extends StatelessWidget {
  const _RatedBooksCard({required this.books});

  final List<ReadingInsightRatedBook> books;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.08),
        ),
        boxShadow: AppShadows.editorial(theme.colorScheme.primary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(AppIcons.star, color: theme.colorScheme.primary),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Top 3 del año',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (books.isEmpty)
            Text(
              'Aún no hay libros valorados este año.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            )
          else
            for (var index = 0; index < books.length; index++) ...[
              _RatedBookRow(position: index + 1, book: books[index]),
              if (index < books.length - 1) const Divider(height: 18),
            ],
        ],
      ),
    );
  }
}

class _RatedBookRow extends StatelessWidget {
  const _RatedBookRow({required this.position, required this.book});

  final int position;
  final ReadingInsightRatedBook book;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Container(
          width: 30,
          height: 30,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: theme.colorScheme.secondary.withValues(alpha: 0.22),
            shape: BoxShape.circle,
          ),
          child: Text(
            '$position',
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Text(
            book.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          '${book.rating.toStringAsFixed(book.rating % 1 == 0 ? 1 : 2)} / 5',
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _InsightsEmptyState extends ConsumerWidget {
  const _InsightsEmptyState();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final readerProfile = ref.watch(readerProfileControllerProvider);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 132),
      children: [
        _InsightsHeader(readerProfile: readerProfile),
        const SizedBox(height: AppSpacing.xl),
        Container(
          padding: const EdgeInsets.fromLTRB(26, 30, 26, 28),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: theme.colorScheme.primary.withValues(alpha: 0.08),
            ),
            boxShadow: AppShadows.soft(theme.colorScheme.primary),
          ),
          child: Column(
            children: [
              Container(
                width: 74,
                height: 74,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.colorScheme.secondary.withValues(alpha: 0.24),
                ),
                child: Icon(
                  AppIcons.insightsNav,
                  size: 36,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                '¡Añade tu primer libro!',
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Aquí tendrás un resumen de tu actividad lectora.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Podrás ver tu ritmo de lectura, páginas leídas, libros completados y mucho más.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => Navigator.pushNamed(context, '/book/add'),
                  icon: const Icon(AppIcons.add),
                  label: const Text('Añadir primer libro'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(54),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _InsightsLoadingState extends ConsumerWidget {
  const _InsightsLoadingState();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final readerProfile = ref.watch(readerProfileControllerProvider);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 132),
      children: [
        _InsightsHeader(readerProfile: readerProfile),
        const SizedBox(height: AppSpacing.xl),
        Container(
          height: 230,
          decoration: BoxDecoration(
            color: theme.colorScheme.surface.withValues(alpha: 0.62),
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Row(
          children: [
            for (var index = 0; index < 3; index++) ...[
              Expanded(
                child: Container(
                  height: 112,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface.withValues(alpha: 0.50),
                    borderRadius: BorderRadius.circular(22),
                  ),
                ),
              ),
              if (index < 2) const SizedBox(width: AppSpacing.sm),
            ],
          ],
        ),
      ],
    );
  }
}

class _InsightsErrorState extends ConsumerWidget {
  const _InsightsErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final readerProfile = ref.watch(readerProfileControllerProvider);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 132),
      children: [
        _InsightsHeader(readerProfile: readerProfile),
        const SizedBox(height: AppSpacing.xl),
        Container(
          padding: const EdgeInsets.fromLTRB(26, 28, 26, 26),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: theme.colorScheme.error.withValues(alpha: 0.14),
            ),
          ),
          child: Column(
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 42,
                color: theme.colorScheme.error,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'No pudimos cargar tus insights',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Inténtalo otra vez en unos segundos.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

String _formatPages(int pages) {
  if (pages <= 0) return 'Aún no hay datos suficientes';
  return '$pages pag. leídas';
}

String _formatDate(DateTime date) {
  return '${date.day}/${date.month}/${date.year}';
}

String _formatMinutes(int minutes) {
  if (minutes < 60) return '$minutes min';
  final hours = minutes ~/ 60;
  final remainingMinutes = minutes % 60;
  if (remainingMinutes == 0) return '${hours}h';
  return '${hours}h ${remainingMinutes}min';
}

String _formatCount(int value, String singular) {
  if (value == 1) return '1 $singular';
  return '$value ${singular}s';
}

String _formatActivity({required int pages, required int minutes}) {
  if (pages <= 0 && minutes <= 0) return 'Aún no hay datos suficientes';
  if (pages > 0 && minutes > 0) {
    return '$pages pag. · ${_formatMinutes(minutes)}';
  }
  if (pages > 0) return '$pages pag. leídas';
  return _formatMinutes(minutes);
}

String _formatMonth(DateTime month) {
  const names = [
    'enero',
    'febrero',
    'marzo',
    'abril',
    'mayo',
    'junio',
    'julio',
    'agosto',
    'septiembre',
    'octubre',
    'noviembre',
    'diciembre',
  ];
  return '${names[month.month - 1]} ${month.year}';
}
