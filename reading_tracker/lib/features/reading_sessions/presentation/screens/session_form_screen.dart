import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../books/domain/entities/book.dart';
import '../../../books/domain/enums/book_status.dart';
import '../../../books/presentation/providers/books_provider.dart';
import '../../../stats/presentation/providers/stats_provider.dart';
import '../../data/repositories/reading_session_repository_provider.dart';
import '../../domain/entities/reading_session.dart';

class SessionFormScreen extends ConsumerStatefulWidget {
  const SessionFormScreen({super.key, this.initialDate});

  final DateTime? initialDate;

  @override
  ConsumerState<SessionFormScreen> createState() => _SessionFormScreenState();
}

class _SessionFormScreenState extends ConsumerState<SessionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _minutesController = TextEditingController();
  final _noteController = TextEditingController();
  String? _bookId;
  late DateTime _date;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final initial = widget.initialDate ?? now;
    _date = DateTime(initial.year, initial.month, initial.day);
  }

  @override
  void dispose() {
    _minutesController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _bookId == null) return;

    setState(() => _isSaving = true);
    try {
      final repository = ref.read(readingSessionRepositoryProvider);
      final session = ReadingSession(
        id: const Uuid().v4(),
        bookId: _bookId!,
        date: _date,
        minutes: int.parse(_minutesController.text.trim()),
        note: _noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim(),
        createdAt: DateTime.now(),
      );

      await repository.addSession(session);
      ref.invalidate(statsProvider);
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
        title: const Text('Nueva sesion'),
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
          final readingBooks = books
              .where((book) => book.status == BookStatus.reading)
              .toList();

          if (readingBooks.isEmpty) {
            return const _NoReadingBooksMessage();
          }

          if (_bookId == null ||
              !readingBooks.any((book) => book.id == _bookId)) {
            _bookId = readingBooks.first.id;
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
                    for (final book in readingBooks)
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
                  controller: _minutesController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Minutos leidos',
                    suffixText: 'min',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    final minutes = int.tryParse(value?.trim() ?? '');
                    if (minutes == null || minutes <= 0) {
                      return 'Indica minutos validos';
                    }
                    return null;
                  },
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
                  child: const Text('Guardar sesion'),
                ),
              ],
            ),
          );
        },
      ),
    );
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
}

class _NoReadingBooksMessage extends StatelessWidget {
  const _NoReadingBooksMessage();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'No hay libros en lectura. Marca un libro como reading antes de anadir una sesion.',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
