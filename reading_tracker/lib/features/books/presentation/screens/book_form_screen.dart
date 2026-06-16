import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/design_system/design_system.dart';
import '../../data/datasources/book_api_datasource.dart';
import '../../domain/entities/book.dart';
import '../../domain/entities/book_search_result.dart';
import '../../domain/enums/book_status.dart';
import '../../../insights/presentation/providers/reading_insights_summary_provider.dart';
import '../../../stats/presentation/providers/stats_provider.dart';
import '../../../stats/presentation/providers/statistics_summary_provider.dart';
import '../providers/books_provider.dart';
import '../widgets/completion_review_sheet.dart';

class BookFormScreen extends ConsumerStatefulWidget {
  const BookFormScreen({super.key});

  @override
  ConsumerState<BookFormScreen> createState() => _BookFormScreenState();
}

class _BookFormScreenState extends ConsumerState<BookFormScreen> {
  static const _autoSearchMinLength = 3;
  static const _autoSearchDebounce = Duration(milliseconds: 500);
  static const _initialVisibleResults = 5;

  final _searchController = TextEditingController();
  final _totalPagesController = TextEditingController();
  List<BookSearchResult> _results = const [];
  int _visibleResultsCount = _initialVisibleResults;
  BookSearchResult? _selectedBook;
  Timer? _searchDebounce;
  String _activeSearchQuery = '';
  BookStatus _selectedStatus = BookStatus.pending;
  DateTime? _startedAt;
  DateTime? _finishedAt;
  bool _totalPagesAutoFilled = false;
  bool _isSearching = false;
  bool _isSaving = false;
  bool _hasSearched = false;
  String? _error;

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    _totalPagesController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    final query = value.trim();

    if (query.length < _autoSearchMinLength) {
      _activeSearchQuery = '';
      setState(() {
        _isSearching = false;
        _hasSearched = false;
        _error = null;
        _results = const [];
        _visibleResultsCount = _initialVisibleResults;
        _selectedBook = null;
        if (_totalPagesAutoFilled) {
          _totalPagesController.clear();
          _totalPagesAutoFilled = false;
        }
      });
      return;
    }

