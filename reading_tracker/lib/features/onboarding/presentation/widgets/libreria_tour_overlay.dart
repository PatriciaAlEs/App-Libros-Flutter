import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/design_system/design_system.dart';

class LibreriaTourOverlay extends StatelessWidget {
  const LibreriaTourOverlay({
    super.key,
    required this.step,
    required this.targetRect,
    required this.onPrimary,
    required this.onSkip,
    required this.onDismissTemporarily,
  });

  final int step;
  final Rect targetRect;
  final VoidCallback onPrimary;
  final VoidCallback onSkip;
  final VoidCallback onDismissTemporarily;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final safeTop = media.padding.top + 12;
    final safeBottom = media.padding.bottom + 12;
    final viewport = media.size;
    final cardWidth = math.min(360.0, viewport.width - 24);
    final horizontal = (targetRect.center.dx - cardWidth / 2).clamp(
      12.0,
      math.max(12.0, viewport.width - cardWidth - 12),
    ).toDouble();
    final placeAbove = step != 1 && targetRect.center.dy > viewport.height / 2;
    final top = step == 1
        ? safeTop
        : placeAbove
        ? null
        : math.max(safeTop, targetRect.bottom + 12);
    final bottom = placeAbove
        ? math.max(safeBottom, viewport.height - targetRect.top + 12)
        : null;

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.escape):
            onDismissTemporarily,
      },
      child: Focus(
        autofocus: true,
        child: Stack(
          key: const ValueKey('libreria-tour-overlay'),
          children: [
            Positioned.fill(
              child: Semantics(
                label: 'Recorrido de novedades de LibrerIA',
                container: true,
                explicitChildNodes: true,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {},
                  child: CustomPaint(
                    key: ValueKey('libreria-tour-spotlight-$step'),
                    painter: _SpotlightPainter(
                      target: targetRect.inflate(7),
                      color: Colors.black.withValues(alpha: 0.58),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: horizontal,
              top: top,
              bottom: bottom,
              width: cardWidth,
              child: _TourCard(
                step: step,
                onPrimary: onPrimary,
                onSkip: onSkip,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TourCard extends StatelessWidget {
  const _TourCard({
    required this.step,
    required this.onPrimary,
    required this.onSkip,
  });

  final int step;
  final VoidCallback onPrimary;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = switch (step) {
      0 => '¡Nueva compañera de lecturas! ✨',
      1 => 'Habla de libros, sin invocar un grimorio',
      _ => 'Guárdala sin perder el hilo',
    };
    final description = switch (step) {
      0 =>
        'LibrerIA conoce tu biblioteca y puede ayudarte a elegir qué leer, entender tu progreso y crear un hábito.',
      1 =>
        'Pídele recomendaciones, revisa tu progreso o cuéntale tu drama lector. Ya sabe qué tienes en tu biblioteca.',
      _ =>
        'Puedes cerrar el panel y seguir a lo tuyo. Cuando vuelvas, la conversación seguirá aquí.',
    };
    final action = switch (step) {
      0 => 'Conocer a LibrerIA',
      1 => 'Siguiente',
      _ => 'Entendido',
    };

    return Material(
      key: ValueKey('libreria-tour-card-$step'),
      elevation: 18,
      color: theme.colorScheme.surface,
      shadowColor: theme.colorScheme.shadow.withValues(alpha: 0.32),
      borderRadius: BorderRadius.circular(24),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.headlineSmall?.copyWith(
                color: theme.colorScheme.primary,
                fontSize: 23,
                height: 1.08,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(description, style: theme.textTheme.bodyMedium),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: onPrimary,
                child: Text(action),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Center(
              child: TextButton(
                onPressed: onSkip,
                child: const Text('Omitir recorrido'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SpotlightPainter extends CustomPainter {
  const _SpotlightPainter({required this.target, required this.color});

  final Rect target;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final overlay = Path()..addRect(Offset.zero & size);
    final opening = Path()
      ..addRRect(RRect.fromRectAndRadius(target, const Radius.circular(22)));
    final dimmed = Path.combine(PathOperation.difference, overlay, opening);
    canvas.drawPath(dimmed, Paint()..color = color);
    canvas.drawRRect(
      RRect.fromRectAndRadius(target, const Radius.circular(22)),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.88)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(covariant _SpotlightPainter oldDelegate) =>
      oldDelegate.target != target || oldDelegate.color != color;
}
