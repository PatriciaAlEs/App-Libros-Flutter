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
              _AnnualGoalSection(
                annualReadingGoal: summary.annualReadingGoal,
                completedThisYear: summary.completedThisYear,
                annualGoalProgress: summary.annualGoalProgress,
                booksRemainingForAnnualGoal:
                    summary.booksRemainingForAnnualGoal,
                isAnnualGoalReached: summary.isAnnualGoalReached,
                onEditGoal: () => _editAnnualGoal(
                  context,
                  ref,
                  currentGoal: summary.annualReadingGoal,
                ),
              ),
              const SizedBox(height: 24),
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

  Future<void> _editAnnualGoal(
    BuildContext context,
    WidgetRef ref, {
    required int? currentGoal,
  }) async {
    final goal = await showDialog<int>(
      context: context,
      builder: (_) => _AnnualGoalDialog(initialGoal: currentGoal),
    );
    if (goal == null) return;

    await ref.read(saveAnnualReadingGoalProvider)(goal);
    ref.invalidate(statisticsSummaryProvider);
  }
}

class _AnnualGoalSection extends StatelessWidget {
  const _AnnualGoalSection({
    required this.annualReadingGoal,
    required this.completedThisYear,
    required this.annualGoalProgress,
    required this.booksRemainingForAnnualGoal,
    required this.isAnnualGoalReached,
    required this.onEditGoal,
  });

  final int? annualReadingGoal;
  final int completedThisYear;
  final double? annualGoalProgress;
  final int? booksRemainingForAnnualGoal;
  final bool isAnnualGoalReached;
  final VoidCallback onEditGoal;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasGoal = annualReadingGoal != null;
    final progress = annualGoalProgress ?? 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.flag_outlined, color: theme.colorScheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Objetivo anual',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(_subtitle),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (hasGoal) ...[
              LinearProgressIndicator(value: progress / 100),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _GoalMetric(
                    label: 'Objetivo',
                    value: '$annualReadingGoal libros',
                  ),
                  _GoalMetric(
                    label: 'Completados este ano',
                    value: '$completedThisYear',
                  ),
                  _GoalMetric(
                    label: 'Avance',
                    value: '${progress.toStringAsFixed(0)}%',
                  ),
                  _GoalMetric(
                    label: isAnnualGoalReached ? 'Meta alcanzada' : 'Restan',
                    value: isAnnualGoalReached
                        ? 'Si'
                        : '${booksRemainingForAnnualGoal ?? 0}',
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
            Align(
              alignment: Alignment.centerLeft,
              child: FilledButton.icon(
                onPressed: onEditGoal,
                icon: Icon(hasGoal ? Icons.edit_outlined : Icons.add),
                label: Text(hasGoal ? 'Editar objetivo' : 'Definir objetivo'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String get _subtitle {
    if (annualReadingGoal == null) {
      return 'Define cuantos libros quieres leer este ano.';
    }
    if (isAnnualGoalReached) {
      return 'Objetivo alcanzado. Buen ritmo.';
    }
    return 'Vas por $completedThisYear de $annualReadingGoal libros.';
  }
}

class _GoalMetric extends StatelessWidget {
  const _GoalMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 136,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _AnnualGoalDialog extends StatefulWidget {
  const _AnnualGoalDialog({required this.initialGoal});

  final int? initialGoal;

  @override
  State<_AnnualGoalDialog> createState() => _AnnualGoalDialogState();
}

class _AnnualGoalDialogState extends State<_AnnualGoalDialog> {
  late final TextEditingController _controller;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.initialGoal?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    final goal = int.tryParse(_controller.text.trim());
    if (goal == null || goal <= 0) {
      setState(() => _error = 'Introduce un numero mayor que 0.');
      return;
    }

    Navigator.pop(context, goal);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Objetivo anual'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: 'Libros para este ano',
          hintText: 'Ej. 12',
          errorText: _error,
          border: const OutlineInputBorder(),
        ),
        onSubmitted: (_) => _save(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(onPressed: _save, child: const Text('Guardar')),
      ],
    );
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