    _searchDebounce = Timer(_autoSearchDebounce, () {
      _search(unfocus: false);
    });
  }

  Future<void> _search({bool unfocus = true}) async {
    _searchDebounce?.cancel();
    if (unfocus) {
      FocusScope.of(context).unfocus();
    }
    final query = _searchController.text.trim();
    if (query.isEmpty) return;
    final requestQuery = query;
    _activeSearchQuery = requestQuery;

    setState(() {
      _isSearching = true;
      _hasSearched = true;
      _error = null;
      _selectedBook = null;
      _visibleResultsCount = _initialVisibleResults;
    });

    try {
      final datasource = ref.read(bookApiDatasourceProvider);
      final results = await datasource.searchBooks(requestQuery);
      if (!_isCurrentSearch(requestQuery)) return;
      setState(() {
        _results = results;
        _visibleResultsCount = _initialVisibleResults;
      });
    } catch (error) {
      if (!_isCurrentSearch(requestQuery)) return;
      setState(() {
        _error = 'No se pudo buscar el libro. Inténtalo de nuevo.';
        _results = const [];
      });
    } finally {
      if (_isCurrentSearch(requestQuery)) {
        setState(() => _isSearching = false);
      }
    }
  }

  bool _isCurrentSearch(String query) {
    return mounted &&
        _activeSearchQuery == query &&
        _searchController.text.trim() == query;
  }

  void _selectBook(BookSearchResult book) {
    setState(() {
      _selectedBook = book;

      if (book.numberOfPages != null &&
          (_totalPagesAutoFilled ||
              _totalPagesController.text.trim().isEmpty)) {
        _totalPagesController.text = book.numberOfPages.toString();
        _totalPagesAutoFilled = true;
      } else if (book.numberOfPages == null && _totalPagesAutoFilled) {
        _totalPagesController.clear();
        _totalPagesAutoFilled = false;
      }
    });
  }

  void _showMoreResults() {
    setState(() {
      _visibleResultsCount = (_visibleResultsCount + _initialVisibleResults)
          .clamp(0, _results.length)
          .toInt();
    });
  }

  void _changeStatus(BookStatus status) {
    final today = _today();
    setState(() {
      _selectedStatus = status;

      if (status == BookStatus.pending) {
        _startedAt = null;
        _finishedAt = null;
      } else if (status == BookStatus.completed) {
        _startedAt = _clampDate(_startedAt ?? today);
        _finishedAt = null;
      } else {
        _startedAt = _clampDate(_startedAt ?? today);
        _finishedAt = null;
      }
    });
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
    final today = _today();
    final effectiveFirstDate = firstDate ?? DateTime(1900);
    final clampedInitialDate = _clampDate(initialDate ?? today)!;
    final effectiveInitialDate = clampedInitialDate.isBefore(effectiveFirstDate)
        ? effectiveFirstDate
        : clampedInitialDate;
    return showDatePicker(
      context: context,
      initialDate: effectiveInitialDate,
      firstDate: effectiveFirstDate,
      lastDate: today,
    );
  }

  Future<void> _save() async {
    final selectedBook = _selectedBook;
    if (selectedBook == null) return;

    setState(() => _isSaving = true);
    final normalizedDates = _normalizedReadingDates();

    final book = Book(
      id: const Uuid().v4(),
      title: selectedBook.title,
      author: selectedBook.author,
      publisher: selectedBook.publisher,
      coverUrl: selectedBook.coverUrl,
      isbn: selectedBook.isbn,
      firstPublishYear: selectedBook.firstPublishYear,
      totalPages: int.tryParse(_totalPagesController.text.trim()),
      status: _selectedStatus,
      startDate: normalizedDates.startedAt,
      completedDate: normalizedDates.finishedAt,
      createdAt: DateTime.now(),
    );

    await ref.read(booksProvider.notifier).addBook(book);
    ref.invalidate(statsProvider);
    ref.invalidate(statisticsSummaryProvider);
    ref.invalidate(readingInsightsSummaryProvider);

    if (!mounted) return;

    if (_selectedStatus == BookStatus.completed) {
      final review = await showModalBottomSheet<CompletionReview>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (_) => CompletionReviewSheet(title: book.title),
      );

      if (review != null && review.hasContent) {
        await ref
            .read(booksProvider.notifier)
            .updateBook(
              book.copyWith(
                rating: review.rating,
                notes: review.note,
                updatedAt: DateTime.now(),
              ),
            );
        ref.invalidate(statsProvider);
        ref.invalidate(statisticsSummaryProvider);
        ref.invalidate(readingInsightsSummaryProvider);
      }
    }

    if (mounted) Navigator.pop(context, _selectedStatus);
  }

  ({DateTime? startedAt, DateTime? finishedAt}) _normalizedReadingDates() {
    final startedAt = _clampDate(_startedAt);
    var finishedAt = _clampDate(_finishedAt);
    if (startedAt != null &&
        finishedAt != null &&
        finishedAt.isBefore(startedAt)) {
      finishedAt = null;
    }
    return (startedAt: startedAt, finishedAt: finishedAt);
  }

  DateTime? _clampDate(DateTime? date) {
    if (date == null) return null;
    final day = DateTime(date.year, date.month, date.day);
    final today = _today();
    return day.isAfter(today) ? today : day;
  }

  DateTime _today() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(title: const Text('Añadir libro')),
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              theme.scaffoldBackgroundColor,
              theme.colorScheme.primaryContainer.withValues(alpha: 0.16),
              theme.scaffoldBackgroundColor,
            ],
            stops: const [0, 0.42, 1],
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 112),
          children: [
            const _AddBookHero(),
            const SizedBox(height: AppSpacing.lg),
            _SearchField(
              controller: _searchController,
              isSearching: _isSearching,
              onChanged: _onSearchChanged,
              onSubmitted: _search,
            ),
            const SizedBox(height: 16),
            if (_error != null) ...[
              _InlineError(message: _error!),
              const SizedBox(height: 16),
            ],
            if (_selectedBook != null) ...[
              _SelectedBookCard(book: _selectedBook!),
              const SizedBox(height: 16),
            ],
            _FormSection(
              title: 'Cómo entra en tu biblioteca',
              icon: AppIcons.bookmark,
              child: _InitialStatusSelector(
                selectedStatus: _selectedStatus,
                onChanged: _changeStatus,
              ),
            ),
            const SizedBox(height: 16),
            if (_selectedStatus != BookStatus.pending) ...[
              _FormSection(
                title: 'Fechas de lectura',
                icon: AppIcons.calendar,
                child: _InitialDatesFields(
                  startedAt: _startedAt,
                  finishedAt: _finishedAt,
                  showFinishedAt: _selectedStatus == BookStatus.completed,
                  onStartedAtTap: _pickStartedAt,
                  onFinishedAtTap: _pickFinishedAt,
                  onClearStartedAt: () => setState(() {
                    _startedAt = null;
                    _finishedAt = null;
                  }),
                  onClearFinishedAt: () => setState(() => _finishedAt = null),
                ),
              ),
              const SizedBox(height: 16),
            ],
            _FormSection(
              title: 'Datos del libro',
              icon: AppIcons.pages,
              child: _TotalPagesField(
                controller: _totalPagesController,
                onChanged: (_) => _totalPagesAutoFilled = false,
              ),
            ),
            const SizedBox(height: 16),
            _ResultsList(
              results: _results,
              hasSearched: _hasSearched,
              isSearching: _isSearching,
              visibleCount: _visibleResultsCount,
              selectedBook: _selectedBook,
              onSelected: _selectBook,
              onShowMore: _showMoreResults,
            ),
            const SizedBox(height: 24),
            _SaveButton(
              isSaving: _isSaving,
              enabled: _selectedBook != null,
              onPressed: _save,
            ),
          ],
        ),
      ),
    );
  }
}

