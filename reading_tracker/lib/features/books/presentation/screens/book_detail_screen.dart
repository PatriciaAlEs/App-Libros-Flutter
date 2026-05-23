import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../stats/presentation/providers/stats_provider.dart';
import '../../../stats/presentation/providers/statistics_summary_provider.dart';
import '../../domain/entities/book.dart';
import '../../domain/enums/book_status.dart';
import '../providers/books_provider.dart';
import '../widgets/completion_review_sheet.dart';

class BookDetailScreen extends ConsumerWidget {
  const BookDetailScreen({super.key, required this.bookId});

  final String bookId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final booksAsync = ref.watch(booksProvider);

    return booksAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, _) => Scaffold(body: Center(child: Text('Error: $error'))),
      data: (books) {
        Book? book;
        for (final candidate in books) {
          if (candidate.id == bookId) {
            book = candidate;
            break;
          }
        }

        if (book == null) {
          return const Scaffold(
            body: Center(child: Text('Libro no encontrado.')),
          );
        }

        return _BookDetailView(book: book);
      },
    );
  }
}

class _BookDetailView extends ConsumerWidget {
  const _BookDetailView({required this.book});

  final Book book;

  Future<bool> _onStatusChanged(
    BuildContext context,
    BookStatus newStatus,
    WidgetRef ref,
  ) async {
    final completionReview = newStatus == BookStatus.completed
        ? await showModalBottomSheet<CompletionReview>(
            context: context,
            isScrollControlled: true,
            showDragHandle: true,
            builder: (_) => CompletionReviewSheet(
              title: book.title,
              initialRating: book.rating,
              initialNote: book.notes,
            ),
          )
        : null;

    if (newStatus == BookStatus.completed && completionReview == null) {
      return false;
    }

    final updated = _updatedBookForStatus(newStatus, completionReview);
    await ref.read(booksProvider.notifier).updateBook(updated);
    ref.invalidate(statsProvider);
    ref.invalidate(statisticsSummaryProvider);

    if (!context.mounted) return true;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Estado actualizado')));
    return true;
  }

  Book _updatedBookForStatus(
    BookStatus newStatus,
    CompletionReview? completionReview,
  ) {
    return Book(
      id: book.id,
      title: book.title,
      author: book.author,
      totalPages: book.totalPages,
      currentPage: book.currentPage,
      rating: completionReview == null ? book.rating : completionReview.rating,
      notes: completionReview == null ? book.notes : completionReview.note,
      publisher: book.publisher,
      coverUrl: book.coverUrl,
      isbn: book.isbn,
      firstPublishYear: book.firstPublishYear,
      genre: book.genre,
      language: book.language,
      status: newStatus,
      startDate: newStatus == BookStatus.reading && book.startDate == null
          ? DateTime.now()
          : book.startDate,
      completedDate: newStatus == BookStatus.completed
          ? DateTime.now()
          : book.completedDate,
      createdAt: book.createdAt,
      updatedAt: DateTime.now(),
    );
  }

  Book _updatedBookForDates(_DatesEditResult dates) {
    return Book(
      id: book.id,
      title: book.title,
      author: book.author,
      totalPages: book.totalPages,
      currentPage: book.currentPage,
      rating: book.rating,
      notes: book.notes,
      publisher: book.publisher,
      coverUrl: book.coverUrl,
      isbn: book.isbn,
      firstPublishYear: book.firstPublishYear,
      genre: book.genre,
      language: book.language,
      status: book.status,
      startDate: dates.startedAt,
      completedDate: dates.finishedAt,
      createdAt: book.createdAt,
      updatedAt: DateTime.now(),
    );
  }

  Future<void> _onDelete(WidgetRef ref, BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => const _DeleteDialog(),
    );

    if (confirm == true) {
      await ref.read(booksProvider.notifier).deleteBook(book.id);
      ref.invalidate(statsProvider);
      ref.invalidate(statisticsSummaryProvider);
      if (context.mounted) Navigator.pop(context, true);
    }
  }

  Future<void> _openPagesEditor(BuildContext context, WidgetRef ref) async {
    final pages = await showModalBottomSheet<_PagesEditResult>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _PagesEditSheet(book: book),
    );
    if (pages == null) return;

    await ref
        .read(booksProvider.notifier)
        .updateBook(
          book.copyWith(
            currentPage: pages.currentPage,
            totalPages: pages.totalPages,
            updatedAt: DateTime.now(),
          ),
        );
    ref.invalidate(statsProvider);
    ref.invalidate(statisticsSummaryProvider);
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Paginas actualizadas')));
  }

  Future<void> _openDatesEditor(BuildContext context, WidgetRef ref) async {
    final dates = await showDialog<_DatesEditResult>(
      context: context,
      builder: (_) => _DatesEditDialog(book: book),
    );
    if (dates == null) return;

    await ref
        .read(booksProvider.notifier)
        .updateBook(_updatedBookForDates(dates));
    ref.invalidate(statsProvider);
    ref.invalidate(statisticsSummaryProvider);
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Fechas actualizadas')));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle del libro'),
        actions: [
          IconButton(
            tooltip: 'Eliminar libro',
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _onDelete(ref, context),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _InfoSection(book: book),
          const SizedBox(height: 24),
          _StatusSection(
            book: book,
            onStatusChanged: (status) => _onStatusChanged(context, status, ref),
          ),
          const SizedBox(height: 24),
          _ReaderDataSection(
            book: book,
            onEditPages: () => _openPagesEditor(context, ref),
          ),
          const SizedBox(height: 24),
          _DatesSection(
            book: book,
            onEditDates: () => _openDatesEditor(context, ref),
          ),
        ],
      ),
    );
  }
}

