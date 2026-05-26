import 'package:flutter/material.dart';

class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Progreso')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _ProgressEntryCard(
            icon: Icons.bar_chart_outlined,
            title: 'Estadisticas',
            subtitle: 'Resumen de biblioteca, rachas, ritmo y valoraciones.',
            onTap: () => Navigator.pushNamed(context, '/stats'),
          ),
          const SizedBox(height: 12),
          _ProgressEntryCard(
            icon: Icons.flag_outlined,
            title: 'Reading Challenge',
            subtitle: 'Consulta o ajusta tu objetivo anual de lectura.',
            onTap: () => Navigator.pushNamed(context, '/stats'),
          ),
          const SizedBox(height: 12),
          _ProgressEntryCard(
            icon: Icons.calendar_month_outlined,
            title: 'Activity Tracking',
            subtitle: 'Revisa el calendario y las sesiones de lectura.',
            onTap: () => Navigator.pushNamed(context, '/calendar'),
          ),
          const SizedBox(height: 12),
          _ProgressEntryCard(
            icon: Icons.add_circle_outline,
            title: 'Registrar sesion',
            subtitle: 'Anade paginas, minutos y notas a una lectura activa.',
            onTap: () => Navigator.pushNamed(context, '/session/add'),
          ),
        ],
      ),
    );
  }
}

class _ProgressEntryCard extends StatelessWidget {
  const _ProgressEntryCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Icon(icon, color: theme.colorScheme.primary),
        title: Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
