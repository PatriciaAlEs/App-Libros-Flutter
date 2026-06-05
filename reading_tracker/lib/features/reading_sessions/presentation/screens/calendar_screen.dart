import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../books/domain/entities/book.dart';
import '../../domain/entities/reading_session.dart';
import '../models/reading_day_activity.dart';
import '../providers/reading_sessions_provider.dart';

enum CalendarMode { month, week }

Color _activityColor(BuildContext context, ReadingActivityIntensity intensity) {
  final colorScheme = Theme.of(context).colorScheme;
  return switch (intensity) {
    ReadingActivityIntensity.none => colorScheme.surface,
    ReadingActivityIntensity.low => colorScheme.secondaryContainer,
    ReadingActivityIntensity.medium => colorScheme.tertiaryContainer,
    ReadingActivityIntensity.high => colorScheme.primaryContainer,
  };
}

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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Diario lector'),
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
            tooltip: 'Nueva sesión',
            icon: const Icon(Icons.add_rounded),
            onPressed: () => Navigator.pushNamed(context, '/session/add'),
          ),
        ],
      ),
      body: sessionsAsync.when(
        loading: () => const _CalendarLoadingState(),
        error: (error, _) => const _CalendarErrorState(),
        data: (sessions) {
          final sessionsByDay = _groupSessionsByDay(sessions);
          final activitiesByDay = ReadingDayActivity.fromSessions(sessions);
          final summary = ReadingActivitySummary.fromActivities(
            activitiesByDay.values,
          );
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
              _ActivitySummaryCard(
                title: _mode == CalendarMode.month
                    ? 'Resumen mensual'
                    : 'Resumen semanal',
                summary: summary,
              ),
              const _ActivityLegend(),
              Expanded(
                child: _mode == CalendarMode.month
                    ? _MonthCalendar(
                        focusedDate: _focusedDate,
                        sessionsByDay: sessionsByDay,
                        activitiesByDay: activitiesByDay,
                        booksById: booksById,
                      )
                    : _WeekCalendar(
                        focusedDate: _focusedDate,
                        sessionsByDay: sessionsByDay,
                        activitiesByDay: activitiesByDay,
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
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
      child: Row(
        children: [
          _RoundNavButton(icon: Icons.chevron_left, onTap: onPrevious),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          _RoundNavButton(icon: Icons.chevron_right, onTap: onNext),
        ],
      ),
    );
  }
}

class _RoundNavButton extends StatelessWidget {
  const _RoundNavButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.surface.withValues(alpha: 0.72),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 42,
          height: 42,
          child: Icon(icon, color: theme.colorScheme.primary),
        ),
      ),
    );
  }
}

class _ActivitySummaryCard extends StatelessWidget {
  const _ActivitySummaryCard({required this.title, required this.summary});

  final String title;
  final ReadingActivitySummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface.withValues(alpha: 0.78),
          borderRadius: BorderRadius.circular(26),
          border: Border.all(
            color: theme.colorScheme.primary.withValues(alpha: 0.08),
          ),
          boxShadow: AppShadows.soft(theme.colorScheme.primary),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _SummaryMetric(
                    icon: AppIcons.pages,
                    label: 'Páginas',
                    value: '${summary.pagesRead}',
                  ),
                ),
                Expanded(
                  child: _SummaryMetric(
                    icon: AppIcons.time,
                    label: 'Minutos',
                    value: '${summary.minutes}',
                  ),
                ),
                Expanded(
                  child: _SummaryMetric(
                    icon: AppIcons.calendar,
                    label: 'Días',
                    value: '${summary.activeDays}',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryMetric extends StatelessWidget {
  const _SummaryMetric({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: theme.colorScheme.primary, size: 18),
        const SizedBox(height: 6),
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.primary.withValues(alpha: 0.70),
          ),
        ),
      ],
    );
  }
}

class _ActivityLegend extends StatelessWidget {
  const _ActivityLegend();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      child: Wrap(
        spacing: 12,
        runSpacing: 8,
        children: const [
          _LegendItem(
            label: 'Sin actividad',
            intensity: ReadingActivityIntensity.none,
          ),
          _LegendItem(label: 'Baja', intensity: ReadingActivityIntensity.low),
          _LegendItem(
            label: 'Media',
            intensity: ReadingActivityIntensity.medium,
          ),
          _LegendItem(label: 'Alta', intensity: ReadingActivityIntensity.high),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.label, required this.intensity});

