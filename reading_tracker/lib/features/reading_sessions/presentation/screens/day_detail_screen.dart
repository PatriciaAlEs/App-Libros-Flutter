import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../books/domain/entities/book.dart';
import '../../../books/presentation/providers/books_provider.dart';
import '../../../insights/presentation/providers/reading_insights_summary_provider.dart';
import '../../../stats/presentation/providers/stats_provider.dart';
import '../../data/repositories/reading_session_repository_provider.dart';
import '../../domain/entities/reading_session.dart';
import '../providers/reading_sessions_provider.dart';

class DayDetailScreen extends ConsumerWidget {
  const DayDetailScreen({super.key, required this.day});

  final DateTime day;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionsAsync = ref.watch(readingSessionsForDayProvider(day));
    final booksAsync = ref.watch(booksProvider);
    final canAddSession = !_isFutureDay(day);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Diario lector'),
        actions: [
          IconButton(
            tooltip: 'Añadir lectura',
            icon: const Icon(Icons.add_rounded),
            onPressed: canAddSession
                ? () => _openSessionForm(context, ref)
                : null,
          ),
        ],
      ),
      body: sessionsAsync.when(
        loading: () => const _DayLoadingState(),
        error: (error, _) => const _DayErrorState(),
        data: (sessions) {
          final booksById = booksAsync.maybeWhen(
            data: (books) => {for (final book in books) book.id: book},
            orElse: () => <String, Book>{},
          );
          final totalMinutes = sessions.fold<int>(
            0,
            (sum, session) => sum + session.minutes,
          );
          final totalPages = sessions.fold<int>(
            0,
            (sum, session) => sum + session.pagesRead,
          );
          final focusBook = _focusBookForDay(sessions, booksById);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _DayEditorialHeader(
                day: day,
                totalMinutes: totalMinutes,
                totalPages: totalPages,
                sessionCount: sessions.length,
                focusBook: focusBook,
              ),
              const SizedBox(height: 16),
              _AddSessionButton(
                onPressed: canAddSession
                    ? () => _openSessionForm(context, ref)
                    : null,
              ),
              const SizedBox(height: 16),
              if (sessions.isEmpty)
                const _EmptyState()
              else
                for (var index = 0; index < sessions.length; index++) ...[
                  _AnimatedSessionTile(
                    index: index,
                    child: _SessionTile(
                      session: sessions[index],
                      book: booksById[sessions[index].bookId],
                      onEdit: () =>
                          _openEditSessionForm(context, ref, sessions[index]),
                      onDelete: () =>
                          _confirmDeleteSession(context, ref, sessions[index]),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
            ],
          );
        },
      ),
    );
  }

  Future<void> _openSessionForm(BuildContext context, WidgetRef ref) async {
    final saved = await Navigator.pushNamed(
      context,
      '/session/add',
      arguments: day,
    );
    if (!context.mounted) return;
    if (saved == true) {
      ref.invalidate(readingSessionsForDayProvider(day));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tiempo de lectura guardado')),
      );
    }
  }

  Future<void> _openEditSessionForm(
    BuildContext context,
    WidgetRef ref,
    ReadingSession session,
  ) async {
    final saved = await Navigator.pushNamed(
      context,
      '/session/edit',
      arguments: session,
    );
    if (!context.mounted) return;
    if (saved == true) {
      ref.invalidate(readingSessionsForDayProvider(day));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tiempo de lectura actualizado')),
      );
    }
  }

  Future<void> _confirmDeleteSession(
    BuildContext context,
    WidgetRef ref,
    ReadingSession session,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => const _DeleteSessionDialog(),
    );
    if (confirmed != true) return;

    await ref.read(readingSessionRepositoryProvider).deleteSession(session.id);
    ref.invalidate(statsProvider);
    ref.invalidate(readingInsightsSummaryProvider);
    ref.invalidate(readingSessionsForDayProvider(day));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Tiempo de lectura eliminado')),
    );
  }

  bool _isFutureDay(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dayOnly = DateTime(date.year, date.month, date.day);
    return dayOnly.isAfter(today);
  }

  Book? _focusBookForDay(
    List<ReadingSession> sessions,
    Map<String, Book> booksById,
  ) {
    if (sessions.isEmpty) return null;
    final scoreByBook = <String, int>{};
    for (final session in sessions) {
      scoreByBook[session.bookId] =
          (scoreByBook[session.bookId] ?? 0) +
          session.pagesRead +
          session.minutes;
    }
    final best = scoreByBook.entries.fold<MapEntry<String, int>?>(null, (
      current,
      entry,
    ) {
      if (current == null) return entry;
      return entry.value > current.value ? entry : current;
    });
    if (best == null) return null;
    return booksById[best.key];
  }
}

class _DayEditorialHeader extends StatelessWidget {
  const _DayEditorialHeader({
    required this.day,
    required this.totalMinutes,
    required this.totalPages,
    required this.sessionCount,
    required this.focusBook,
  });

