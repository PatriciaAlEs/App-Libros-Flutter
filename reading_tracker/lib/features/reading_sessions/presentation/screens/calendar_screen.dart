import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../books/domain/entities/book.dart';
import '../../domain/entities/reading_session.dart';
import '../providers/reading_sessions_provider.dart';

enum CalendarMode { month, week }

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  CalendarMode _mode = CalendarMode.month;
  DateTime _focusedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final range = _mode == CalendarMode.month
        ? _monthRange(_focusedDate)
        : _weekRange(_focusedDate);
    final sessionsAsync = ref.watch(readingSessionsForRangeProvider(range));
    final booksById = ref.watch(booksByIdProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendario'),
        actions: [
          SegmentedButton<CalendarMode>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(value: CalendarMode.month, label: Text('Mes')),
              ButtonSegment(value: CalendarMode.week, label: Text('Semana')),
            ],
            selected: {_mode},
            onSelectionChanged: (selection) {
              setState(() => _mode = selection.first);
            },
          ),
          IconButton(
            tooltip: 'Nueva sesion',
            icon: const Icon(Icons.add),
            onPressed: () => Navigator.pushNamed(context, '/session/add'),
          ),
        ],
      ),
      body: sessionsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
        data: (sessions) {
          final sessionsByDay = _groupSessionsByDay(sessions);
          return Column(
            children: [
              _CalendarHeader(
                title: _titleFor(_focusedDate, _mode),
                onPrevious: () => setState(() {
                  _focusedDate = _mode == CalendarMode.month
                      ? DateTime(_focusedDate.year, _focusedDate.month - 1)
                      : _focusedDate.subtract(const Duration(days: 7));
                }),
                onNext: () => setState(() {
                  _focusedDate = _mode == CalendarMode.month
                      ? DateTime(_focusedDate.year, _focusedDate.month + 1)
                      : _focusedDate.add(const Duration(days: 7));
                }),
              ),
              Expanded(
                child: _mode == CalendarMode.month
                    ? _MonthCalendar(
                        focusedDate: _focusedDate,
                        sessionsByDay: sessionsByDay,
                        booksById: booksById,
                      )
                    : _WeekCalendar(
                        focusedDate: _focusedDate,
                        sessionsByDay: sessionsByDay,
                        booksById: booksById,
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  DateRange _monthRange(DateTime date) {
    final start = DateTime(date.year, date.month);
    final end = DateTime(date.year, date.month + 1);
    return DateRange(start: start, end: end);
  }

  DateRange _weekRange(DateTime date) {
    final start = _startOfWeek(date);
    return DateRange(start: start, end: start.add(const Duration(days: 7)));
  }

  DateTime _startOfWeek(DateTime date) {
    final day = DateTime(date.year, date.month, date.day);
    return day.subtract(Duration(days: day.weekday - 1));
  }

  Map<DateTime, List<ReadingSession>> _groupSessionsByDay(
    List<ReadingSession> sessions,
  ) {
    final map = <DateTime, List<ReadingSession>>{};
    for (final session in sessions) {
      final key = DateTime(
        session.date.year,
        session.date.month,
        session.date.day,
      );
      map.putIfAbsent(key, () => []).add(session);
    }
    return map;
  }

  String _titleFor(DateTime date, CalendarMode mode) {
    if (mode == CalendarMode.month) {
      return '${_monthName(date.month)} ${date.year}';
    }

    final start = _startOfWeek(date);
    final end = start.add(const Duration(days: 6));
    return '${start.day} - ${end.day} ${_monthName(end.month)} ${end.year}';
  }

  String _monthName(int month) {
    const names = [
      'Enero',
      'Febrero',
      'Marzo',
      'Abril',
      'Mayo',
      'Junio',
      'Julio',
      'Agosto',
      'Septiembre',
      'Octubre',
      'Noviembre',
      'Diciembre',
    ];
    return names[month - 1];
  }
}

class _CalendarHeader extends StatelessWidget {
  const _CalendarHeader({
    required this.title,
    required this.onPrevious,
    required this.onNext,
  });

  final String title;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        children: [
          IconButton(
            onPressed: onPrevious,
            icon: const Icon(Icons.chevron_left),
          ),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          IconButton(onPressed: onNext, icon: const Icon(Icons.chevron_right)),
        ],
      ),
    );
  }
}

class _MonthCalendar extends StatelessWidget {
  const _MonthCalendar({
    required this.focusedDate,
    required this.sessionsByDay,
    required this.booksById,
  });

  final DateTime focusedDate;
  final Map<DateTime, List<ReadingSession>> sessionsByDay;
  final Map<String, Book> booksById;

  @override
  Widget build(BuildContext context) {
    final days = _visibleMonthDays(focusedDate);
    return Column(
      children: [
        const _WeekdayHeader(),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(8),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 0.82,
            ),
            itemCount: days.length,
            itemBuilder: (context, index) {
              final day = days[index];
              return _CalendarDayCell(
                day: day,
                isMuted: day.month != focusedDate.month,
                sessions: sessionsByDay[_dateOnly(day)] ?? const [],
                booksById: booksById,
              );
            },
          ),
        ),
      ],
    );
  }

  List<DateTime> _visibleMonthDays(DateTime date) {
    final first = DateTime(date.year, date.month);
    final start = first.subtract(Duration(days: first.weekday - 1));
    return List.generate(42, (index) => start.add(Duration(days: index)));
  }

  DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);
}

