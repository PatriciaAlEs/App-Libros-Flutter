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
        error: (error, _) => _StatsErrorState(
          onRetry: () => ref.invalidate(statisticsSummaryProvider),
        ),
        data: (summary) {
          if (summary.totalBooks == 0) {
            return const _StatsEmptyState();
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _StatsSection(
                title: 'Biblioteca',
                children: [
                  StatCard(
                    icon: Icons.library_books_outlined,
                    title: 'Libros en biblioteca',
                    value: '${summary.totalBooks}',
                  ),
                  StatCard(
                    icon: Icons.bookmark_border,
                    title: 'Pendientes',
                    value: '${summary.toReadBooks}',
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _StatsSection(
                title: 'Estado de lectura',
                children: [
                  StatCard(
                    icon: Icons.auto_stories_outlined,
                    title: 'Leyendo',
                    value: '${summary.readingBooks}',
                  ),
                  StatCard(
                    icon: Icons.local_library_outlined,
                    title: 'Lecturas activas',
                    value: '${summary.currentlyReadingCount}',
                  ),
                  StatCard(
                    icon: Icons.check_circle_outline,
                    title: 'Completados',
                    value: '${summary.completedBooks}',
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
                ],
              ),
              const SizedBox(height: 24),
              _StatsSection(
                title: 'Progreso',
                children: [
                  StatCard(
                    icon: Icons.menu_book_outlined,
                    title: 'Paginas leidas',
                    value: '${summary.totalPagesRead}',
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _StatsSection(
                title: 'Valoraciones',
                children: [
                  StatCard(
                    icon: Icons.star_border,
                    title: 'Valoracion media',
                    value: _formatAverageRating(summary.averageRating),
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

class _StatsSection extends StatelessWidget {
  const _StatsSection({required this.title, required this.children});

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
        _StatsCardGrid(children: children),
      ],
    );
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
              'Todavia no hay datos de lectura',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            const Text(
              'Anade tu primer libro para empezar a calcular tus estadisticas.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/book/add'),
              icon: const Icon(Icons.add),
              label: const Text('Anadir libro'),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatsErrorState extends StatelessWidget {
  const _StatsErrorState({required this.onRetry});

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
              'No pudimos cargar tus estadisticas',
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
