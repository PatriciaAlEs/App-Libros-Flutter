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
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: AnimatedContainer(
        duration: AppMotion.normal,
        constraints: const BoxConstraints(maxWidth: 720),
        margin: EdgeInsets.only(
          left: isUser ? 42 : 0,
          right: isUser ? 0 : 24,
          bottom: AppSpacing.md,
        ),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: isUser
              ? theme.colorScheme.primaryContainer
              : theme.colorScheme.surface.withValues(alpha: 0.94),
          borderRadius: BorderRadius.circular(20).copyWith(
            bottomRight: isUser ? const Radius.circular(6) : null,
            bottomLeft: isUser ? null : const Radius.circular(6),
          ),
          border: isUser
              ? null
              : Border.all(
                  color: theme.colorScheme.primary.withValues(alpha: 0.12),
                ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedSwitcher(
              duration: AppMotion.normal,
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
              const _StreamingCursor(key: ValueKey('streaming-cursor')),
            if (showRegenerate) ...[
              const SizedBox(height: AppSpacing.sm),
              Semantics(
                button: true,
                label: 'Regenerar última respuesta',
                child: TextButton.icon(
                  onPressed: onRegenerate,
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Regenerar'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
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