class _WeekCalendar extends StatelessWidget {
  const _WeekCalendar({
    required this.focusedDate,
    required this.sessionsByDay,
    required this.booksById,
  });

  final DateTime focusedDate;
  final Map<DateTime, List<ReadingSession>> sessionsByDay;
  final Map<String, Book> booksById;

  @override
  Widget build(BuildContext context) {
    final start = _startOfWeek(focusedDate);
    final days = List.generate(7, (index) => start.add(Duration(days: index)));

    return ListView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.all(8),
      children: [
        for (final day in days)
          SizedBox(
            width: 150,
            child: _CalendarDayCell(
              day: day,
              sessions: sessionsByDay[_dateOnly(day)] ?? const [],
              booksById: booksById,
              large: true,
            ),
          ),
      ],
    );
  }

  DateTime _startOfWeek(DateTime date) {
    final day = DateTime(date.year, date.month, date.day);
    return day.subtract(Duration(days: day.weekday - 1));
  }

  DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);
}

class _WeekdayHeader extends StatelessWidget {
  const _WeekdayHeader();

  @override
  Widget build(BuildContext context) {
    const labels = ['LUN', 'MAR', 'MIE', 'JUE', 'VIE', 'SAB', 'DOM'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          for (final label in labels)
            Expanded(
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ),
        ],
      ),
    );
  }
}

class _CalendarDayCell extends StatelessWidget {
  const _CalendarDayCell({
    required this.day,
    required this.sessions,
    required this.booksById,
    this.isMuted = false,
    this.large = false,
  });

  final DateTime day;
  final List<ReadingSession> sessions;
  final Map<String, Book> booksById;
  final bool isMuted;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final books = _uniqueBooks();
    final visibleBooks = books.take(large ? 4 : 3).toList();
    final extraCount = books.length - visibleBooks.length;

    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () =>
          Navigator.pushNamed(context, '/calendar/day', arguments: day),
      child: Container(
        margin: const EdgeInsets.all(3),
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: _isToday(day)
              ? Theme.of(context).colorScheme.primaryContainer
              : Theme.of(context).colorScheme.surface,
          border: Border.all(color: Theme.of(context).dividerColor),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${day.day}',
              style: TextStyle(
                color: isMuted ? Theme.of(context).disabledColor : null,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: [
                for (final book in visibleBooks)
                  _MiniCover(url: book.coverUrl, large: large),
              ],
            ),
            const Spacer(),
            if (extraCount > 0)
              Text(
                '+$extraCount mas',
                style: Theme.of(context).textTheme.labelSmall,
              ),
          ],
        ),
      ),
    );
  }

  List<Book> _uniqueBooks() {
    final seen = <String>{};
    final books = <Book>[];
    for (final session in sessions) {
      if (!seen.add(session.bookId)) continue;
      final book = booksById[session.bookId];
      if (book != null) books.add(book);
    }
    return books;
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }
}

class _MiniCover extends StatelessWidget {
  const _MiniCover({required this.url, required this.large});

  final String? url;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final width = large ? 42.0 : 28.0;
    final height = large ? 58.0 : 40.0;
    if (url == null) {
      return Container(
        width: width,
        height: height,
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: const Icon(Icons.menu_book, size: 14),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(3),
      child: Image.network(
        url!,
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          width: width,
          height: height,
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: const Icon(Icons.menu_book, size: 14),
        ),
      ),
    );
  }
}
