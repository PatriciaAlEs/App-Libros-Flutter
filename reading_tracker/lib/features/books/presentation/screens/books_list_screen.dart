import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/enums/book_status.dart';
import '../providers/books_provider.dart';
import '../widgets/book_card.dart';
import '../widgets/status_filter_bar.dart';
import '../../../../core/database/database_provider.dart';
import '../../../../core/database/database_seed.dart';

class BooksListScreen extends ConsumerStatefulWidget {
  const BooksListScreen({super.key});

  @override
  ConsumerState<BooksListScreen> createState() => _BooksListScreenState();
}

class _BooksListScreenState extends ConsumerState<BooksListScreen> {
  BookStatus? _selectedStatus;

  @override
  void initState() {
    super.initState();
    // En modo debug, limpiar la tabla al arrancar para pruebas no persistentes.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (kDebugMode) {
        try {
          await ref.read(bookDaoProvider).deleteAllBooks();
          await ref.read(booksProvider.notifier).loadBooks();
        } catch (_) {}
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final booksAsync = ref.watch(booksProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Books'),
        actions: [
          IconButton(
            tooltip: 'Seed books',
            icon: const Icon(Icons.cloud_download),
            onPressed: () async {
              final seeder = DatabaseSeeder(ref.read(bookDaoProvider));
              try {
                await seeder.seedIfNeeded();
                await ref.read(booksProvider.notifier).loadBooks();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Seed ejecutado (si necesario)')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error al seed: $e')),
                );
              }
            },
          ),
        ],
      ),
      body: booksAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
        data: (books) {
          final filteredBooks = _selectedStatus == null
              ? books
              : books.where((book) => book.status == _selectedStatus).toList();

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
                    ? const Center(child: Text('No books yet.'))
                    : ListView.builder(
                        itemCount: filteredBooks.length,
                        itemBuilder: (context, index) {
                          final book = filteredBooks[index];
                          return BookCard(
                            book: book,
                            onTap: () {
                              Navigator.pushNamed(
                                context,
                                '/book/detail',
                                arguments: book.id,
                              );
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
        onPressed: () => Navigator.pushNamed(context, '/book/add'),
        child: const Icon(Icons.add),
      ),
    );
  }
}
