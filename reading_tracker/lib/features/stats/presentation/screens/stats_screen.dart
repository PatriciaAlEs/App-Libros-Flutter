import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/stats_provider.dart';
import '../widgets/stat_card.dart';

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(statsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Estadísticas')),
      body: statsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
        data: (stats) {
          if (stats.totalBooks == 0) {
            return const Center(
              child: Text(
                'No hay datos para mostrar. Añade libros o sesiones para ver estadísticas.',
                textAlign: TextAlign.center,
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionTitle(context, 'Resumen'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    StatCard(
                      icon: Icons.book_outlined,
                      title: 'Libros totales',
                      value: '${stats.totalBooks}',
                    ),
                    StatCard(
                      icon: Icons.schedule,
                      title: 'Pendientes',
                      value: '${stats.pendingBooks}',
                    ),
                    StatCard(
                      icon: Icons.auto_stories,
                      title: 'En lectura',
                      value: '${stats.readingBooks}',
                    ),
                    StatCard(
                      icon: Icons.check_circle_outline,
                      title: 'Completados',
                      value: '${stats.completedBooks}',
                      subtitle: '${stats.completedRate.toStringAsFixed(0)}% completado',
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _sectionTitle(context, 'Progreso'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    StatCard(
                      icon: Icons.stacked_line_chart,
                      title: 'Páginas leídas',
                      value: '${stats.pagesRead}',
                    ),
                    StatCard(
                      icon: Icons.percent,
                      title: 'Progreso medio',
                      value: '${stats.averageReadingProgress.toStringAsFixed(0)}%',
                    ),
                    StatCard(
                      icon: Icons.calendar_month,
                      title: 'Terminados este mes',
                      value: '${stats.booksCompletedThisMonth}',
                    ),
                    StatCard(
                      icon: Icons.calendar_today,
                      title: 'Añadidos este mes',
                      value: '${stats.booksAddedThisMonth}',
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _sectionTitle(context, 'Tiempo de lectura'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    StatCard(
                      icon: Icons.timer,
                      title: 'Minutos leídos',
                      value: '${stats.totalMinutesRead}',
                    ),
                    StatCard(
                      icon: Icons.access_time,
                      title: 'Horas leídas',
                      value: stats.totalHoursRead.toStringAsFixed(1),
                    ),
                    StatCard(
                      icon: Icons.show_chart,
                      title: 'Media diaria',
                      value: stats.averageDailyMinutes.toStringAsFixed(0),
                    ),
                    StatCard(
                      icon: Icons.calendar_view_day,
                      title: 'Días con actividad',
                      value: '${stats.daysWithActivity}',
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    StatCard(
                      icon: Icons.emoji_events,
                      title: 'Mejor día',
                      value: stats.bestDay != null
                          ? '${stats.bestDay!.day}/${stats.bestDay!.month}/${stats.bestDay!.year}'
                          : '-',
                      subtitle: stats.bestDayMinutes > 0
                          ? '${stats.bestDayMinutes} min'
                          : null,
                    ),
                    StatCard(
                      icon: Icons.whatshot,
                      title: 'Racha actual',
                      value: '${stats.currentStreakDays} días',
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _sectionTitle(context, 'Rankings'),
                const SizedBox(height: 8),
                _rankingCard(
                  title: 'Mejor valorados',
                  items: stats.topRatedBooks,
                  itemBuilder: (book) => '${book.title} ${book.rating.toStringAsFixed(1)}',
                  emptyMessage: 'No hay libros valorados aún.',
                ),
                const SizedBox(height: 12),
                _rankingCard(
                  title: 'Autores más leídos',
                  items: stats.topAuthors,
                  itemBuilder: (author) =>
                      '${author.author} · ${author.minutes} min · ${author.bookCount} libros',
                  emptyMessage: 'Sin datos de autores todavía.',
                ),
                const SizedBox(height: 12),
                _rankingCard(
                  title: 'Más tiempo dedicado',
                  items: stats.topBooksByTime,
                  itemBuilder: (book) =>
                      '${book.title} · ${book.minutes} min',
                  emptyMessage: stats.hasSessionData
                      ? 'No hay suficiente información para este ranking.'
                      : 'Añade sesiones de lectura para ver el ranking.',
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
    );
  }

  Widget _rankingCard<T>({
    required String title,
    required List<T> items,
    required String Function(T item) itemBuilder,
    required String emptyMessage,
  }) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (items.isEmpty)
              Text(emptyMessage)
            else
              Column(
                children: items
                    .take(5)
                    .map((item) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('• ', style: TextStyle(fontSize: 16)),
                              Expanded(child: Text(itemBuilder(item))),
                            ],
                          ),
                        ))
                    .toList(),
              ),
          ],
        ),
      ),
    );
  }
}