  final String label;
  final ReadingActivityIntensity intensity;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: _activityColor(context, intensity),
            border: Border.all(color: Theme.of(context).dividerColor),
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _MonthCalendar extends StatelessWidget {
  const _MonthCalendar({
    required this.focusedDate,
    required this.sessionsByDay,
    required this.activitiesByDay,
    required this.booksById,
  });

  final DateTime focusedDate;
  final Map<DateTime, List<ReadingSession>> sessionsByDay;
  final Map<DateTime, ReadingDayActivity> activitiesByDay;
  final Map<String, Book> booksById;

  @override
  Widget build(BuildContext context) {
    final days = _visibleMonthDays(focusedDate);
    return Column(
      children: [
        const _WeekdayHeader(),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 0.72,
              mainAxisSpacing: 4,
              crossAxisSpacing: 4,
            ),
            itemCount: days.length,
            itemBuilder: (context, index) {
              final day = days[index];
              return _CalendarDayCell(
                day: day,
                isMuted: day.month != focusedDate.month,
                sessions: sessionsByDay[_dateOnly(day)] ?? const [],
                activity: activitiesByDay[_dateOnly(day)],
                booksById: booksById,
                compact: true,
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
    required this.activitiesByDay,
    required this.booksById,
  });

  final DateTime focusedDate;
  final Map<DateTime, List<ReadingSession>> sessionsByDay;
  final Map<DateTime, ReadingDayActivity> activitiesByDay;
  final Map<String, Book> booksById;

  @override
  Widget build(BuildContext context) {
    final start = _startOfWeek(focusedDate);
    final days = List.generate(7, (index) => start.add(Duration(days: index)));
    final hasSessions = days.any(
      (day) => (sessionsByDay[_dateOnly(day)] ?? const []).isNotEmpty,
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
      children: [
        if (!hasSessions) const _WeekEmptyState(),
        for (final day in days)
          _WeekDaySection(
            day: day,
            sessions: sessionsByDay[_dateOnly(day)] ?? const [],
            activity: activitiesByDay[_dateOnly(day)],
            booksById: booksById,
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

class _WeekEmptyState extends StatelessWidget {
  const _WeekEmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 12),
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        children: [
          Icon(AppIcons.calendar, color: theme.colorScheme.primary),
          const SizedBox(height: 10),
          Text(
            'Semana sin sesiones',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Registra una lectura para encender el calendario.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _CalendarLoadingState extends StatelessWidget {
  const _CalendarLoadingState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            height: 78,
            decoration: BoxDecoration(
              color: theme.colorScheme.surface.withValues(alpha: 0.70),
              borderRadius: BorderRadius.circular(22),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            height: 120,
            decoration: BoxDecoration(
              color: theme.colorScheme.surface.withValues(alpha: 0.56),
              borderRadius: BorderRadius.circular(22),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surface.withValues(alpha: 0.44),
                borderRadius: BorderRadius.circular(22),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CalendarErrorState extends StatelessWidget {
  const _CalendarErrorState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          'No pudimos cargar tu calendario lector. Inténtalo de nuevo en unos segundos.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium,
        ),
      ),
    );
  }
}

class _WeekDaySection extends StatelessWidget {
  const _WeekDaySection({
    required this.day,
    required this.sessions,
    required this.activity,
    required this.booksById,
  });

  final DateTime day;
  final List<ReadingSession> sessions;
  final ReadingDayActivity? activity;
  final Map<String, Book> booksById;

  @override
  Widget build(BuildContext context) {
    final activity = this.activity;
    final totalPages = activity?.pagesRead ?? 0;
    final totalMinutes = activity?.minutes ?? 0;
    final intensity = activity?.intensity ?? ReadingActivityIntensity.none;

    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _activityColor(context, intensity).withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(
            alpha: intensity == ReadingActivityIntensity.none ? 0.06 : 0.14,
          ),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: () =>
              Navigator.pushNamed(context, '/calendar/day', arguments: day),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _dayTitle(day),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    if (totalPages > 0 || totalMinutes > 0)
                      _ActivityBadge(
                        label: _activityValue(totalPages, totalMinutes),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                if (sessions.isEmpty)
                  Text('Sin sesiones', style: theme.textTheme.bodySmall)
                else
                  for (final session in sessions)
                    _WeekSessionRow(
                      session: session,
                      book: booksById[session.bookId],
                    ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _activityValue(int pagesRead, int minutes) {
    final parts = <String>[
      if (pagesRead > 0) '$pagesRead pag.',
      if (minutes > 0) '$minutes min',
    ];
    return parts.join(' · ');
  }

  String _dayTitle(DateTime date) {
    const weekdays = [
      'Lunes',
      'Martes',
      'Miércoles',
      'Jueves',
      'Viernes',
      'Sábado',
      'Domingo',
    ];
    return '${weekdays[date.weekday - 1]} ${date.day}/${date.month}';
  }
}

class _ActivityBadge extends StatelessWidget {
  const _ActivityBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondary.withValues(alpha: 0.24),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _WeekSessionRow extends StatelessWidget {
  const _WeekSessionRow({required this.session, required this.book});

  final ReadingSession session;
  final Book? book;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          _MiniCover(url: book?.coverUrl, width: 34, height: 48),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              book?.title ?? 'Libro no encontrado',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          const SizedBox(width: 8),
          Text(_sessionValue(), style: Theme.of(context).textTheme.labelLarge),
        ],
      ),
    );
  }

  String _sessionValue() {
    final parts = <String>[
      if (session.pagesRead > 0) '${session.pagesRead} pag.',
      if (session.minutes > 0) '${session.minutes} min',
    ];
    return parts.isEmpty ? '-' : parts.join(' · ');
  }
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
    required this.activity,
    required this.booksById,
    this.isMuted = false,
    this.compact = false,
  });

  final DateTime day;
  final List<ReadingSession> sessions;
  final ReadingDayActivity? activity;
  final Map<String, Book> booksById;
  final bool isMuted;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final books = _uniqueBooks();
    final maxCovers = compact ? 2 : 3;
    final visibleBooks = books.take(maxCovers).toList();
    final extraCount = books.length - visibleBooks.length;
    final coverWidth = compact ? 16.0 : 28.0;
    final coverHeight = compact ? 22.0 : 40.0;
    final intensity = activity?.intensity ?? ReadingActivityIntensity.none;
    final totalPages = activity?.pagesRead ?? 0;
    final totalMinutes = activity?.minutes ?? 0;
    final isToday = _isToday(day);

    final theme = Theme.of(context);
    final hasActivity = totalPages > 0 || totalMinutes > 0;

    return InkWell(
      borderRadius: BorderRadius.circular(compact ? 14 : 18),
      onTap: () =>
          Navigator.pushNamed(context, '/calendar/day', arguments: day),
      child: AnimatedContainer(
        duration: AppMotion.fast,
        curve: AppMotion.standard,
        padding: EdgeInsets.all(compact ? 5 : 7),
        decoration: BoxDecoration(
          color: _activityColor(
            context,
            intensity,
          ).withValues(alpha: hasActivity ? 0.92 : 0.58),
          border: Border.all(
            color: isToday
                ? theme.colorScheme.primary
                : theme.colorScheme.primary.withValues(
                    alpha: hasActivity ? 0.16 : 0.06,
                  ),
            width: isToday ? 1.6 : 1,
          ),
          borderRadius: BorderRadius.circular(compact ? 14 : 18),
          boxShadow: hasActivity && !compact
              ? AppShadows.editorial(theme.colorScheme.primary)
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: compact ? 18 : 22,
              child: Text(
                '${day.day}',
                maxLines: 1,
                style: TextStyle(
                  color: isMuted
                      ? theme.colorScheme.onSurface.withValues(alpha: 0.34)
                      : theme.colorScheme.onSurface,
                  fontSize: compact ? 12 : null,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(height: 2),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _MiniCoverRow(
                    books: visibleBooks,
                    extraCount: extraCount,
                    coverWidth: coverWidth,
                    coverHeight: coverHeight,
                    compact: compact,
                  ),
                  const Spacer(),
                  if (totalPages > 0 || totalMinutes > 0)
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: compact ? 5 : 7,
                        vertical: compact ? 2 : 4,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface.withValues(
                          alpha: 0.72,
                        ),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        _activityLabel(totalPages, totalMinutes),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontSize: compact ? 9 : null,
                          fontWeight: FontWeight.w900,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                ],
              ),
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

  String _activityLabel(int pagesRead, int minutes) {
    if (pagesRead > 0) return '$pagesRead pag.';
    return '$minutes min';
  }
}

class _MiniCoverRow extends StatelessWidget {
  const _MiniCoverRow({
    required this.books,
    required this.extraCount,
    required this.coverWidth,
    required this.coverHeight,
    required this.compact,
  });

  final List<Book> books;
  final int extraCount;
  final double coverWidth;
  final double coverHeight;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (books.isEmpty && extraCount <= 0) {
      return const SizedBox.shrink();
    }

    return FittedBox(
      alignment: Alignment.topLeft,
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final book in books) ...[
            _MiniCover(
              url: book.coverUrl,
              width: coverWidth,
              height: coverHeight,
            ),
            SizedBox(width: compact ? 2 : 4),
          ],
          if (extraCount > 0)
            _ExtraCountBadge(count: extraCount, compact: compact),
        ],
      ),
    );
  }
}

class _ExtraCountBadge extends StatelessWidget {
  const _ExtraCountBadge({required this.count, required this.compact});

  final int count;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: compact ? 20 : 24,
      padding: EdgeInsets.symmetric(horizontal: compact ? 5 : 7),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      alignment: Alignment.center,
      child: Text(
        '+$count',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          fontSize: compact ? 10 : null,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _MiniCover extends StatelessWidget {
  const _MiniCover({
    required this.url,
    required this.width,
    required this.height,
  });

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
