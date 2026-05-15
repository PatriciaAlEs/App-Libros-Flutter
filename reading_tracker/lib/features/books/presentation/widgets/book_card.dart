import 'package:flutter/material.dart';

import '../../domain/entities/book.dart';

class BookCard extends StatelessWidget {
  const BookCard({
    super.key,
    required this.book,
    required this.onTap,
  });

  final Book book;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final subtitle = [
      if (book.author != null && book.author!.isNotEmpty) book.author!,
      if (book.pages != null) '${book.pages} pages',
    ].join(' - ');

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ListTile(
        title: Text(book.title),
        subtitle: subtitle.isEmpty ? null : Text(subtitle),
        trailing: Text(book.status.toValue()),
        onTap: onTap,
      ),
    );
  }
}
