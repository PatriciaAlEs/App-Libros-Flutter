import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design_system/design_system.dart';
import '../models/libreria_route_arguments.dart';
import '../models/libreria_view_state.dart';
import '../providers/libreria_provider.dart';
import '../widgets/libreria_limit_card.dart';

class LibreriaScreen extends ConsumerWidget {
  const LibreriaScreen({super.key, this.arguments});

  final LibreriaRouteArguments? arguments;

  static const _suggestedQuestions = <String>[
    '¿Qué estoy leyendo?',
    '¿Cuánto avancé esta semana?',
    '¿Cuál es mi racha actual?',
    '¿Cómo voy con mi objetivo anual?',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final state = ref.watch(libreriaViewStateProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          tooltip: 'Volver',
          onPressed: () => Navigator.maybePop(context),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: Text(
          'LibrerIA',
          style: theme.textTheme.titleLarge?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                theme.scaffoldBackgroundColor,
                theme.colorScheme.primaryContainer.withValues(alpha: 0.16),
                theme.scaffoldBackgroundColor,
              ],
              stops: const [0, 0.5, 1],
            ),
          ),
          child: AnimatedSwitcher(
            duration: AppMotion.normal,
            child: _bodyForState(context, state),
          ),
        ),
      ),
    );
  }

  Widget _bodyForState(BuildContext context, LibreriaViewState state) {
    return switch (state.status) {
      LibreriaViewStatus.initial => _InitialContent(
        key: const ValueKey('libreria-initial'),
        suggestedQuestions: _suggestedQuestions,
        origin: arguments?.origin,
      ),
      LibreriaViewStatus.loading => const _LoadingContent(
        key: ValueKey('libreria-loading'),
      ),
      LibreriaViewStatus.response => _MessageContent(
        key: const ValueKey('libreria-response'),
        icon: AppIcons.libreria,
        title: 'LibrerIA',
        message: state.message ?? 'Respuesta preparada.',
      ),
      LibreriaViewStatus.error => _MessageContent(
        key: const ValueKey('libreria-error'),
        icon: Icons.error_outline_rounded,
        title: 'No pudimos preparar LibrerIA',
        message:
            state.message ??
            'ReadPp sigue funcionando con normalidad. Inténtalo más tarde.',
      ),
      LibreriaViewStatus.unavailable => _MessageContent(
        key: const ValueKey('libreria-unavailable'),
        icon: Icons.cloud_off_outlined,
        title: 'LibrerIA no está disponible',
        message:
            state.message ??
            'Tus libros y sesiones siguen disponibles en ReadPp.',
      ),
    };
  }
}

class _InitialContent extends StatelessWidget {
  const _InitialContent({
    super.key,
    required this.suggestedQuestions,
    this.origin,
  });

  final List<String> suggestedQuestions;
  final String? origin;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      key: const PageStorageKey('libreria-scroll'),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.xxl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            child: Text(
              'Tu lectura, con más claridad',
              style: theme.textTheme.headlineMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w900,
                height: 1.05,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Aquí podrás entender tu progreso y encontrar el siguiente paso en tu biblioteca.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.45,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          LibreriaLimitCard(
            title: 'Tus próximos insights vivirán aquí',
            message:
                'Esta primera versión prepara la experiencia sin consultar todavía tus datos de lectura.',
            actionLabel: origin == null ? null : 'Volver a $origin',
            onAction: origin == null ? null : () => Navigator.maybePop(context),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            'Preguntas que podrás hacer',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final question in suggestedQuestions)
                ActionChip(
                  label: Text(question),
                  onPressed: null,
                  tooltip: 'Disponible próximamente',
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          Semantics(
            textField: true,
            enabled: false,
            label: 'Pregunta a LibrerIA. Disponible próximamente.',
            child: ExcludeSemantics(
              child: TextField(
                enabled: false,
                decoration: InputDecoration(
                  labelText: 'Pregunta por tu biblioteca o tu progreso',
                  helperText: 'Las preguntas estarán disponibles pronto.',
                  suffixIcon: Icon(
                    Icons.send_rounded,
                    color: theme.disabledColor,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingContent extends StatelessWidget {
  const _LoadingContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Semantics(
        label: 'Preparando LibrerIA',
        child: const CircularProgressIndicator(),
      ),
    );
  }
}

class _MessageContent extends StatelessWidget {
  const _MessageContent({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: LibreriaLimitCard(
            title: title,
            message: message,
            actionLabel: 'Volver',
            onAction: () => Navigator.maybePop(context),
          ),
        ),
      ),
    );
  }
}
