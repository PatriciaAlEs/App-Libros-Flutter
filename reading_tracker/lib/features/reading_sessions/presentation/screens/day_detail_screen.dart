import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../books/domain/entities/book.dart';
import '../../../books/presentation/providers/books_provider.dart';
import '../../data/repositories/reading_session_repository_provider.dart';
import '../../domain/entities/reading_session.dart';
import '../providers/reading_sessions_provider.dart';
import '../utils/reading_session_refresh.dart';

class DayDetailScreen extends ConsumerStatefulWidget {
  const DayDetailScreen({super.key, required this.day});

  final DateTime day;

  @override
  ConsumerState<DayDetailScreen> createState() => _DayDetailScreenState();
}

class _DayDetailScreenState extends ConsumerState<DayDetailScreen> {
  String? _selectedSessionId;

  @override
  Widget build(BuildContext context) {
    final selectedDay = _dateOnly(widget.day);
    final sessionsAsync = ref.watch(readingSessionsForDayProvider(selectedDay));
    final booksAsync = ref.watch(booksProvider);
    final canAddSession = !_isFutureDay(selectedDay);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Diario de lectura',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontFamily: AppTypography.displayFontFamily,
            fontFamilyFallback: AppTypography.displayFallback,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: sessionsAsync.when(
        loading: () => const _DayLoadingState(),
        error: (error, _) => const _DayErrorState(),
        data: (sessions) {
          final booksById = booksAsync.maybeWhen(
            data: (books) => {for (final book in books) book.id: book},
            orElse: () => <String, Book>{},
          );
          final selectedSession = _selectedSession(sessions);
          final selectedBook = selectedSession == null
              ? null
              : booksById[selectedSession.bookId];

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _DayEditorialHeader(
                day: selectedDay,
                session: selectedSession,
                sessionCount: sessions.length,
                book: selectedBook,
                onTap: selectedBook == null
                    ? null
                    : () => Navigator.pushNamed(
                        context,
                        '/book/detail',
                        arguments: selectedBook.id,
                      ),
              ),
              const SizedBox(height: 16),
              _AddSessionButton(
                onPressed: canAddSession
                    ? () => _openSessionForm(context)
                    : null,
              ),
              const SizedBox(height: 16),
              if (sessions.isEmpty)
                _ReadingDayEmptyState(
                  onRegister: () => _openSessionForm(context),
                )
              else
                for (var index = 0; index < sessions.length; index++) ...[
                  _AnimatedSessionTile(
                    index: index,
                    child: _SessionTile(
                      session: sessions[index],
                      book: booksById[sessions[index].bookId],
                      isSelected: sessions[index].id == selectedSession?.id,
                      onSelect: () => setState(
                        () => _selectedSessionId = sessions[index].id,
                      ),
                      onEdit: () =>
                          _openEditSessionForm(context, sessions[index]),
                      onDelete: () =>
                          _confirmDeleteSession(context, sessions[index]),
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

  ReadingSession? _selectedSession(List<ReadingSession> sessions) {
    if (sessions.isEmpty) return null;
    for (final session in sessions) {
      if (session.id == _selectedSessionId) return session;
    }
    return sessions.first;
  }

  Future<void> _openSessionForm(BuildContext context) async {
    final selectedDay = _dateOnly(widget.day);
    final saved = await Navigator.pushNamed(
      context,
      '/session/add',
      arguments: selectedDay,
    );
    if (!context.mounted) return;
    if (saved == true) {
      refreshReadingSessionUi(ref, days: [selectedDay]);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tiempo de lectura guardado')),
      );
    }
  }

  Future<void> _openEditSessionForm(
    BuildContext context,
    ReadingSession session,
  ) async {
    final selectedDay = _dateOnly(widget.day);
    final saved = await Navigator.pushNamed(
      context,
      '/session/edit',
      arguments: session,
    );
    if (!context.mounted) return;
    if (saved == true) {
      refreshReadingSessionUi(ref, days: [selectedDay, session.date]);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tiempo de lectura actualizado')),
      );
    }
  }

  Future<void> _confirmDeleteSession(
    BuildContext context,
    ReadingSession session,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => const _DeleteSessionDialog(),
    );
    if (confirmed != true) return;

    await ref.read(readingSessionRepositoryProvider).deleteSession(session.id);
    if (_selectedSessionId == session.id && mounted) {
      setState(() => _selectedSessionId = null);
    }
    refreshReadingSessionUi(ref, days: [_dateOnly(widget.day), session.date]);
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

  DateTime _dateOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }
}

class _DayEditorialHeader extends StatelessWidget {
  const _DayEditorialHeader({
    required this.day,
    required this.session,
    required this.sessionCount,
    required this.book,
    required this.onTap,
  });

  final DateTime day;
  final ReadingSession? session;
  final int sessionCount;
  final Book? book;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totalPages = session?.pagesRead ?? 0;
    final totalMinutes = session?.minutes ?? 0;
    final focusBook = book;

    final semanticTitle = focusBook?.title ?? 'Sin lectura seleccionada';

    return Semantics(
      button: onTap != null,
      label:
          '$semanticTitle, $totalPages páginas, $totalMinutes minutos, $sessionCount sesiones',
      hint: onTap == null ? null : 'Abre el detalle del libro',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
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
                _humanDay(day),
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.secondary,
                  fontFamily: AppTypography.displayFontFamily,
                  fontFamilyFallback: AppTypography.displayFallback,
                  letterSpacing: 0,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _Cover(url: focusBook?.coverUrl),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          focusBook?.title ?? 'Sin lectura seleccionada',
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color: theme.colorScheme.onPrimary,
                            fontFamily: AppTypography.displayFontFamily,
                            fontFamilyFallback: AppTypography.displayFallback,
                            fontWeight: FontWeight.w800,
                            height: 1.04,
                          ),
                        ),
                        if (focusBook?.author != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            focusBook!.author!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onPrimary.withValues(
                                alpha: 0.72,
                              ),
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: _DayMetric(value: '$totalPages', label: 'pág.'),
                  ),
                  Expanded(
                    child: _DayMetric(value: '$totalMinutes', label: 'min'),
                  ),
                  Expanded(
                    child: _DayMetric(
                      value: '$sessionCount',
                      label: 'sesiones',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
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
            fontFamily: AppTypography.displayFontFamily,
            fontFamilyFallback: AppTypography.displayFallback,
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
    );
  }
}

class _ReadingDayEmptyState extends StatelessWidget {
  const _ReadingDayEmptyState({required this.onRegister});

  final VoidCallback onRegister;

  @override
  Widget build(BuildContext context) {
    return ReadPpEmptyState(
      icon: AppIcons.time,
      title: 'Este día aún está en blanco',
      description:
          'Registra una lectura para que tus páginas, minutos y notas aparezcan en el calendario.',
      actionLabel: 'Registrar lectura',
      onAction: onRegister,
    );
  }
}

// ignore: unused_element
class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onRegister});

  final VoidCallback onRegister;

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
            style: theme.textTheme.headlineSmall?.copyWith(
              fontSize: 17,
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
    required this.isSelected,
    required this.onSelect,
    required this.onEdit,
    required this.onDelete,
  });

  final ReadingSession session;
  final Book? book;
  final bool isSelected;
  final VoidCallback onSelect;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onSelect,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface.withValues(alpha: 0.82),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: theme.colorScheme.primary.withValues(
                alpha: isSelected ? 0.42 : 0.08,
              ),
              width: isSelected ? 1.4 : 1,
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
                    key: const Key('session_edit_action'),
                    tooltip: 'Editar sesión',
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: onEdit,
                  ),
                  IconButton(
                    key: const Key('session_delete_action'),
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
