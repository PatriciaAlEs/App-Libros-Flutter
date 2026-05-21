import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../books/domain/entities/book.dart';
import '../../../books/presentation/providers/books_provider.dart';
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

    return Scaffold(
      appBar: AppBar(
        title: Text(_formatDate(day)),
        actions: [
          IconButton(
            tooltip: 'Nueva sesión',
            icon: const Icon(Icons.add),
            onPressed: () => _openSessionForm(context, ref),
          ),
        ],
      ),
      body: sessionsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
        data: (sessions) {
          final booksById = booksAsync.maybeWhen(
            data: (books) => {for (final book in books) book.id: book},
            orElse: () => <String, Book>{},
          );
          final total = sessions.fold<int>(
            0,
            (sum, session) => sum + session.minutes,
          );

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _TotalCard(totalMinutes: total, sessionCount: sessions.length),
              const SizedBox(height: 12),
              _AddSessionButton(
                onPressed: () => _openSessionForm(context, ref),
              ),
              const SizedBox(height: 12),
              if (sessions.isEmpty)
                const _EmptyState()
              else
                for (final session in sessions)
                  _SessionTile(
                    session: session,
                    book: booksById[session.bookId],
                    onEdit: () => _openEditSessionForm(context, ref, session),
                    onDelete: () => _confirmDeleteSession(
                      context,
                      ref,
                      session,
                    ),
                  ),
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
        const SnackBar(content: Text('Sesión guardada')),
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
        const SnackBar(content: Text('Sesión actualizada')),
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
    ref.invalidate(readingSessionsForDayProvider(day));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sesión eliminada')),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

class _AddSessionButton extends StatelessWidget {
  const _AddSessionButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.add),
      label: const Text('Añadir sesión'),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Center(
        child: Text(
          'No hay sesiones este día. Añade una sesión para registrar actividad.',
          style: Theme.of(context).textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class _TotalCard extends StatelessWidget {
  const _TotalCard({required this.totalMinutes, required this.sessionCount});

  final int totalMinutes;
  final int sessionCount;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(sessionCount == 1 ? '1 sesión' : '$sessionCount sesiones'),
            Text(
              '$totalMinutes min',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ],
        ),
      ),
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
    return Card(
      child: ListTile(
        leading: _Cover(url: book?.coverUrl),
        title: Text(book?.title ?? 'Libro no encontrado'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (book?.author != null) Text(book!.author!),
            if (session.note != null && session.note!.isNotEmpty)
              Text(session.note!),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('${session.minutes} min'),
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
        onTap: book == null
            ? null
            : () {
                Navigator.pushNamed(
                  context,
                  '/book/detail',
                  arguments: book!.id,
                );
              },
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
    if (url == null) {
      return Container(
        width: 42,
        height: 56,
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: const Icon(Icons.menu_book),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: Image.network(
        url!,
        width: 42,
        height: 56,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          width: 42,
          height: 56,
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: const Icon(Icons.menu_book),
        ),
      ),
    );
  }
}
