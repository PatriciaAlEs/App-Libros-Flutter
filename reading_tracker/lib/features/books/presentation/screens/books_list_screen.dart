import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/book.dart';
import '../../domain/enums/book_status.dart';
import '../providers/books_provider.dart';
import '../widgets/book_card.dart';
import '../widgets/status_filter_bar.dart';

class BooksListScreen extends ConsumerStatefulWidget {
  const BooksListScreen({super.key});

  @override
  ConsumerState<BooksListScreen> createState() => _BooksListScreenState();
}

class _BooksListScreenState extends ConsumerState<BooksListScreen> {
  BookStatus? _selectedStatus;

  @override
  Widget build(BuildContext context) {
    final booksAsync = ref.watch(booksProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis libros'),
        actions: [
          IconButton(
            tooltip: 'Estadísticas',
            icon: const Icon(Icons.bar_chart),
            onPressed: () => Navigator.pushNamed(context, '/stats'),
          ),
          IconButton(
            tooltip: 'Calendario',
            icon: const Icon(Icons.calendar_month),
            onPressed: () => Navigator.pushNamed(context, '/calendar'),
          ),
        ],
      ),
      body: booksAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) =>
            const Center(child: Text('No se pudieron cargar los libros.')),
        data: (books) {
          final filteredBooks = _selectedStatus == null
              ? books
              : books.where((book) => book.status == _selectedStatus).toList();
          final visibleBooks = _selectedStatus == null
              ? _readingBooksFirst(filteredBooks)
              : filteredBooks;

          return Column(
            children: [
              StatusFilterBar(
                selectedStatus: _selectedStatus,
                onChanged: (status) {
                  setState(() => _selectedStatus = status);
                },
              ),
              Expanded(
                child: filteredBooks.isEmpty
                    ? _BooksEmptyState(hasBooks: books.isNotEmpty)
                    : ListView.builder(
                        itemCount: visibleBooks.length,
                        itemBuilder: (context, index) {
                          final book = visibleBooks[index];
                          return BookCard(
                            book: book,
                            onTap: () async {
                              final deleted = await Navigator.pushNamed(
                                context,
                                '/book/detail',
                                arguments: book.id,
                              );
                              if (!context.mounted) return;
                              if (deleted == true) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Libro eliminado'),
                                  ),
                                );
                              }
                            },
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final status = await Navigator.pushNamed(context, '/book/add');
          if (!context.mounted) return;
          if (status is BookStatus) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Libro añadido como ${status.label}')),
            );
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  List<Book> _readingBooksFirst(List<Book> books) {
    final readingBooks = books
        .where((book) => book.status == BookStatus.reading)
        .toList();
    final otherBooks = books
        .where((book) => book.status != BookStatus.reading)
        .toList();
    return [...readingBooks, ...otherBooks];
  }
}

class _BooksEmptyState extends StatelessWidget {
  const _BooksEmptyState({required this.hasBooks});

  final bool hasBooks;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          hasBooks
              ? 'No hay libros en este estado.'
              : 'Todavía no tienes libros. Añade tu primer libro con el botón +.',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
