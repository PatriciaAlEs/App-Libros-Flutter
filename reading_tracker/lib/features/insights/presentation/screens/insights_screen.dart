import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/reading_insights_summary.dart';
import '../../../stats/presentation/widgets/stat_card.dart';
import '../providers/reading_insights_summary_provider.dart';

class InsightsScreen extends ConsumerWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(readingInsightsSummaryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Insights')),
      body: summaryAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _InsightsErrorState(
          onRetry: () => ref.invalidate(readingInsightsSummaryProvider),
        ),
        data: (summary) {
          if (!summary.hasAnyInsight) {
            return const _InsightsEmptyState();
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _InsightsSection(
                title: 'Preferencias',
                children: [
                  StatCard(
                    icon: Icons.menu_book_outlined,
                    title: 'Libro mas leido',
                    value: summary.mostReadBookTitle ?? 'Sin datos',
                    subtitle: _formatPages(summary.mostReadBookPages),
                  ),
                  StatCard(
                    icon: Icons.person_outline,
                    title: 'Autor mas leido',
                    value: summary.mostReadAuthor ?? 'Sin datos',
                    subtitle: _formatPages(summary.mostReadAuthorPages),
                  ),
                  StatCard(
                    icon: Icons.category_outlined,
                    title: 'Genero favorito',
                    value: summary.favoriteGenre ?? 'Sin datos',
                    subtitle: summary.favoriteGenre == null
                        ? 'Sin generos registrados'
                        : _formatPages(summary.favoriteGenrePages),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _InsightsSection(
                title: 'Reading Pace',
                children: [
                  StatCard(
                    icon: Icons.auto_stories_outlined,
                    title: 'Paginas por sesion',
                    value: _formatAverage(summary.averagePagesPerSession),
                    subtitle: summary.averagePagesPerSession == null
                        ? 'Aun no hay suficientes sesiones'
                        : 'promedio registrado',
                  ),
                  StatCard(
                    icon: Icons.timer_outlined,
                    title: 'Minutos por sesion',
                    value: _formatAverage(summary.averageMinutesPerSession),
                    subtitle: summary.averageMinutesPerSession == null
                        ? 'Aun no hay suficientes sesiones'
                        : 'promedio registrado',
                  ),
                  StatCard(
                    icon: Icons.today_outlined,
                    title: 'Paginas por dia',
                    value: _formatAverage(summary.averagePagesPerActiveDay),
                    subtitle: summary.averagePagesPerActiveDay == null
                        ? 'Aun no hay suficientes sesiones'
                        : 'dias con lectura',
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _InsightsSection(
                title: 'Finish Prediction',
                children: [
                  StatCard(
                    icon: Icons.flag_outlined,
                    title: 'Libro actual',
                    value: summary.finishPredictionBookTitle ?? 'Sin datos',
                    subtitle: summary.hasFinishPrediction
                        ? '${summary.finishPredictionRemainingPages} pag. restantes'
                        : 'No hay un libro en lectura con datos suficientes',
                  ),
                  StatCard(
                    icon: Icons.trending_up_outlined,
                    title: 'Ritmo reciente',
                    value: _formatAverage(
                      summary.finishPredictionRecentPagesPerDay,
                    ),
                    subtitle: summary.finishPredictionRecentPagesPerDay == null
                        ? 'Aun no hay suficientes sesiones'
                        : 'pag. por dia activo',
                  ),
                  StatCard(
                    icon: Icons.event_available_outlined,
                    title: 'Fecha estimada',
                    value: summary.finishPredictionDate == null
                        ? 'Sin datos'
                        : _formatDate(summary.finishPredictionDate!),
                    subtitle: summary.finishPredictionDaysRemaining == null
                        ? 'Aun no hay datos suficientes'
                        : 'Terminaras este libro aproximadamente en ${summary.finishPredictionDaysRemaining} dias',
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _InsightsSection(
                title: 'Annual Forecast',
                children: [
                  StatCard(
                    icon: Icons.check_circle_outline,
                    title: 'Leidos este ano',
                    value: '${summary.completedBooksThisYear}',
                    subtitle: 'libros completados',
                  ),
                  StatCard(
                    icon: Icons.calendar_month_outlined,
                    title: 'Proyeccion anual',
                    value: summary.annualBooksForecast == null
                        ? 'Sin datos'
                        : '${summary.annualBooksForecast}',
                    subtitle: summary.annualBooksForecast == null
                        ? 'Aun no hay suficientes datos'
                        : 'libros para final de ano',
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _InsightsSection(
                title: 'Top Lecturas del Año',
                children: [
                  StatCard(
                    icon: Icons.star_border,
                    title: 'Mejor valorado',
                    value: summary.topRatedBookTitle ?? 'Sin datos',
                    subtitle: summary.topRatedBookRating == null
                        ? 'Aun no hay libros valorados este ano'
                        : '${_formatRating(summary.topRatedBookRating!)} / 5',
                  ),
                  StatCard(
                    icon: Icons.menu_book_outlined,
                    title: 'Mas largo',
                    value: summary.longestBookTitle ?? 'Sin datos',
                    subtitle: summary.longestBookPages == null
                        ? 'Aun no hay libros completados con paginas'
                        : '${summary.longestBookPages} pag.',
                  ),
                  StatCard(
                    icon: Icons.hourglass_bottom_outlined,
                    title: 'Mas tiempo invertido',
                    value: summary.mostTimeBookTitle ?? 'Sin datos',
                    subtitle: summary.mostTimeBookMinutes == null
                        ? 'Aun no hay sesiones este ano'
                        : _formatMinutes(summary.mostTimeBookMinutes!),
                  ),
                  StatCard(
                    icon: Icons.format_list_numbered,
                    title: 'Mas sesiones',
                    value: summary.mostSessionsBookTitle ?? 'Sin datos',
                    subtitle: summary.mostSessionsCount == null
                        ? 'Aun no hay sesiones este ano'
                        : _formatCount(summary.mostSessionsCount!, 'sesion'),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _InsightsSection(
                title: 'Ranking Personal',
                children: [
                  _RankingCard(
                    icon: Icons.person_outline,
                    title: 'Top autores',
                    items: summary.topAuthors,
                  ),
                  _RankingCard(
                    icon: Icons.category_outlined,
                    title: 'Top generos',
                    items: summary.topGenres,
                  ),
                  _RankingCard(
                    icon: Icons.local_library_outlined,
                    title: 'Top libros',
                    items: summary.topBooks,
                  ),
                  StatCard(
                    icon: Icons.emoji_events_outlined,
                    title: 'Mejor racha',
                    value: summary.bestStreakDays > 0
                        ? '${summary.bestStreakDays}'
                        : 'Sin datos',
                    subtitle: summary.bestStreakDays > 0
                        ? _formatCount(summary.bestStreakDays, 'dia')
                        : 'Aun no hay suficientes sesiones',
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  String _formatPages(int pages) {
    if (pages <= 0) return 'Aun no hay datos suficientes';
    return '$pages pag. leidas';
  }

  String _formatAverage(double? value) {
    if (value == null || value <= 0) return 'Sin datos';
    return value.toStringAsFixed(value % 1 == 0 ? 0 : 1);
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatRating(double rating) {
    return rating.toStringAsFixed(rating % 1 == 0 ? 1 : 2);
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
}

class _InsightsSection extends StatelessWidget {
  const _InsightsSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        _InsightsCardGrid(children: children),
      ],
    );
  }
}

class _RankingCard extends StatelessWidget {
  const _RankingCard({
    required this.icon,
    required this.title,
    required this.items,
  });

  final IconData icon;
  final String title;
  final List<ReadingInsightRankingItem> items;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.primary;

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(minWidth: 150, maxWidth: 260),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 12),
            Text(title, style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            if (items.isEmpty)
              Text(
                'Aun no hay datos suficientes',
                style: theme.textTheme.bodySmall,
              )
            else
              for (var index = 0; index < items.length; index++) ...[
                _RankingRow(position: index + 1, item: items[index]),
                if (index < items.length - 1) const SizedBox(height: 6),
              ],
          ],
        ),
      ),
    );
  }
}

class _RankingRow extends StatelessWidget {
  const _RankingRow({required this.position, required this.item});

  final int position;
  final ReadingInsightRankingItem item;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text('$position. ', style: Theme.of(context).textTheme.bodySmall),
        Expanded(
          child: Text(
            item.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '${item.value} pag.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _InsightsCardGrid extends StatelessWidget {
  const _InsightsCardGrid({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double cardWidth;
        if (constraints.maxWidth >= 640) {
          cardWidth = (constraints.maxWidth - 24) / 3;
        } else if (constraints.maxWidth >= 360) {
          cardWidth = (constraints.maxWidth - 12) / 2;
        } else {
          cardWidth = constraints.maxWidth;
        }

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final child in children)
              SizedBox(width: cardWidth, child: child),
          ],
        );
      },
    );
  }
}

class _InsightsEmptyState extends StatelessWidget {
  const _InsightsEmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.insights_outlined,
              size: 48,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'Aun no hay datos suficientes',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            const Text(
              'Registra sesiones de lectura para ver insights.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _InsightsErrorState extends StatelessWidget {
  const _InsightsErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'No pudimos cargar tus insights',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            const Text(
              'Intentalo de nuevo en unos segundos.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}
