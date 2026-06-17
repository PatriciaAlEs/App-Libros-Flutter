import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/branding/branding.dart';
import '../../../../core/design_system/design_system.dart';
import '../../../../core/preferences/reader_profile_controller.dart';
import '../../../books/data/datasources/book_api_datasource.dart';
import '../../../books/domain/entities/book_search_result.dart';
import '../../domain/entities/statistics_summary.dart';
import '../providers/annual_goal_cover_controller.dart';
import '../providers/statistics_summary_provider.dart';

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final readerProfile = ref.watch(readerProfileControllerProvider);
    final summaryAsync = ref.watch(statisticsSummaryProvider);
    final annualGoalCover = ref.watch(annualGoalCoverControllerProvider);

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
              stops: const [0, 0.42, 1],
            ),
          ),
          child: summaryAsync.when(
            loading: () => const _StatsLoadingState(),
            error: (error, _) => _StatsErrorState(
              onRetry: () => ref.invalidate(statisticsSummaryProvider),
            ),
            data: (summary) {
              return ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.md,
                  AppSpacing.lg,
                  128,
                ),
                children: [
                  _StatsHeader(readerProfile: readerProfile),
                  const SizedBox(height: AppSpacing.xxl),
                  SectionHeader(
                    title: 'Objetivo anual',
                    actionLabel: 'Editar',
                    onAction: () => _editAnnualGoal(
                      context,
                      ref,
                      currentGoal: summary.annualReadingGoal,
                    ),
                  ),
                  _AnnualGoalSection(
                    annualReadingGoal: summary.annualReadingGoal,
                    completedThisYear: summary.completedThisYear,
                    annualGoalProgress: summary.annualGoalProgress,
                    booksRemainingForAnnualGoal:
                        summary.booksRemainingForAnnualGoal,
                    isAnnualGoalReached: summary.isAnnualGoalReached,
                    cover: annualGoalCover,
                    onEditGoal: () => _editAnnualGoal(
                      context,
                      ref,
                      currentGoal: summary.annualReadingGoal,
                    ),
                    onSearchCover: () => _searchAnnualGoalCover(context, ref),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  _StatsHero(summary: summary),
                  const SizedBox(height: AppSpacing.xl),
                  _StatsSection(
                    title: 'Lectura',
                    children: [
                      MetricCard(
                        icon: AppIcons.library,
                        label: 'Biblioteca',
                        value: '${summary.totalBooks}',
                        subtitle: 'libros guardados',
                      ),
                      MetricCard(
                        icon: AppIcons.bookmark,
                        label: 'Pendientes',
                        value: '${summary.toReadBooks}',
                      ),
                      MetricCard(
                        icon: AppIcons.book,
                        label: 'Leyendo',
                        value: '${summary.readingBooks}',
                      ),
                      MetricCard(
                        icon: Icons.check_circle_outline,
                        label: 'Completados',
                        value: '${summary.completedBooks}',
                      ),
                      MetricCard(
                        icon: Icons.pause_circle_outline,
                        label: 'Pausados',
                        value: '${summary.pausedBooks}',
                      ),
                      MetricCard(
                        icon: Icons.block_outlined,
                        label: 'Abandonados',
                        value: '${summary.abandonedBooks}',
                      ),
                      MetricCard(
                        icon: AppIcons.fire,
                        label: 'Racha actual',
                        value: '${summary.currentStreakDays}',
                        subtitle: 'días seguidos',
                      ),
                      MetricCard(
                        icon: AppIcons.star,
                        label: 'Valoración media',
                        value: _formatAverageRating(summary.averageRating),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  _StatsSection(
                    title: 'Tiempo',
                    children: [
                      MetricCard(
                        icon: AppIcons.pages,
                        label: 'Páginas esta semana',
                        value: '${summary.pagesReadThisWeek}',
                      ),
                      MetricCard(
                        icon: AppIcons.calendar,
                        label: 'Páginas este mes',
                        value: '${summary.pagesReadThisMonth}',
                      ),
                      MetricCard(
                        icon: AppIcons.time,
                        label: 'Tiempo esta semana',
                        value: _formatMinutes(summary.minutesReadThisWeek),
                      ),
                      MetricCard(
                        icon: Icons.hourglass_bottom_outlined,
                        label: 'Tiempo este mes',
                        value: _formatMinutes(summary.minutesReadThisMonth),
                      ),
                      MetricCard(
                        icon: Icons.trending_up_outlined,
                        label: 'Promedio por día activo',
                        value:
                            '${_formatAverage(summary.averagePagesPerActiveDay)} pag.',
                        subtitle:
                            '${_formatAverage(summary.averageMinutesPerActiveDay)} min',
                      ),
                      MetricCard(
                        icon: Icons.event_available_outlined,
                        label: 'Días activos este mes',
                        value: '${summary.activeDaysThisMonth}',
                      ),
                      MetricCard(
                        icon: Icons.bolt_outlined,
                        label: 'Día más activo',
                        value: _formatMostActiveDay(summary.mostActiveDayDate),
                        subtitle: _formatMostActiveDayActivity(
                          summary.mostActiveDayPages,
                          summary.mostActiveDayMinutes,
                        ),
                      ),
                      MetricCard(
                        icon: Icons.emoji_events_outlined,
                        label: 'Mejor racha',
                        value: '${summary.bestStreakDays}',
                        subtitle: 'mejor marca',
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

  String _formatAverageRating(double? rating) {
    if (rating == null) return '-';
    return rating.toStringAsFixed(rating % 1 == 0 ? 1 : 2);
  }

  String _formatAverage(double value) {
    return value.toStringAsFixed(value % 1 == 0 ? 0 : 1);
  }

  String _formatMinutes(int minutes) {
    if (minutes < 60) return '$minutes min';
    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;
    if (remainingMinutes == 0) return '${hours}h';
    return '${hours}h ${remainingMinutes}min';
  }

  String _formatMostActiveDay(DateTime? date) {
    if (date == null) return '-';
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatMostActiveDayActivity(int pagesRead, int minutes) {
    final parts = <String>[
      if (pagesRead > 0) '$pagesRead pag.',
      if (minutes > 0) '$minutes min',
    ];
    return parts.isEmpty ? 'Sin sesiones' : parts.join(' · ');
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

  Future<void> _searchAnnualGoalCover(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final selectedBook = await showDialog<BookSearchResult>(
      context: context,
      builder: (_) => const _AnnualGoalCoverSearchDialog(),
    );
    if (selectedBook == null) return;

    await ref
        .read(annualGoalCoverControllerProvider.notifier)
        .selectBook(selectedBook);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Portada del reto actualizada')),
    );
  }
}

class _StatsHeader extends StatelessWidget {
  const _StatsHeader({required this.readerProfile});

  final ReaderProfile readerProfile;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppBrandHeader(
          readerProfile: readerProfile,
          onTap: () =>
              Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false),
          onProfileTap: () => Navigator.pushNamed(context, '/settings'),
          onAddBookTap: () => Navigator.pushNamed(context, '/book/add'),
          onCalendarTap: () => Navigator.pushNamed(context, '/calendar'),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'Una lectura clara de tu biblioteca, tus ritmos y tu reto anual.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.primary.withValues(alpha: 0.72),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _StatsHero extends StatelessWidget {
  const _StatsHero({required this.summary});

  final StatisticsSummary summary;

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
            'PULSO LECTOR',
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
                  value: '${summary.completedThisYear}',
                  label: 'libros $year',
                ),
              ),
              Expanded(
                child: _HeroMetric(
                  value: '${summary.currentStreakDays}',
                  label: 'racha',
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
                Icon(AppIcons.chart, color: accent, size: 22),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    '${summary.completedBooks} completados · ${summary.readingBooks} en curso · ${summary.toReadBooks} pendientes',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onPrimary,
                      fontWeight: FontWeight.w800,
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

class _AnnualGoalSection extends StatelessWidget {
  const _AnnualGoalSection({
    required this.annualReadingGoal,
    required this.completedThisYear,
    required this.annualGoalProgress,
    required this.booksRemainingForAnnualGoal,
    required this.isAnnualGoalReached,
    required this.cover,
    required this.onEditGoal,
    required this.onSearchCover,
  });

  final int? annualReadingGoal;
  final int completedThisYear;
  final double? annualGoalProgress;
  final int? booksRemainingForAnnualGoal;
  final bool isAnnualGoalReached;
  final AnnualGoalCover? cover;
  final VoidCallback onEditGoal;
  final VoidCallback onSearchCover;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasGoal = annualReadingGoal != null;
    final rawProgress = annualGoalProgress ?? 0;
    final progress = (rawProgress / 100).clamp(0.0, 1.0).toDouble();
    final percent = rawProgress.clamp(0, 100).round();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.90),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.16),
        ),
        boxShadow: AppShadows.editorial(theme.colorScheme.primary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _AnnualGoalCoverFrame(cover: cover),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hasGoal
                          ? '$completedThisYear / $annualReadingGoal libros'
                          : 'Define tu reto lector',
                      style: GoogleFonts.cormorantGaramond(
                        textStyle: theme.textTheme.headlineSmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontSize: 31,
                          fontWeight: FontWeight.w700,
                          height: 1.04,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      cover?.title ?? 'Elige una portada para tu reto',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (cover?.author?.isNotEmpty == true) ...[
                      const SizedBox(height: 2),
                      Text(
                        cover!.author!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              OutlinedButton.icon(
                onPressed: onEditGoal,
                icon: Icon(hasGoal ? AppIcons.edit : AppIcons.add, size: 18),
                label: Text(hasGoal ? 'Editar objetivo' : 'Definir objetivo'),
              ),
              OutlinedButton.icon(
                onPressed: onSearchCover,
                icon: const Icon(Icons.search_rounded, size: 18),
                label: Text(
                  cover == null ? 'Buscar portada' : 'Cambiar portada',
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: hasGoal ? progress : 0,
              minHeight: 8,
              backgroundColor: theme.colorScheme.primaryContainer.withValues(
                alpha: 0.26,
              ),
              color: theme.colorScheme.secondary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.md,
            children: [
              _GoalMetric(label: 'Avance', value: hasGoal ? '$percent%' : '-'),
              _GoalMetric(label: 'Completados', value: '$completedThisYear'),
              _GoalMetric(
                label: hasGoal
                    ? isAnnualGoalReached
                          ? 'Meta'
                          : 'Restan'
                    : 'Objetivo',
                value: hasGoal
                    ? isAnnualGoalReached
                          ? 'Alcanzada'
                          : '${booksRemainingForAnnualGoal ?? 0}'
                    : 'Sin definir',
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            _subtitle,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  String get _subtitle {
    if (annualReadingGoal == null) {
      return 'Elige cuántos libros quieres leer este año.';
    }
    if (isAnnualGoalReached) {
      return 'Objetivo alcanzado. Buen ritmo.';
    }
    return 'Vas por $completedThisYear de $annualReadingGoal libros.';
  }
}

class _AnnualGoalCoverFrame extends StatelessWidget {
  const _AnnualGoalCoverFrame({required this.cover});

  final AnnualGoalCover? cover;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final coverUrl = cover?.coverUrl;

    return Container(
      width: 72,
      height: 104,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.12),
        ),
        boxShadow: AppShadows.editorial(theme.colorScheme.primary),
      ),
      clipBehavior: Clip.antiAlias,
      child: coverUrl == null || coverUrl.isEmpty
          ? Icon(
              AppIcons.book,
              color: theme.colorScheme.primary.withValues(alpha: 0.62),
              size: 28,
            )
          : Image.network(
              coverUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Icon(
                AppIcons.book,
                color: theme.colorScheme.primary.withValues(alpha: 0.62),
                size: 28,
              ),
            ),
    );
  }
}

class _GoalMetric extends StatelessWidget {
  const _GoalMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: 132,
      height: 92,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.14),
        ),
        boxShadow: AppShadows.editorial(theme.colorScheme.primary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              maxLines: 1,
              style: GoogleFonts.cormorantGaramond(
                textStyle: theme.textTheme.titleLarge?.copyWith(
                  color: theme.colorScheme.primary,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  height: 0.95,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _compactNumber(int value) {
  if (value < 1000) return '$value';
  final compact = value / 1000;
  final decimals = compact >= 10 || compact % 1 == 0 ? 0 : 1;
  return '${compact.toStringAsFixed(decimals)}k';
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
      setState(() => _error = 'Introduce un número mayor que 0.');
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
          labelText: 'Libros para este año',
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

class _AnnualGoalCoverSearchDialog extends ConsumerStatefulWidget {
  const _AnnualGoalCoverSearchDialog();

  @override
  ConsumerState<_AnnualGoalCoverSearchDialog> createState() =>
      _AnnualGoalCoverSearchDialogState();
}

class _AnnualGoalCoverSearchDialogState
    extends ConsumerState<_AnnualGoalCoverSearchDialog> {
  final _controller = TextEditingController();
  Future<List<BookSearchResult>>? _searchFuture;
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _search() {
    final query = _controller.text.trim();
    if (query.isEmpty) return;
    setState(() {
      _query = query;
      _searchFuture = ref.read(bookApiDatasourceProvider).searchBooks(query);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Buscar portada'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              key: const Key('annual_goal_cover_search_field'),
              controller: _controller,
              autofocus: true,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                labelText: 'Título, autor o ISBN',
                suffixIcon: IconButton(
                  tooltip: 'Buscar',
                  icon: const Icon(Icons.search_rounded),
                  onPressed: _search,
                ),
                border: const OutlineInputBorder(),
              ),
              onSubmitted: (_) => _search(),
            ),
            const SizedBox(height: AppSpacing.md),
            _SearchResults(future: _searchFuture, query: _query),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
      ],
    );
  }
}

class _SearchResults extends StatelessWidget {
  const _SearchResults({required this.future, required this.query});

  final Future<List<BookSearchResult>>? future;
  final String query;

  @override
  Widget build(BuildContext context) {
    if (future == null) {
      return const _CoverSearchEmptyState();
    }

    return FutureBuilder<List<BookSearchResult>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const SizedBox(
            height: 160,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return _CoverSearchMessage(
            icon: Icons.wifi_off_rounded,
            title: 'No pudimos buscar',
            message: 'Revisa la conexión e inténtalo otra vez.',
          );
        }

        final results = snapshot.data ?? const [];
        if (results.isEmpty) {
          return _CoverSearchMessage(
            icon: Icons.search_off_rounded,
            title: 'Sin resultados',
            message: 'No encontramos coincidencias para "$query".',
          );
        }

        return ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 360),
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: results.length,
            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, index) {
              final book = results[index];
              return _CoverSearchResultTile(book: book);
            },
          ),
        );
      },
    );
  }
}

class _CoverSearchEmptyState extends StatelessWidget {
  const _CoverSearchEmptyState();

  @override
  Widget build(BuildContext context) {
    return const _CoverSearchMessage(
      icon: Icons.search_rounded,
      title: 'Busca una portada',
      message: 'Puedes usar título, autora o ISBN.',
    );
  }
}

class _CoverSearchMessage extends StatelessWidget {
  const _CoverSearchMessage({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      height: 160,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: theme.colorScheme.primary),
            const SizedBox(height: AppSpacing.sm),
            Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _CoverSearchResultTile extends StatelessWidget {
  const _CoverSearchResultTile({required this.book});

  final BookSearchResult book;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.surface.withValues(alpha: 0.92),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => Navigator.pop(context, book),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Row(
            children: [
              _SearchCoverThumb(url: book.coverUrl),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      book.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _resultSubtitle(book),
                      maxLines: 1,
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
        ),
      ),
    );
  }

  String _resultSubtitle(BookSearchResult book) {
    final parts = <String>[
      if (book.author?.isNotEmpty == true) book.author!,
      if (book.firstPublishYear != null) '${book.firstPublishYear}',
      if (book.coverUrl == null) 'Sin portada',
    ];
    return parts.isEmpty ? 'Resultado de Open Library' : parts.join(' · ');
  }
}

class _SearchCoverThumb extends StatelessWidget {
  const _SearchCoverThumb({required this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final placeholder = Container(
      width: 42,
      height: 60,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        AppIcons.book,
        color: theme.colorScheme.primary.withValues(alpha: 0.62),
        size: 18,
      ),
    );

    if (url == null || url!.isEmpty) return placeholder;

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(
        url!,
        width: 42,
        height: 60,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => placeholder,
      ),
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
        SectionHeader(title: title),
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
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          children: [
            for (final child in children)
              SizedBox(width: cardWidth, height: 150, child: child),
          ],
        );
      },
    );
  }
}

// ignore: unused_element
class _StatsEmptyState extends StatelessWidget {
  const _StatsEmptyState();

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
            color: theme.colorScheme.surface.withValues(alpha: 0.90),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: theme.colorScheme.primary.withValues(alpha: 0.16),
            ),
            boxShadow: AppShadows.editorial(theme.colorScheme.primary),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _StateIcon(icon: AppIcons.chart),
              const SizedBox(height: 16),
              Text(
                'Tus estadísticas están por estrenarse',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Añade tu primer libro y registra lectura para ver ritmo, rachas y progreso.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: () => Navigator.pushNamed(context, '/book/add'),
                icon: const Icon(AppIcons.add),
                label: const Text('Añadir primer libro'),
              ),
            ],
          ),
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
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(26, 28, 26, 26),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface.withValues(alpha: 0.90),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: theme.colorScheme.error.withValues(alpha: 0.12),
            ),
            boxShadow: AppShadows.editorial(theme.colorScheme.primary),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _StateIcon(icon: Icons.error_outline, isError: true),
              const SizedBox(height: 16),
              Text(
                'No pudimos preparar tus estadísticas',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Revisa la conexión de datos local e inténtalo otra vez.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium,
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
      ),
    );
  }
}

class _StatsLoadingState extends StatelessWidget {
  const _StatsLoadingState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        for (var index = 0; index < 5; index++) ...[
          Container(
            height: index == 0 ? 132 : 92,
            decoration: BoxDecoration(
              color: theme.colorScheme.surface.withValues(alpha: 0.86),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: theme.colorScheme.primary.withValues(alpha: 0.12),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ],
    );
  }
}

class _StateIcon extends StatelessWidget {
  const _StateIcon({required this.icon, this.isError = false});

  final IconData icon;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = isError ? theme.colorScheme.error : theme.colorScheme.primary;

    return Container(
      width: 72,
      height: 72,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.12),
      ),
      child: Icon(icon, size: 34, color: color),
    );
  }
}
