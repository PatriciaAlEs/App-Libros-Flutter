import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart';
import '../../domain/entities/coach_message.dart';
import 'coach_markdown.dart';

class CoachMessageBubble extends StatelessWidget {
  const CoachMessageBubble({
    super.key,
    required this.message,
    this.isWaiting = false,
    this.isStreaming = false,
    this.showRegenerate = false,
    this.onRegenerate,
  });

  final CoachMessage message;
  final bool isWaiting;
  final bool isStreaming;
  final bool showRegenerate;
  final VoidCallback? onRegenerate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUser = message.role == CoachMessageRole.user;
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxBubbleWidth = constraints.maxWidth * (isUser ? 0.80 : 0.82);
        final bubble = ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxBubbleWidth),
          child: _MessageEntrance(
            child: AnimatedContainer(
              duration: AppMotion.fast,
              curve: AppMotion.standard,
              margin: const EdgeInsets.only(bottom: AppSpacing.md),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: 14,
              ),
              decoration: BoxDecoration(
                color: isUser
                    ? theme.colorScheme.primaryContainer
                    : theme.colorScheme.surface.withValues(alpha: 0.96),
                borderRadius: BorderRadius.circular(22).copyWith(
                  bottomRight: isUser ? const Radius.circular(8) : null,
                  bottomLeft: isUser ? null : const Radius.circular(8),
                ),
                border: isUser
                    ? null
                    : Border.all(
                        color: theme.colorScheme.outlineVariant.withValues(
                          alpha: 0.72,
                        ),
                      ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnimatedSwitcher(
                    duration: AppMotion.fast,
                    switchInCurve: AppMotion.standard,
                    switchOutCurve: AppMotion.standard,
                    child: isWaiting
                        ? const _TypingIndicator(key: ValueKey('typing'))
                        : isUser
                        ? SelectableText(
                            message.content,
                            key: const ValueKey('user-content'),
                          )
                        : CoachMarkdown(
                            key: const ValueKey('assistant-content'),
                            data: message.content,
                          ),
                  ),
                  if (isStreaming)
                    const _StreamingCursor(
                      key: ValueKey('streaming-cursor'),
                    ),
                  if (showRegenerate) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Semantics(
                      button: true,
                      label: 'Regenerar última respuesta',
                      child: TextButton.icon(
                        onPressed: onRegenerate,
                        style: TextButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          foregroundColor: theme.colorScheme.onSurfaceVariant,
                          minimumSize: const Size(44, 44),
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                        icon: const Icon(Icons.refresh_rounded, size: 17),
                        label: const Text('Regenerar'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );

        if (isUser) {
          return Align(alignment: Alignment.centerRight, child: bubble);
        }
        return Align(
          alignment: Alignment.centerLeft,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 10, right: AppSpacing.sm),
                child: ExcludeSemantics(
                  child: Text('📚', style: TextStyle(fontSize: 22)),
                ),
              ),
              Flexible(child: bubble),
            ],
          ),
        );
      },
    );
  }
}

class _MessageEntrance extends StatefulWidget {
  const _MessageEntrance({required this.child});

  final Widget child;

  @override
  State<_MessageEntrance> createState() => _MessageEntranceState();
}

class _MessageEntranceState extends State<_MessageEntrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _offset;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppMotion.fast,
    )..forward();
    _opacity = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _offset = Tween<Offset>(
      begin: const Offset(0, 0.035),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) _controller.value = 1;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: _opacity,
    child: SlideTransition(position: _offset, child: widget.child),
  );
}

class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator({super.key});

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller
        ..stop()
        ..value = 1;
    } else if (!_controller.isAnimating) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      label: 'El Coach está escribiendo',
      child: FadeTransition(
        opacity: Tween(begin: 0.45, end: 1.0).animate(_controller),
        child: const Text('Escribiendo…'),
      ),
    );
  }
}

class _StreamingCursor extends StatefulWidget {
  const _StreamingCursor({super.key});

  @override
  State<_StreamingCursor> createState() => _StreamingCursorState();
}

class _StreamingCursorState extends State<_StreamingCursor>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    )..repeat(reverse: true);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller
        ..stop()
        ..value = 1;
    } else if (!_controller.isAnimating) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: FadeTransition(
        opacity: _controller,
        child: Text(
          '▍',
          style: TextStyle(color: Theme.of(context).colorScheme.primary),
        ),
      ),
    );
  }
}
