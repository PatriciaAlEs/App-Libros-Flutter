import '../../../../core/preferences/reader_profile_controller.dart';
import '../../../books/domain/entities/book.dart';
import '../../../reading_sessions/domain/entities/reading_session.dart';
import '../models/reader_context.dart';

abstract class ContextFormatter {
  String format(ReaderContext context);
}

class MarkdownContextFormatter implements ContextFormatter {
  const MarkdownContextFormatter({
    this.maxCurrentBooks = 5,
    this.maxCompletedBooks = 5,
    this.maxRecentSessions = 5,
  });

  final int maxCurrentBooks;
  final int maxCompletedBooks;
  final int maxRecentSessions;

  @override
  String format(ReaderContext context) {
    final sections = <String>[
      _contextSection(context),
      if (_hasProfileData(context.readerProfile))
        _profileSection(context.readerProfile!),
      if (context.annualReadingGoal != null)
        _annualGoalSection(context.annualReadingGoal!),
      if (_hasLibraryData(context)) _librarySection(context),
      if (context.activity.readingSessions.isNotEmpty)
        _activitySection(context),
    ];

    return sections.join('\n\n');
  }

  String _contextSection(ReaderContext context) {
    return '# Contexto\n\n- Generado: ${_formatDateTime(context.metadata.generatedAt)}';
  }

  bool _hasProfileData(ReaderProfile? profile) {
    if (profile == null) return false;
    return profile.displayName.isNotEmpty ||
        profile.customGreeting.trim().isNotEmpty ||
        profile.currentReadingBookId?.trim().isNotEmpty == true;
  }

  String _profileSection(ReaderProfile profile) {
    final lines = <String>['# Perfil lector'];
    if (profile.displayName.isNotEmpty) {
      lines.add('- Nombre: ${profile.displayName}');
    }
    if (profile.customGreeting.trim().isNotEmpty) {
      lines.add('- Saludo preferido: ${profile.fallbackGreeting}');
    }
    final currentReadingBookId = profile.currentReadingBookId?.trim();
    if (currentReadingBookId != null && currentReadingBookId.isNotEmpty) {
      lines.add('- Libro actual destacado: $currentReadingBookId');
    }
    return lines.join('\n');
  }

  String _annualGoalSection(int annualReadingGoal) {
    return '# Objetivo anual\n\n- Meta de libros: $annualReadingGoal';
  }

  bool _hasLibraryData(ReaderContext context) {
    return context.library.currentBooks.any(_hasTitle) ||
        context.library.completedBooks.any(_hasTitle) ||
        context.library.pendingBooks.any(_hasTitle) ||
        context.library.abandonedBooks.any(_hasTitle);
  }

  String _librarySection(ReaderContext context) {
    final lines = <String>['# Biblioteca'];
    final currentBooks = context.library.currentBooks.where(_hasTitle).toList()
      ..sort(_sortBooksByUpdatedThenTitle);
    final completedBooks =
        context.library.completedBooks.where(_hasTitle).toList()
          ..sort(_sortCompletedBooks);
    final pendingBooks = context.library.pendingBooks.where(_hasTitle).toList()
      ..sort(_sortBooksByCreatedThenTitle);
    final abandonedBooks =
        context.library.abandonedBooks.where(_hasTitle).toList()
          ..sort(_sortBooksByUpdatedThenTitle);

    _appendBookGroup(
      lines,
      title: 'Libros en lectura',
      books: currentBooks.take(maxCurrentBooks),
    );
    _appendBookGroup(
      lines,
      title: 'Ultimos libros terminados',
      books: completedBooks.take(maxCompletedBooks),
    );
    _appendBookGroup(lines, title: 'Pendientes', books: pendingBooks.take(3));
    _appendBookGroup(
      lines,
      title: 'Abandonados',
      books: abandonedBooks.take(3),
    );

    return lines.join('\n');
  }

  void _appendBookGroup(
    List<String> lines, {
    required String title,
    required Iterable<Book> books,
  }) {
    final visibleBooks = books.toList();
    if (visibleBooks.isEmpty) return;

    lines
      ..add('')
      ..add('## $title');
    for (final book in visibleBooks) {
      lines.add('- ${_formatBook(book)}');
    }
  }