class _InfoSection extends StatelessWidget {
  const _InfoSection({required this.book});

  final Book book;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Cover(url: book.coverUrl),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(book.title, style: textTheme.headlineSmall),
              if (book.author != null) ...[
                const SizedBox(height: 4),
                Text(book.author!, style: textTheme.bodyLarge),
              ],
              if (book.publisher != null) ...[
                const SizedBox(height: 4),
                Text(book.publisher!, style: textTheme.bodyMedium),
              ],
              if (book.firstPublishYear != null) ...[
                const SizedBox(height: 4),
                Text('${book.firstPublishYear}', style: textTheme.bodyMedium),
              ],
              if (book.isbn != null) ...[
                const SizedBox(height: 4),
                Text('ISBN ${book.isbn}', style: textTheme.bodySmall),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _StatusSection extends StatefulWidget {
  const _StatusSection({required this.book, required this.onStatusChanged});

  final Book book;
  final Future<bool> Function(BookStatus status) onStatusChanged;

  @override
  State<_StatusSection> createState() => _StatusSectionState();
}

class _StatusSectionState extends State<_StatusSection> {
  late BookStatus _selectedStatus;

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.book.status;
  }

  @override
  void didUpdateWidget(covariant _StatusSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.book.status != widget.book.status) {
      _selectedStatus = widget.book.status;
    }
  }

  Future<void> _handleStatusChanged(BookStatus value) async {
    if (value == widget.book.status) return;

    setState(() => _selectedStatus = value);
    final saved = await widget.onStatusChanged(value);
    if (!saved && mounted) {
      setState(() => _selectedStatus = widget.book.status);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Estado', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        DropdownButtonFormField<BookStatus>(
          key: ValueKey(_selectedStatus),
          initialValue: _selectedStatus,
          decoration: const InputDecoration(border: OutlineInputBorder()),
          items: BookStatus.values
              .map(
                (status) =>
                    DropdownMenuItem(value: status, child: Text(status.label)),
              )
              .toList(),
          onChanged: (value) {
            if (value != null) {
              _handleStatusChanged(value);
            }
          },
        ),
      ],
    );
  }
}

class _ReaderDataSection extends StatelessWidget {
  const _ReaderDataSection({required this.book, required this.onEditPages});

  final Book book;
  final VoidCallback onEditPages;

  @override
  Widget build(BuildContext context) {
    final progress = [
      if (book.currentPage != null) '${book.currentPage}',
      if (book.totalPages != null) 'de ${book.totalPages}',
    ].join(' ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Datos de lectura',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        _DateRow(label: 'Progreso', value: progress.isEmpty ? '-' : progress),
        _DateRow(
          label: 'Total de paginas',
          value: book.totalPages == null ? '-' : '${book.totalPages}',
        ),
        _DateRow(
          label: 'Valoracion',
          value: book.rating == null ? '-' : '${_formatRating(book.rating!)}/5',
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton.icon(
            onPressed: onEditPages,
            icon: const Icon(Icons.edit_outlined),
            label: const Text('Editar paginas'),
          ),
        ),
        if (book.notes != null && book.notes!.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(book.notes!, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ],
    );
  }

  String _formatRating(double rating) {
    return rating.toStringAsFixed(rating % 1 == 0 ? 1 : 2);
  }
}

class _PagesEditResult {
  const _PagesEditResult({this.currentPage, this.totalPages});

  final int? currentPage;
  final int? totalPages;
}

class _PagesEditSheet extends StatefulWidget {
  const _PagesEditSheet({required this.book});

  final Book book;

  @override
  State<_PagesEditSheet> createState() => _PagesEditSheetState();
}

class _PagesEditSheetState extends State<_PagesEditSheet> {
  late final TextEditingController _currentPageController;
  late final TextEditingController _totalPagesController;

