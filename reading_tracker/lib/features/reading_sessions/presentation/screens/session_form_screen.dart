import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../books/domain/entities/book.dart';
import '../../../books/domain/enums/book_status.dart';
import '../../../books/presentation/providers/books_provider.dart';
import '../../../stats/presentation/providers/stats_provider.dart';
import '../../../stats/presentation/providers/statistics_summary_provider.dart';
import '../../data/repositories/reading_session_repository_provider.dart';
import '../../domain/entities/reading_session.dart';
import '../../domain/usecases/register_reading_session.dart';
import '../providers/reading_sessions_provider.dart';
import '../providers/register_reading_session_provider.dart';
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
    _date = DateTime(initial.year, initial.month, initial.day);
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

    setState(() => _isSaving = true);
    try {
      final pagesRead = int.tryParse(_pagesReadController.text.trim()) ?? 0;
      final minutes = int.tryParse(_minutesController.text.trim()) ?? 0;
      final note = _noteController.text.trim().isEmpty
          ? null
          : _noteController.text.trim();
      final existingSession = widget.session;
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
      ref.invalidate(statsProvider);
      ref.invalidate(statisticsSummaryProvider);
      ref.invalidate(booksProvider);
      ref.invalidate(readingSessionsForDayProvider(_date));
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
      appBar: AppBar(
        title: Text(
          _isEditing ? 'Editar rato de lectura' : 'Añadir tiempo de lectura',
        ),
        actions: [
          IconButton(
            tooltip: 'Guardar',
            icon: const Icon(Icons.check),
            onPressed: _isSaving ? null : _save,
          ),
        ],
      ),
      body: booksAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
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
              padding: const EdgeInsets.all(16),
              children: [
                DropdownButtonFormField<String>(
                  initialValue: _bookId,
                  decoration: const InputDecoration(
                    labelText: 'Libro',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    for (final book in selectableBooks)
                      DropdownMenuItem(
                        value: book.id,
                        child: Text(_bookLabel(book)),
                      ),
                  ],
                  onChanged: (value) => setState(() => _bookId = value),
                ),
                const SizedBox(height: 16),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Fecha'),
                  subtitle: Text('${_date.day}/${_date.month}/${_date.year}'),
                  trailing: const Icon(Icons.calendar_month),
                  onTap: _pickDate,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _pagesReadController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Paginas leidas',
                    suffixText: 'pag',
                    border: OutlineInputBorder(),
                  ),
                  validator: (_) => _activityValidator(),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _minutesController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Minutos leídos',
                    suffixText: 'min',
                    border: OutlineInputBorder(),
                  ),
                  validator: (_) => _activityValidator(),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _noteController,
                  minLines: 3,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    labelText: 'Nota opcional',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _isSaving ? null : _save,
                  child: Text(
                    _isEditing
                        ? 'Guardar cambios'
                        : 'Guardar tiempo de lectura',
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
      return 'Indica paginas o minutos';
    }
    return null;
  }

  Future<void> _pickDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (selected == null) return;
    setState(
      () => _date = DateTime(selected.year, selected.month, selected.day),
    );
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

class _NoReadingBooksMessage extends StatelessWidget {
  const _NoReadingBooksMessage();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'No hay libros en lectura. Marca un libro como "leyendo" antes de añadir tiempo de lectura.',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