  String _activitySection(ReaderContext context) {
    final sessions = context.activity.readingSessions.toList()
      ..sort(_sortSessions);
    final totalMinutes = sessions.fold<int>(
      0,
      (total, session) => total + session.minutes,
    );
    final totalPages = sessions.fold<int>(
      0,
      (total, session) => total + session.pagesRead,
    );

    final lines = <String>[
      '# Actividad',
      '',
      '- Sesiones registradas: ${sessions.length}',
      '- Minutos leidos: $totalMinutes',
    ];
    if (totalPages > 0) {
      lines.add('- Paginas registradas: $totalPages');
    }

    final recentSessions = sessions.take(maxRecentSessions).toList();
    if (recentSessions.isNotEmpty) {
      lines
        ..add('')
        ..add('## Sesiones recientes');
      for (final session in recentSessions) {
        lines.add('- ${_formatSession(session, context.library.allBooks)}');
      }
    }

    return lines.join('\n');
  }

  bool _hasTitle(Book book) => book.title.trim().isNotEmpty;

  String _formatBook(Book book) {
    final details = <String>[];
    final author = book.author?.trim();
    if (author != null && author.isNotEmpty) details.add(author);
    if (book.currentPage != null && book.totalPages != null) {
      details.add('${book.currentPage}/${book.totalPages} pags.');
    } else if (book.totalPages != null) {
      details.add('${book.totalPages} pags.');
    } else if (book.currentPage != null) {
      details.add('pagina ${book.currentPage}');
    }
    if (book.rating != null) details.add('valoracion ${book.rating}');
    final genre = book.genre?.trim();
    if (genre != null && genre.isNotEmpty) details.add('genero $genre');
    final notes = book.notes?.trim();
    if (notes != null && notes.isNotEmpty) details.add('notas: $notes');
    final publisher = book.publisher?.trim();
    if (publisher != null && publisher.isNotEmpty) {
      details.add('editorial $publisher');
    }
    final isbn = book.isbn?.trim();
    if (isbn != null && isbn.isNotEmpty) details.add('ISBN $isbn');
    if (book.completedDate != null) {
      details.add('terminado ${_formatDate(book.completedDate!)}');
    }

    final title = book.title.trim();
    if (details.isEmpty) return title;
    return '$title (${details.join(', ')})';
  }

  String _formatSession(ReadingSession session, List<Book> books) {
    final details = <String>[
      _formatDate(session.date),
      '${session.minutes} min',
    ];
    if (session.pagesRead > 0) details.add('${session.pagesRead} pags.');
    final matchingBooks = books.where((book) => book.id == session.bookId);
    final bookLabel = matchingBooks.isEmpty
        ? session.bookId
        : matchingBooks.first.title.trim();
    return '${details.join(', ')} - libro $bookLabel';
  }

  int _sortCompletedBooks(Book a, Book b) {
    final dateComparison = _compareNullableDateDesc(
      a.completedDate,
      b.completedDate,
    );
    if (dateComparison != 0) return dateComparison;
    return _compareTitles(a, b);
  }

  int _sortBooksByUpdatedThenTitle(Book a, Book b) {
    final dateComparison = _compareNullableDateDesc(
      a.updatedAt ?? a.startDate ?? a.createdAt,
      b.updatedAt ?? b.startDate ?? b.createdAt,
    );
    if (dateComparison != 0) return dateComparison;
    return _compareTitles(a, b);
  }

  int _sortBooksByCreatedThenTitle(Book a, Book b) {
    final dateComparison = b.createdAt.compareTo(a.createdAt);
    if (dateComparison != 0) return dateComparison;
    return _compareTitles(a, b);
  }

  int _sortSessions(ReadingSession a, ReadingSession b) {
    final dateComparison = b.date.compareTo(a.date);
    if (dateComparison != 0) return dateComparison;
    final createdComparison = b.createdAt.compareTo(a.createdAt);
    if (createdComparison != 0) return createdComparison;
    return a.id.compareTo(b.id);
  }

  int _compareNullableDateDesc(DateTime? a, DateTime? b) {
    if (a == null && b == null) return 0;
    if (a == null) return 1;
    if (b == null) return -1;
    return b.compareTo(a);
  }

  int _compareTitles(Book a, Book b) {
    final titleComparison = a.title.trim().compareTo(b.title.trim());
    if (titleComparison != 0) return titleComparison;
    return a.id.compareTo(b.id);
  }

  String _formatDateTime(DateTime date) {
    return '${_formatDate(date)} ${_twoDigits(date.hour)}:${_twoDigits(date.minute)}';
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${_twoDigits(date.month)}-${_twoDigits(date.day)}';
  }

  String _twoDigits(int value) => value.toString().padLeft(2, '0');
}
