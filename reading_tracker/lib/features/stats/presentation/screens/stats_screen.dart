import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/statistics_summary_provider.dart';
import '../widgets/stat_card.dart';

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(statisticsSummaryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Estadisticas')),
      body: summaryAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => const _StatsErrorState(),
        data: (summary) {
          if (summary.totalBooks == 0) {
            return const _StatsEmptyState();
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Resumen de biblioteca',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              _StatsCardGrid(
                children: [
                  StatCard(
                    icon: Icons.library_books_outlined,
                    title: 'Libros totales',
                    value: '${summary.totalBooks}',
                  ),
                  StatCard(
                    icon: Icons.check_circle_outline,
                    title: 'Completados',
                    value: '${summary.completedBooks}',
                  ),
                  StatCard(
                    icon: Icons.auto_stories_outlined,
                    title: 'Leyendo',
                    value: '${summary.readingBooks}',
                  ),
                  StatCard(
                    icon: Icons.pause_circle_outline,
                    title: 'Pausados',
                    value: '${summary.pausedBooks}',
                  ),
                  StatCard(
                    icon: Icons.block_outlined,
                    title: 'Abandonados',
                    value: '${summary.abandonedBooks}',
                  ),
                  StatCard(
                    icon: Icons.bookmark_border,
                    title: 'Pendientes',
                    value: '${summary.toReadBooks}',
                  ),
                  StatCard(
                    icon: Icons.menu_book_outlined,
                    title: 'Paginas leidas',
                    value: '${summary.totalPagesRead}',
                  ),
                  StatCard(
                    icon: Icons.star_border,
                    title: 'Valoracion media',
                    value: _formatAverageRating(summary.averageRating),
                  ),
                  StatCard(
                    icon: Icons.local_library_outlined,
                    title: 'Lecturas actuales',
                    value: '${summary.currentlyReadingCount}',
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  String _formatAverageRating(double? rating) {
    if (rating == null) return '-';
    return rating.toStringAsFixed(rating % 1 == 0 ? 1 : 2);
  }
}

class _StatsCardGrid extends StatelessWidget {
  const _StatsCardGrid({required this.children});

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

class _StatsEmptyState extends StatelessWidget {
  const _StatsEmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'Todavia no hay libros para calcular estadisticas.',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class _StatsErrorState extends StatelessWidget {
  const _StatsErrorState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'No se pudieron cargar las estadisticas.',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
