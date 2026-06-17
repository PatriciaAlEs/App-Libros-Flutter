import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../books/domain/entities/book.dart';
import '../../../books/domain/enums/book_status.dart';
import '../../../books/presentation/providers/books_provider.dart';
import '../../data/repositories/reading_session_repository_provider.dart';
import '../../domain/entities/reading_session.dart';
import '../../domain/usecases/register_reading_session.dart';
import '../providers/register_reading_session_provider.dart';
import '../utils/reading_session_refresh.dart';
import '../utils/session_completion_flow.dart';

class SessionFormScreen extends ConsumerStatefulWidget {
  const SessionFormScreen({super.key, this.initialDate, this.session});

  final DateTime? initialDate;
  final ReadingSession? session;

  @override
  ConsumerState<SessionFormScreen> createState() => _SessionFormScreenState();
}

class _SessionFormScreenState extends ConsumerState<SessionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _pagesReadController = TextEditingController();
  final _minutesController = TextEditingController();
  final _noteController = TextEditingController();
  String? _bookId;
  late DateTime _date;
  bool _isSaving = false;
  bool get _isEditing => widget.session != null;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final initial = widget.session?.date ?? widget.initialDate ?? now;
    _date = _clampToToday(initial);
    if (widget.session case final session?) {
      _bookId = session.bookId;
      _pagesReadController.text = session.pagesRead > 0
          ? session.pagesRead.toString()
          : '';
      _minutesController.text = session.minutes.toString();
      _noteController.text = session.note ?? '';
    }
  }

  @override
  void dispose() {
    _pagesReadController.dispose();
    _minutesController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _bookId == null) return;
    if (_date.isAfter(_today())) return;

    setState(() => _isSaving = true);
    try {
      final pagesRead = int.tryParse(_pagesReadController.text.trim()) ?? 0;
      final minutes = int.tryParse(_minutesController.text.trim()) ?? 0;
      final note = _noteController.text.trim().isEmpty
          ? null
          : _noteController.text.trim();
      final existingSession = widget.session;
      final previousDate = existingSession?.date;
      final selectedBook = _selectedBookFromCache();

      if (_isEditing) {
        final repository = ref.read(readingSessionRepositoryProvider);
        final session = ReadingSession(
          id: existingSession!.id,
          bookId: _bookId!,
          date: _date,
          minutes: minutes,
          pagesRead: pagesRead,
          note: note,
          createdAt: existingSession.createdAt,
          updatedAt: DateTime.now(),
        );
        await repository.updateSession(session);
      } else {
        await ref
            .read(registerReadingSessionProvider)
            .call(
              RegisterReadingSessionInput(
                bookId: _bookId!,
                sessionDate: _date,
                pagesRead: pagesRead,
                minutes: minutes,
                note: note,
              ),
            );
      }
      refreshReadingSessionUi(ref, days: [_date, ?previousDate]);
      if (!mounted) return;
      if (!_isEditing && selectedBook != null) {
        await maybeOfferSessionCompletion(
          context: context,
          ref: ref,
          book: selectedBook,
          pagesRead: pagesRead,
        );
      }
      if (mounted) Navigator.pop(context, true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final booksAsync = ref.watch(booksProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar sesión' : 'Registrar lectura'),
        actions: [
          IconButton(
            tooltip: 'Guardar',
            icon: const Icon(Icons.check_rounded),
            onPressed: _isSaving ? null : _save,
          ),
        ],
      ),
      body: booksAsync.when(
        loading: () => const _SessionFormLoadingState(),
        error: (error, _) => const _SessionFormErrorState(),
        data: (books) {
          final selectableBooks = _selectableBooks(books);

          if (selectableBooks.isEmpty) {
            return const _NoReadingBooksMessage();
          }

          if (_bookId == null ||
              !selectableBooks.any((book) => book.id == _bookId)) {
            _bookId = selectableBooks.first.id;
          }

          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
              children: [
                const _SessionFormIntro(),
                const SizedBox(height: 18),
                _FormSection(
                  title: 'Lectura',
                  icon: AppIcons.book,
                  child: Column(
                    children: [
                      DropdownButtonFormField<String>(
                        key: const Key('session_book_dropdown'),
                        isExpanded: true,
                        initialValue: _bookId,
                        decoration: const InputDecoration(
                          labelText: 'Libro',
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          for (final book in selectableBooks)
                            DropdownMenuItem(
                              value: book.id,
                              child: Text(
                                _bookLabel(book),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                        ],
                        onChanged: (value) => setState(() => _bookId = value),
                      ),
                      const SizedBox(height: 14),
                      _DatePickerTile(date: _date, onTap: _pickDate),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _FormSection(
                  title: 'Avance',
                  icon: AppIcons.pages,
                  child: Column(
                    children: [
                      TextFormField(
                        key: const Key('session_pages_field'),
                        controller: _pagesReadController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Páginas leídas',
                          suffixText: 'pag',
                          border: OutlineInputBorder(),
                        ),
                        validator: (_) => _activityValidator(),
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        key: const Key('session_minutes_field'),
                        controller: _minutesController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Minutos leídos',
                          suffixText: 'min',
                          border: OutlineInputBorder(),
                        ),
                        validator: (_) => _activityValidator(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _FormSection(
                  title: 'Nota',
                  icon: AppIcons.edit,
                  child: TextFormField(
                    key: const Key('session_note_field'),
                    controller: _noteController,
                    minLines: 3,
                    maxLines: 5,
                    decoration: const InputDecoration(
                      labelText: 'Nota opcional',
                      hintText: 'Una frase, una idea o cómo fue la lectura.',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  key: const Key('session_save_button'),
                  onPressed: _isSaving ? null : _save,
                  child: Text(
                    _isEditing ? 'Guardar cambios' : 'Guardar sesión',
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String? _activityValidator() {
    final pagesRead = int.tryParse(_pagesReadController.text.trim()) ?? 0;
    final minutes = int.tryParse(_minutesController.text.trim()) ?? 0;
    if (pagesRead < 0 || minutes < 0) {
      return 'Usa valores positivos';
    }
    if (pagesRead == 0 && minutes == 0) {
      return 'Indica páginas o minutos';
    }
    return null;
  }

  Future<void> _pickDate() async {
    final today = _today();
    final selected = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: today,
    );
    if (selected == null) return;
    setState(
      () => _date = DateTime(selected.year, selected.month, selected.day),
    );
  }

  DateTime _clampToToday(DateTime date) {
    final day = DateTime(date.year, date.month, date.day);
    final today = _today();
    return day.isAfter(today) ? today : day;
  }

  DateTime _today() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  String _bookLabel(Book book) {
    if (book.author == null || book.author!.isEmpty) return book.title;
    return '${book.title} - ${book.author}';
  }

  Book? _selectedBookFromCache() {
    final books = ref.read(booksProvider).valueOrNull;
    if (books == null) return null;
    for (final book in books) {
      if (book.id == _bookId) return book;
    }
    return null;
  }

  List<Book> _selectableBooks(List<Book> books) {
    final readingBooks = books
        .where((book) => book.status == BookStatus.reading)
        .toList();
    Book? currentBook;
    for (final book in books) {
      if (book.id == _bookId) {
        currentBook = book;
        break;
      }
    }
    if (currentBook == null) {
      return readingBooks;
    }
    final selectedBook = currentBook;
    if (readingBooks.any((book) => book.id == selectedBook.id)) {
      return readingBooks;
    }
    return [selectedBook, ...readingBooks];
  }
}

class _SessionFormIntro extends StatelessWidget {
  const _SessionFormIntro();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primary.withValues(alpha: 0.82),
          ],
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: AppShadows.soft(theme.colorScheme.primary),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
            ),
            child: const Icon(AppIcons.time, color: Colors.white),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Diario de lectura',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Guarda páginas, minutos y una nota breve de la sesión.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.78),
                    height: 1.35,
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

class _FormSection extends StatelessWidget {
  const _FormSection({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.08),
        ),
        boxShadow: AppShadows.editorial(theme.colorScheme.primary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondary.withValues(alpha: 0.24),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 18, color: theme.colorScheme.primary),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontFamily: AppTypography.displayFontFamily,
                  fontFamilyFallback: AppTypography.displayFallback,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _DatePickerTile extends StatelessWidget {
  const _DatePickerTile({required this.date, required this.onTap});

  final DateTime date;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.46),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Icon(AppIcons.calendar, color: theme.colorScheme.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Fecha',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${date.day}/${date.month}/${date.year}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.46),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NoReadingBooksMessage extends StatelessWidget {
  const _NoReadingBooksMessage();

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
            color: theme.colorScheme.surface.withValues(alpha: 0.76),
            borderRadius: BorderRadius.circular(26),
            border: Border.all(
              color: theme.colorScheme.primary.withValues(alpha: 0.08),
            ),
            boxShadow: AppShadows.soft(theme.colorScheme.primary),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 70,
                height: 70,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.colorScheme.secondary.withValues(alpha: 0.24),
                ),
                child: Icon(AppIcons.book, color: theme.colorScheme.primary),
              ),
              const SizedBox(height: 16),
              Text(
                'No hay lecturas activas',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Marca un libro como "Leyendo" para registrar páginas, minutos y notas.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: () => Navigator.pushNamed(context, '/books'),
                icon: const Icon(AppIcons.library),
                label: const Text('Ir a Biblioteca'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SessionFormLoadingState extends StatelessWidget {
  const _SessionFormLoadingState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        for (var index = 0; index < 5; index++) ...[
          Container(
            height: index == 0 ? 58 : 68,
            decoration: BoxDecoration(
              color: theme.colorScheme.surface.withValues(alpha: 0.62),
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ],
    );
  }
}

class _SessionFormErrorState extends StatelessWidget {
  const _SessionFormErrorState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'No pudimos preparar el formulario de lectura. Inténtalo otra vez en unos segundos.',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