class _AddBookHero extends StatelessWidget {
  const _AddBookHero();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primary,
            Color.lerp(theme.colorScheme.primary, Colors.black, 0.24)!,
          ],
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: AppShadows.soft(theme.colorScheme.primary),
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
            ),
            child: const Icon(AppIcons.library, color: Colors.white, size: 27),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Nuevo libro',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Busca el libro, elige cómo quieres guardarlo y déjalo listo en tu biblioteca.',
                  style: theme.textTheme.bodyMedium?.copyWith(
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
        color: theme.colorScheme.surface,
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
                  color: theme.colorScheme.secondary.withValues(alpha: 0.22),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 18, color: theme.colorScheme.primary),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          child,
        ],
      ),
    );
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, color: theme.colorScheme.error),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onErrorContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.isSearching,
    required this.onChanged,
    required this.onSubmitted,
  });

  final TextEditingController controller;
  final bool isSearching;
  final ValueChanged<String> onChanged;
  final VoidCallback onSubmitted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.08),
        ),
        boxShadow: AppShadows.editorial(theme.colorScheme.primary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Busca tu próximo libro',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Encuentra portadas y datos para guardarlo en tu biblioteca.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  autofocus: true,
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    labelText: 'Libro, autor o ISBN',
                    hintText: 'Ej. La sombra del viento',
                    prefixIcon: const Icon(AppIcons.search),
                    filled: true,
                    fillColor: theme.colorScheme.primaryContainer.withValues(
                      alpha: 0.18,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: theme.colorScheme.primary.withValues(
                          alpha: 0.18,
                        ),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: theme.colorScheme.primary,
                        width: 1.4,
                      ),
                    ),
                  ),
                  onChanged: onChanged,
                  onSubmitted: (_) => onSubmitted(),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 56,
                height: 56,
                child: FilledButton(
                  key: const Key('book_search_button'),
                  onPressed: isSearching ? null : onSubmitted,
                  child: isSearching
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.search_rounded),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ResultsList extends StatelessWidget {
  const _ResultsList({
    required this.results,
    required this.hasSearched,
    required this.isSearching,
    required this.visibleCount,
    required this.selectedBook,
    required this.onSelected,
    required this.onShowMore,
  });

  final List<BookSearchResult> results;
  final bool hasSearched;
  final bool isSearching;
  final int visibleCount;
  final BookSearchResult? selectedBook;
  final ValueChanged<BookSearchResult> onSelected;
  final VoidCallback onShowMore;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (isSearching) {
      return _SearchFeedbackCard(
        icon: AppIcons.search,
        title: 'Buscando tu libro',
        message: 'Estamos revisando resultados y portadas disponibles.',
        isLoading: true,
      );
    }

    if (results.isEmpty) {
      if (!hasSearched) return const SizedBox.shrink();
      return const _SearchFeedbackCard(
        icon: AppIcons.book,
        title: 'No encontramos ese libro',
        message: 'Prueba con otro título, autor o ISBN más específico.',
      );
    }

    final visibleResults = results.take(visibleCount).toList();
    final hasMoreResults = visibleResults.length < results.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Resultados',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Elige el resultado que mejor encaje con tu edición.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),
        for (var index = 0; index < visibleResults.length; index++)
          _BookResultTile(
            key: ValueKey(
              'book_result_${index}_${visibleResults[index].title}_${visibleResults[index].author ?? ''}_${visibleResults[index].firstPublishYear ?? ''}',
            ),
            book: visibleResults[index],
            isSelected: identical(visibleResults[index], selectedBook),
            subtitle: _subtitleFor(visibleResults[index]),
            onTap: () => onSelected(visibleResults[index]),
          ),
        if (hasMoreResults) ...[
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: onShowMore,
              icon: const Icon(Icons.expand_more),
              label: Text(
                'Ver más resultados (${results.length - visibleResults.length})',
              ),
            ),
          ),
        ],
      ],
    );
  }

  String _subtitleFor(BookSearchResult book) {
    return [
      if (book.author != null) book.author,
      if (book.publisher != null) book.publisher,
      if (book.firstPublishYear != null) '${book.firstPublishYear}',
      if (book.numberOfPages != null) '${book.numberOfPages} páginas',
    ].whereType<String>().join(' · ');
  }
}

