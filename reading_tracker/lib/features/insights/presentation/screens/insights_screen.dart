import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../stats/presentation/widgets/stat_card.dart';
import '../../domain/entities/reading_insights_summary.dart';
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
                title: 'Tu perfil lector',
                children: [
                  StatCard(
                    icon: Icons.person_outline,
                    title: 'Autor favorito',
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
                  StatCard(
                    icon: Icons.hourglass_bottom_outlined,
                    title: 'Libro al que mas tiempo dedicaste',
                    value: summary.mostTimeBookTitle ?? 'Sin datos',
                    subtitle: summary.mostTimeBookMinutes == null
                        ? 'Aun no hay sesiones este ano'
                        : _formatMinutes(summary.mostTimeBookMinutes!),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _InsightsSection(
                title: 'Tus mejores lecturas',
                children: [
                  _RatedBooksCard(
                    icon: Icons.star_border,
                    title: 'Top 3 lecturas del ano',
                    books: summary.topRatedBooks,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _InsightsSection(
                title: 'Curiosidades',
                children: [
                  StatCard(
                    icon: Icons.menu_book_outlined,
                    title: 'Libro mas largo',
                    value: summary.longestBookTitle ?? 'Sin datos',
                    subtitle: summary.longestBookPages == null
                        ? 'Aun no hay libros completados con paginas'
                        : '${summary.longestBookPages} pag.',
                  ),
                  StatCard(
                    icon: Icons.calendar_month_outlined,
                    title: 'Mes con mas lectura',
                    value: summary.mostActiveMonth == null
                        ? 'Sin datos'
                        : _formatMonth(summary.mostActiveMonth!),
                    subtitle: _formatActivity(
                      pages: summary.mostActiveMonthPages,
                      minutes: summary.mostActiveMonthMinutes,
                    ),
                  ),
                  StatCard(
                    icon: Icons.schedule_outlined,
                    title: 'Franja habitual',
                    value: summary.usualReadingTimeSlot ?? 'Sin datos',
                    subtitle: summary.usualReadingTimeSlot == null
                        ? 'Aun no hay sesiones registradas'
                        : _formatCount(
                            summary.usualReadingTimeSlotSessions,
                            'sesion',
                          ),
                  ),
                  StatCard(
                    icon: Icons.today_outlined,
                    title: 'Dia mas activo',
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
    );
  }

  String _formatPages(int pages) {
    if (pages <= 0) return 'Aun no hay datos suficientes';
    return '$pages pag. leidas';
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
    if (pages <= 0 && minutes <= 0) return 'Aun no hay datos suficientes';
    if (pages > 0 && minutes > 0) {
      return '$pages pag. | ${_formatMinutes(minutes)}';
    }
    if (pages > 0) return '$pages pag. leidas';
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

class _RatedBooksCard extends StatelessWidget {
  const _RatedBooksCard({
    required this.icon,
    required this.title,
    required this.books,
  });

  final IconData icon;
  final String title;
  final List<ReadingInsightRatedBook> books;

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
            if (books.isEmpty)
              Text(
                'Aun no hay libros valorados este ano',
                style: theme.textTheme.bodySmall,
              )
            else
              for (var index = 0; index < books.length; index++) ...[
                _RatedBookRow(position: index + 1, book: books[index]),
                if (index < books.length - 1) const SizedBox(height: 6),
              ],
          ],
        ),
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
    return Row(
      children: [
        Text('$position. ', style: Theme.of(context).textTheme.bodySmall),
        Expanded(
          child: Text(
            book.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '${book.rating.toStringAsFixed(book.rating % 1 == 0 ? 1 : 2)} / 5',
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
