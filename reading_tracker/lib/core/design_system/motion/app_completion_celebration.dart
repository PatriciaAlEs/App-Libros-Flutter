import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../theme/app_theme_tokens.dart';
import 'app_motion.dart';

void showBookCompletionCelebration(BuildContext context) {
  final overlay = Overlay.maybeOf(context);
  if (overlay == null) return;

  late final OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) =>
        _CompletionCelebrationOverlay(onComplete: () => entry.remove()),
  );
  overlay.insert(entry);
}

class _CompletionCelebrationOverlay extends StatefulWidget {
  const _CompletionCelebrationOverlay({required this.onComplete});

  final VoidCallback onComplete;

  @override
  State<_CompletionCelebrationOverlay> createState() =>
      _CompletionCelebrationOverlayState();
}

class _CompletionCelebrationOverlayState
    extends State<_CompletionCelebrationOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<_ConfettiPiece> _pieces;

  @override
  void initState() {
    super.initState();
    _pieces = _buildPieces();
    _controller =
        AnimationController(vsync: this, duration: AppMotion.celebration)
          ..addStatusListener((status) {
            if (status == AnimationStatus.completed) {
              widget.onComplete();
            }
          });
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Positioned.fill(
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final value = Curves.easeOutCubic.transform(_controller.value);
            final fade = 1 - Curves.easeIn.transform(_controller.value);
            return CustomPaint(
              painter: _CompletionConfettiPainter(
                progress: value,
                opacity: fade.clamp(0, 1).toDouble(),
                pieces: _pieces,
                primary: theme.colorScheme.primary,
                accent: theme.colorScheme.secondary,
              ),
              child: Center(
                child: Opacity(
                  opacity: (fade * 0.9).clamp(0, 1).toDouble(),
                  child: Transform.translate(
                    offset: Offset(0, -16 * value),
                    child: Transform.scale(
                      scale: 0.96 + (0.04 * value),
                      child: child,
                    ),
                  ),
                ),
              ),
            );
          },
          child: _SuccessMark(
            background: theme.colorScheme.surface,
            color: theme.colorScheme.primary,
          ),
        ),
      ),
    );
  }
}

class _SuccessMark extends StatelessWidget {
  const _SuccessMark({required this.background, required this.color});

  final Color background;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: background.withValues(alpha: 0.96),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.20),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Icon(Icons.check_rounded, color: color, size: 34),
      ),
    );
  }
}

class _CompletionConfettiPainter extends CustomPainter {
  const _CompletionConfettiPainter({
    required this.progress,
    required this.opacity,
    required this.pieces,
    required this.primary,
    required this.accent,
  });

  final double progress;
  final double opacity;
  final List<_ConfettiPiece> pieces;
  final Color primary;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.42);
    for (final piece in pieces) {
      final travel = Offset(
        math.cos(piece.angle) * piece.distance * progress,
        math.sin(piece.angle) * piece.distance * progress +
            52 * progress * progress,
      );
      final position = center + travel;
      final paint = Paint()
        ..color = Color.lerp(
          primary,
          accent,
          piece.mix,
        )!.withValues(alpha: opacity * piece.opacity);
      canvas.save();
      canvas.translate(position.dx, position.dy);
      canvas.rotate(piece.rotation + progress * piece.spin);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset.zero,
            width: piece.width,
            height: piece.height,
          ),
          const Radius.circular(2),
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _CompletionConfettiPainter oldDelegate) {
    return progress != oldDelegate.progress || opacity != oldDelegate.opacity;
  }
}

class _ConfettiPiece {
  const _ConfettiPiece({
    required this.angle,
    required this.distance,
    required this.width,
    required this.height,
    required this.rotation,
    required this.spin,
    required this.mix,
    required this.opacity,
  });

  final double angle;
  final double distance;
  final double width;
  final double height;
  final double rotation;
  final double spin;
  final double mix;
  final double opacity;
}

List<_ConfettiPiece> _buildPieces() {
  final random = math.Random(19);
  return List.generate(28, (index) {
    final side = index.isEven ? -1 : 1;
    final angle =
        (-math.pi / 2) +
        side * (0.18 + random.nextDouble() * 0.95) +
        (random.nextDouble() - 0.5) * 0.12;
    return _ConfettiPiece(
      angle: angle,
      distance: 72 + random.nextDouble() * 118,
      width: 5 + random.nextDouble() * 6,
      height: 9 + random.nextDouble() * 10,
      rotation: random.nextDouble() * math.pi,
      spin: (random.nextDouble() * 2.2 + 1.2) * side,
      mix: random.nextDouble(),
      opacity: 0.55 + random.nextDouble() * 0.35,
    );
  });
}