class _SearchFeedbackCard extends StatelessWidget {
  const _SearchFeedbackCard({
    required this.icon,
    required this.title,
    required this.message,
    this.isLoading = false,
  });

  final IconData icon;
  final String title;
  final String message;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        children: [
          if (isLoading)
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            Icon(icon, color: theme.colorScheme.primary, size: 30),
          const SizedBox(height: AppSpacing.md),
          Text(
            title,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            message,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _BookResultTile extends StatelessWidget {
  const _BookResultTile({
    super.key,
    required this.book,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  final BookSearchResult book;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: isSelected
            ? theme.colorScheme.primaryContainer.withValues(alpha: 0.58)
            : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: isSelected
                    ? theme.colorScheme.primary.withValues(alpha: 0.34)
                    : theme.colorScheme.primary.withValues(alpha: 0.07),
              ),
            ),
            child: Row(
              children: [
                _Cover(url: book.coverUrl, width: 54, height: 78),
                const SizedBox(width: 14),
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
                      if (subtitle.isNotEmpty) ...[
                        const SizedBox(height: 5),
                        Text(
                          subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Icon(
                  isSelected
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked_rounded,
                  color: isSelected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.primary.withValues(alpha: 0.30),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InitialStatusSelector extends StatelessWidget {
  const _InitialStatusSelector({
    required this.selectedStatus,
    required this.onChanged,
  });

  final BookStatus selectedStatus;
  final ValueChanged<BookStatus> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<BookStatus>(
      initialValue: selectedStatus,
      decoration: const InputDecoration(
        labelText: 'Estado inicial',
        border: OutlineInputBorder(),
      ),
      items: [
        for (final status in BookStatus.values)
          DropdownMenuItem(value: status, child: Text(status.label)),
      ],
      onChanged: (status) {
        if (status != null) onChanged(status);
      },
    );
  }
}

class _InitialDatesFields extends StatelessWidget {
  const _InitialDatesFields({
    required this.startedAt,
    required this.finishedAt,
    required this.showFinishedAt,
    required this.onStartedAtTap,
    required this.onFinishedAtTap,
    required this.onClearStartedAt,
    required this.onClearFinishedAt,
  });

  final DateTime? startedAt;
  final DateTime? finishedAt;
  final bool showFinishedAt;
  final VoidCallback onStartedAtTap;
  final VoidCallback onFinishedAtTap;
  final VoidCallback onClearStartedAt;
  final VoidCallback onClearFinishedAt;

  String _format(DateTime? date) {
    if (date == null) return 'Sin fecha';
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Material(
          color: Colors.transparent,
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 4),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: theme.colorScheme.primary.withValues(alpha: 0.12),
              ),
            ),
            tileColor: theme.colorScheme.primaryContainer.withValues(
              alpha: 0.14,
            ),
            title: const Text('Fecha de inicio'),
            subtitle: Text(_format(startedAt)),
            trailing: IconButton(
              tooltip: 'Quitar fecha de inicio',
              icon: const Icon(Icons.close_rounded),
              onPressed: startedAt == null ? null : onClearStartedAt,
            ),
            leading: Icon(AppIcons.calendar, color: theme.colorScheme.primary),
            onTap: onStartedAtTap,
          ),
        ),
        if (showFinishedAt) ...[
          const SizedBox(height: AppSpacing.sm),
          Material(
            color: Colors.transparent,
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: theme.colorScheme.primary.withValues(alpha: 0.12),
                ),
              ),
              tileColor: theme.colorScheme.primaryContainer.withValues(
                alpha: 0.14,
              ),
              title: const Text('Fecha de finalización'),
              subtitle: Text(_format(finishedAt)),
              trailing: IconButton(
                tooltip: 'Quitar fecha de fin',
                icon: const Icon(Icons.close_rounded),
                onPressed: finishedAt == null ? null : onClearFinishedAt,
              ),
              leading: Icon(AppIcons.star, color: theme.colorScheme.primary),
              onTap: onFinishedAtTap,
            ),
          ),
        ],
      ],
    );
  }
}

