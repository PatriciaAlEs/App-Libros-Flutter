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
    '¿Cómo voy con mi objetivo anual?',
    '¿Qué patrón tiene mi lectura esta semana?',
    '¿Qué libro conviene retomar primero?',
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
        title: 'LibrerIA',
        message: state.message ?? 'Respuesta preparada.',
      ),
      LibreriaViewStatus.error => _MessageContent(
        key: const ValueKey('libreria-error'),
        title: 'No pudimos preparar LibrerIA',
        message:
            state.message ??
            'ReadPp sigue funcionando con normalidad. Inténtalo más tarde.',
      ),
      LibreriaViewStatus.unavailable => _MessageContent(
        key: const ValueKey('libreria-unavailable'),
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
              'LibrerIA',
              style: theme.textTheme.headlineMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w900,
                height: 1.05,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Tu coach de lectura dentro de ReadPp: un espacio para entender tu progreso, detectar hábitos y preparar mejores decisiones lectoras.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.45,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          LibreriaLimitCard(
            title: 'Bienvenida a LibrerIA',
            message:
                'Estamos preparando una experiencia especializada en tu biblioteca. En este MVP inicial no consulta datos ni genera respuestas todavía.',
            actionLabel: origin == null ? null : 'Volver a $origin',
            onAction: origin == null ? null : () => Navigator.maybePop(context),
          ),
          const SizedBox(height: AppSpacing.xl),
          const _CoachPreparationCard(),
          const SizedBox(height: AppSpacing.xl),
          Text(
            'Ejemplos de futuras preguntas',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Column(
            children: [
              for (final question in suggestedQuestions)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: _FutureQuestionTile(question: question),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CoachPreparationCard extends StatelessWidget {
  const _CoachPreparationCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      container: true,
      label:
          'Estado de LibrerIA. Preparando coach de lectura. Sin chat ni inteligencia artificial activa todavía.',
      child: ReadPpSurface(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withValues(
                  alpha: 0.72,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                AppIcons.libreria,
                color: theme.colorScheme.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Preparando coach de lectura',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'La base visual ya está lista. Las respuestas, datos reales y herramientas llegarán en siguientes pasos del sprint.',
                    style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FutureQuestionTile extends StatelessWidget {
  const _FutureQuestionTile({required this.question});

  final String question;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      label: 'Ejemplo no funcional: $question',
      child: ExcludeSemantics(
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.md,
          ),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface.withValues(alpha: 0.88),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: theme.colorScheme.primary.withValues(alpha: 0.08),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.auto_awesome_outlined,
                color: theme.colorScheme.primary.withValues(alpha: 0.76),
                size: 19,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  question,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Próximamente',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
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
    required this.title,
    required this.message,
  });

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