  final DateTime day;
  final int totalMinutes;
  final int totalPages;
  final int sessionCount;
  final Book? focusBook;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primary,
            Color.lerp(theme.colorScheme.primary, Colors.black, 0.28)!,
          ],
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: AppShadows.soft(theme.colorScheme.primary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'DIARIO DE LECTURA',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.secondary,
              letterSpacing: 2.4,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _humanDay(day),
            style: theme.textTheme.headlineSmall?.copyWith(
              color: theme.colorScheme.onPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(child: _DayMetric(value: '$totalPages', label: 'páginas')),
              Expanded(child: _DayMetric(value: '$totalMinutes', label: 'minutos')),
              Expanded(child: _DayMetric(value: '$sessionCount', label: 'sesiones')),
            ],
          ),
          if (focusBook != null) ...[
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: Row(
                children: [
                  Icon(AppIcons.book, color: theme.colorScheme.secondary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      focusBook!.title,
                      maxLines: 1,
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
        ],
      ),
    );
  }

  String _humanDay(DateTime date) {
    const months = [
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
    return '${date.day} de ${months[date.month - 1]}';
  }
}

class _DayMetric extends StatelessWidget {
  const _DayMetric({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(
            color: theme.colorScheme.onPrimary,
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onPrimary.withValues(alpha: 0.72),
          ),
        ),
      ],
    );
  }
}

class _AddSessionButton extends StatelessWidget {
  const _AddSessionButton({required this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: onPressed,
      icon: const Icon(AppIcons.add),
      label: const Text('Añadir lectura'),
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 26),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.76),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.08),
        ),
        boxShadow: AppShadows.soft(theme.colorScheme.primary),
      ),
      child: Column(
        children: [
          Icon(AppIcons.time, color: theme.colorScheme.primary, size: 34),
          const SizedBox(height: 14),
          Text(
            'Este día aún está en blanco',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Añade una sesión para guardar páginas, minutos y notas de lectura.',
            style: theme.textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _DayLoadingState extends StatelessWidget {
  const _DayLoadingState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          height: 190,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        const SizedBox(height: 16),
        for (var index = 0; index < 3; index++) ...[
          Container(
            height: 112,
            decoration: BoxDecoration(
              color: theme.colorScheme.surface.withValues(alpha: 0.64),
              borderRadius: BorderRadius.circular(24),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _DayErrorState extends StatelessWidget {
  const _DayErrorState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'No pudimos cargar las sesiones de este día. Vuelve a intentarlo en unos segundos.',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class _AnimatedSessionTile extends StatelessWidget {
  const _AnimatedSessionTile({required this.index, required this.child});

  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 220 + index.clamp(0, 5) * 35),
      curve: AppMotion.standard,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 10 * (1 - value)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

class _SessionTile extends StatelessWidget {
  const _SessionTile({
    required this.session,
    required this.book,
    required this.onEdit,
    required this.onDelete,
  });

  final ReadingSession session;
  final Book? book;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: book == null
            ? null
            : () {
                Navigator.pushNamed(
                  context,
                  '/book/detail',
                  arguments: book!.id,
                );
              },
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface.withValues(alpha: 0.82),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: theme.colorScheme.primary.withValues(alpha: 0.08),
            ),
            boxShadow: AppShadows.soft(theme.colorScheme.primary),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Cover(url: book?.coverUrl),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      book?.title ?? 'Libro no encontrado',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (book?.author != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        book!.author!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (session.pagesRead > 0)
                          _SessionChip(
                            icon: AppIcons.pages,
                            label: '${session.pagesRead} pág.',
                          ),
                        if (session.minutes > 0)
                          _SessionChip(
                            icon: AppIcons.time,
                            label: '${session.minutes} min',
                          ),
                      ],
                    ),
                    if (session.note != null && session.note!.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text(
                        session.note!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontStyle: FontStyle.italic,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Column(
                children: [
                  IconButton(
                    tooltip: 'Editar sesión',
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: onEdit,
                  ),
                  IconButton(
                    tooltip: 'Eliminar sesión',
                    icon: const Icon(Icons.delete_outline),
                    onPressed: onDelete,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SessionChip extends StatelessWidget {
  const _SessionChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondary.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: theme.colorScheme.primary),
          const SizedBox(width: 5),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _DeleteSessionDialog extends StatelessWidget {
  const _DeleteSessionDialog();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Eliminar sesión'),
      content: const Text('Esta acción no se puede deshacer.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Eliminar'),
        ),
      ],
    );
  }
}

class _Cover extends StatelessWidget {
  const _Cover({required this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      width: 48,
      height: 66,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Icon(Icons.menu_book),
    );

    if (url == null) return placeholder;

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Image.network(
        url!,
        width: 48,
        height: 66,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => placeholder,
      ),
    );
  }
}