class _TotalPagesField extends StatelessWidget {
  const _TotalPagesField({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: 'Total de páginas',
        hintText: 'Opcional',
        filled: true,
        fillColor: theme.colorScheme.primaryContainer.withValues(alpha: 0.18),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: theme.colorScheme.primary.withValues(alpha: 0.18),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: theme.colorScheme.primary, width: 1.4),
        ),
      ),
    );
  }
}

class _SelectedBookCard extends StatelessWidget {
  const _SelectedBookCard({required this.book});

  final BookSearchResult book;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.44),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.16),
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          _Cover(url: book.coverUrl, width: 62, height: 90),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Seleccionado',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.4,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  book.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (book.author != null)
                  Text(
                    book.author!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                if (book.numberOfPages != null)
                  Text('${book.numberOfPages} páginas'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Cover extends StatelessWidget {
  const _Cover({required this.url, this.width = 48, this.height = 72});

  final String? url;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    if (url == null) {
      return Container(
        width: width,
        height: height,
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: const Icon(AppIcons.book),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: Image.network(
        url!,
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          width: width,
          height: height,
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: const Icon(AppIcons.book),
        ),
      ),
    );
  }
}

class _SaveButton extends StatelessWidget {
  const _SaveButton({
    required this.isSaving,
    required this.enabled,
    required this.onPressed,
  });

  final bool isSaving;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final canSubmit = enabled && !isSaving;

    return MouseRegion(
      cursor: canSubmit
          ? SystemMouseCursors.click
          : SystemMouseCursors.forbidden,
      child: SizedBox(
        width: double.infinity,
        child: FilledButton(
          onPressed: canSubmit ? onPressed : null,
          child: isSaving
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!enabled) ...[
                      const Icon(Icons.lock_outline_rounded, size: 18),
                      const SizedBox(width: AppSpacing.sm),
                    ],
                    const Text('Guardar libro'),
                  ],
                ),
        ),
      ),
    );
  }
}
