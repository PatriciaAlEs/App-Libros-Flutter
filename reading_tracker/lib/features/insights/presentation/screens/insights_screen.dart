import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
          if (!summary.hasReadingActivity) {
            return const _InsightsEmptyState();
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Reading Insights',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              _InsightsCardGrid(
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