  @override
  void initState() {
    super.initState();
    _currentPageController = TextEditingController(
      text: widget.book.currentPage?.toString() ?? '',
    );
    _totalPagesController = TextEditingController(
      text: widget.book.totalPages?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _currentPageController.dispose();
    _totalPagesController.dispose();
    super.dispose();
  }

  void _save() {
    final currentPage = int.tryParse(_currentPageController.text.trim());
    final totalPages = int.tryParse(_totalPagesController.text.trim());

    Navigator.pop(
      context,
      _PagesEditResult(
        currentPage: currentPage != null && currentPage > 0
            ? currentPage
            : null,
        totalPages: totalPages != null && totalPages > 0 ? totalPages : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(24, 0, 24, bottomInset + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Editar paginas',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _currentPageController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Pagina actual',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _totalPagesController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Total de paginas',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _save,
              child: const Text('Guardar paginas'),
            ),
          ],
        ),
      ),
    );
  }
}

class _DatesSection extends StatelessWidget {
  const _DatesSection({required this.book, required this.onEditDates});

  final Book book;
  final VoidCallback onEditDates;

  String _format(DateTime? date) {
    if (date == null) return '-';
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Fechas', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        _DateRow(label: 'Anadido', value: _format(book.addedAt)),
        _DateRow(label: 'Empezado', value: _format(book.startedAt)),
        _DateRow(label: 'Terminado', value: _format(book.finishedAt)),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton.icon(
            onPressed: onEditDates,
            icon: const Icon(Icons.event_outlined),
            label: const Text('Editar fechas'),
          ),
        ),
      ],
    );
  }
}

class _DatesEditResult {
  const _DatesEditResult({this.startedAt, this.finishedAt});

  final DateTime? startedAt;
  final DateTime? finishedAt;
}

class _DatesEditDialog extends StatefulWidget {
  const _DatesEditDialog({required this.book});

  final Book book;

  @override
  State<_DatesEditDialog> createState() => _DatesEditDialogState();
}

class _DatesEditDialogState extends State<_DatesEditDialog> {
  DateTime? _startedAt;
  DateTime? _finishedAt;

  @override
  void initState() {
    super.initState();
    _startedAt = widget.book.startedAt;
    _finishedAt = widget.book.finishedAt;
  }

  Future<void> _pickStartedAt() async {
    final selected = await _pickDate(_startedAt);
    if (selected != null) {
      setState(() {
        _startedAt = selected;
        if (_finishedAt != null && _finishedAt!.isBefore(selected)) {
          _finishedAt = null;
        }
      });
    }
  }

  Future<void> _pickFinishedAt() async {
    final selected = await _pickDate(
      _finishedAt ?? _startedAt,
      firstDate: _startedAt,
    );
    if (selected != null) {
      setState(() => _finishedAt = selected);
    }
  }

  Future<DateTime?> _pickDate(DateTime? initialDate, {DateTime? firstDate}) {
    final now = DateTime.now();
    final effectiveFirstDate = firstDate ?? DateTime(1900);
    final effectiveInitialDate =
        initialDate != null && initialDate.isBefore(effectiveFirstDate)
        ? effectiveFirstDate
        : initialDate ?? now;
    return showDatePicker(
      context: context,
      initialDate: effectiveInitialDate,
      firstDate: effectiveFirstDate,
      lastDate: DateTime(now.year + 5),
    );
  }

  void _save() {
    Navigator.pop(
      context,
      _DatesEditResult(startedAt: _startedAt, finishedAt: _finishedAt),
    );
  }

  String _format(DateTime? date) {
    if (date == null) return 'Sin fecha';
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Editar fechas'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Anadido'),
              subtitle: Text(_format(widget.book.addedAt)),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Empezado'),
              subtitle: Text(_format(_startedAt)),
              trailing: IconButton(
                tooltip: 'Quitar fecha de inicio',
                icon: const Icon(Icons.close),
                onPressed: _startedAt == null
                    ? null
                    : () => setState(() {
                        _startedAt = null;
                        _finishedAt = null;
                      }),
              ),
              onTap: _pickStartedAt,
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Terminado'),
              subtitle: Text(_format(_finishedAt)),
              trailing: IconButton(
                tooltip: 'Quitar fecha de fin',
                icon: const Icon(Icons.close),
                onPressed: _finishedAt == null
                    ? null
                    : () => setState(() => _finishedAt = null),
              ),
              onTap: _pickFinishedAt,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(onPressed: _save, child: const Text('Guardar fechas')),
      ],
    );
  }
}

class _DateRow extends StatelessWidget {
  const _DateRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          Text(value, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
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
        width: 88,
        height: 132,
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: const Icon(Icons.menu_book),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: Image.network(
        url!,
        width: 88,
        height: 132,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          width: 88,
          height: 132,
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: const Icon(Icons.menu_book),
        ),
      ),
    );
  }
}

class _DeleteDialog extends StatelessWidget {
  const _DeleteDialog();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Eliminar libro'),
      content: const Text('Esta accion no se puede deshacer.'),
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
