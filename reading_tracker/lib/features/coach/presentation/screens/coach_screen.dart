import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design_system/design_system.dart';
import '../../domain/providers/reader_context_provider.dart';
import '../controllers/coach_controller.dart';
import '../widgets/coach_message_bubble.dart';

class CoachScreen extends ConsumerStatefulWidget {
  const CoachScreen({
    super.key,
    this.isFloatingPanel = false,
    this.onCollapse,
    this.conversationTargetKey,
    this.collapseTargetKey,
  });

  final bool isFloatingPanel;
  final VoidCallback? onCollapse;
  final GlobalKey? conversationTargetKey;
  final GlobalKey? collapseTargetKey;

  @override
  ConsumerState<CoachScreen> createState() => _CoachScreenState();
}

class _CoachScreenState extends ConsumerState<CoachScreen> {
  static const _bottomThreshold = 80.0;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _followTail = true;
  bool _scrollScheduled = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<CoachControllerState>(coachControllerProvider, (previous, next) {
      if (_followTail &&
          (previous?.messages.length != next.messages.length ||
              previous?.messages.lastOrNull?.content !=
                  next.messages.lastOrNull?.content)) {
        _scheduleScrollToEnd();
      }
    });
    final uiState = ref.watch(
      coachControllerProvider.select(
        (state) => (
          messageCount: state.messages.length,
          isLoading: state.isLoading,
          errorMessage: state.errorMessage,
          canRetry: state.canRetry,
        ),
      ),
    );
    final theme = Theme.of(context);

    final chatBody = _buildChatBody(uiState);
    if (widget.isFloatingPanel) {
      return Column(
        children: [
          _CoachPanelHeader(
            onNewConversation: () => ref
                .read(coachControllerProvider.notifier)
                .startNewConversation(),
            onShowHistory: () =>
                _showConversationHistory(ref.read(coachControllerProvider)),
            onCollapse: widget.onCollapse,
            collapseTargetKey: widget.collapseTargetKey,
          ),
          Expanded(child: chatBody),
          Padding(
            key: const ValueKey('libreria-disclaimer'),
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              0,
              AppSpacing.md,
              AppSpacing.sm,
            ),
            child: Text(
              'LibrerIA puede equivocarse. Contrasta los datos importantes.',
              textAlign: TextAlign.center,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.primary.withValues(alpha: 0.62),
                fontSize: 11,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      );
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        titleSpacing: AppSpacing.lg,
        title: Row(
          children: [
            _LibreriaMark(color: theme.colorScheme.primary),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'LibrerIA',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w800,
                      fontSize: 23,
                      height: 1,
                    ),
                  ),
                  Text(
                    'Tu asistente de lectura',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        centerTitle: false,
        actions: [
          IconButton(
            tooltip: 'Nueva conversación',
            onPressed: () => ref
                .read(coachControllerProvider.notifier)
                .startNewConversation(),
            icon: const Icon(Icons.add_comment_outlined),
          ),
          IconButton(
            tooltip: 'Historial de conversaciones',
            onPressed: () =>
                _showConversationHistory(ref.read(coachControllerProvider)),
            icon: const Icon(Icons.history),
          ),
        ],
      ),
      body: chatBody,
    );
  }

  Widget _buildChatBody(
    ({
      int messageCount,
      bool isLoading,
      String? errorMessage,
      bool canRetry,
    })
    uiState,
  ) {
    return ColoredBox(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: SafeArea(
        top: false,
        bottom: !widget.isFloatingPanel,
        child: Column(
          children: [
            Expanded(
              child: KeyedSubtree(
                key: widget.conversationTargetKey,
                child: Stack(
                  key: const ValueKey('coach-conversation-area'),
                  children: [
                  if (uiState.messageCount == 0)
                    _CoachEmptyState(onSuggestion: _sendSuggestion)
                  else
                    NotificationListener<ScrollNotification>(
                      onNotification: _handleScrollNotification,
                      child: ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.fromLTRB(
                          18,
                          AppSpacing.md,
                          18,
                          32,
                        ),
                        itemCount: uiState.messageCount,
                        itemBuilder: (context, index) {
                          return _CoachMessageItem(
                            key: ValueKey('coach-message-position-$index'),
                            index: index,
                          );
                        },
                      ),
                    ),
                  Positioned(
                    right: AppSpacing.lg,
                    bottom: AppSpacing.md,
                    child: AnimatedSwitcher(
                      duration: _motionDuration(context),
                      child: _followTail
                          ? const SizedBox.shrink(
                              key: ValueKey('scroll-bottom-hidden'),
                            )
                          : Semantics(
                              key: const ValueKey('scroll-bottom'),
                              button: true,
                              label: 'Volver al final de la conversación',
                              child: FloatingActionButton.small(
                                heroTag: 'coach-scroll-bottom',
                                onPressed: _scrollToEnd,
                                child: const Icon(Icons.keyboard_arrow_down),
                              ),
                            ),
                    ),
                  ),
                  ],
                ),
              ),
            ),
            if (uiState.errorMessage != null)
              _CoachErrorBanner(
                message: uiState.errorMessage!,
                onRetry: uiState.canRetry
                    ? () => ref
                          .read(coachControllerProvider.notifier)
                          .retryLastResponse()
                    : null,
              ),
            _CoachComposer(
              controller: _textController,
              focusNode: _focusNode,
              isGenerating: uiState.isLoading,
              useBottomSafeArea: !widget.isFloatingPanel,
              onSend: _sendComposerMessage,
              onStop: () =>
                  ref.read(coachControllerProvider.notifier).cancelGeneration(),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendComposerMessage() async {
    final message = _textController.text;
    if (message.trim().isEmpty) {
      return;
    }
    _textController.clear();
    await _send(message);
  }

  Future<void> _sendSuggestion(String suggestion) => _send(suggestion);

  Future<void> _send(String message) async {
    try {
      final readerContext = await ref.read(readerContextProvider.future);
      if (!mounted) {
        return;
      }
      _followTail = true;
      await ref
          .read(coachControllerProvider.notifier)
          .sendMessage(userMessage: message, readerContext: readerContext);
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo preparar el contexto lector.'),
        ),
      );
    }
  }

  Future<void> _showConversationHistory(CoachControllerState state) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            ListTile(
              leading: const Icon(Icons.add_comment_outlined),
              title: const Text('Nueva conversación'),
              onTap: () {
                Navigator.pop(sheetContext);
                ref
                    .read(coachControllerProvider.notifier)
                    .startNewConversation();
              },
            ),
            if (state.conversations.isEmpty)
              const Padding(
                padding: EdgeInsets.all(AppSpacing.xl),
                child: Text('Todavía no hay conversaciones guardadas.'),
              ),
            for (final conversation in state.conversations)
              ListTile(
                selected: conversation.id == state.activeConversation?.id,
                leading: const Icon(Icons.chat_bubble_outline),
                title: Text(conversation.title),
                subtitle: Text(
                  _formatConversationDate(conversation.lastMessageAt),
                ),
                onTap: () {
                  Navigator.pop(sheetContext);
                  ref
                      .read(coachControllerProvider.notifier)
                      .openConversation(conversation.id);
                },
                trailing: IconButton(
                  tooltip: 'Eliminar ${conversation.title}',
                  onPressed: () => _confirmDeleteConversation(
                    sheetContext,
                    conversation.id,
                    conversation.title,
                  ),
                  icon: const Icon(Icons.delete_outline),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDeleteConversation(
    BuildContext sheetContext,
    String id,
    String title,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminar conversación'),
        content: Text('¿Quieres eliminar “$title” y todos sus mensajes?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) {
      return;
    }
    if (sheetContext.mounted) {
      Navigator.pop(sheetContext);
    }
    await ref.read(coachControllerProvider.notifier).deleteConversation(id);
  }

  String _formatConversationDate(DateTime date) {
    final local = date.toLocal();
    return '${local.day.toString().padLeft(2, '0')}/'
        '${local.month.toString().padLeft(2, '0')}/${local.year}';
  }

  bool _handleScrollNotification(ScrollNotification notification) {
    if (!mounted ||
        notification.depth != 0 ||
        notification is! ScrollUpdateNotification ||
        notification.dragDetails == null) {
      return false;
    }
    final distance =
        notification.metrics.maxScrollExtent - notification.metrics.pixels;
    final shouldFollow = distance <= _bottomThreshold;
    if (shouldFollow != _followTail) {
      setState(() => _followTail = shouldFollow);
    }
    return false;
  }

  void _scheduleScrollToEnd() {
    if (_scrollScheduled) {
      return;
    }
    _scrollScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollScheduled = false;
      if (!mounted || !_followTail || !_scrollController.hasClients) {
        return;
      }
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: _motionDuration(context),
        curve: AppMotion.standard,
      );
    });
  }

  void _scrollToEnd() {
    if (!_scrollController.hasClients) {
      return;
    }
    setState(() => _followTail = true);
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: _motionDuration(context),
      curve: AppMotion.standard,
    );
  }

  Duration _motionDuration(BuildContext context) =>
      MediaQuery.disableAnimationsOf(context)
      ? Duration.zero
      : AppMotion.normal;
}

enum _CoachPanelAction { newConversation, history }

class _CoachPanelHeader extends StatelessWidget {
  const _CoachPanelHeader({
    required this.onNewConversation,
    required this.onShowHistory,
    required this.onCollapse,
    this.collapseTargetKey,
  });

  final VoidCallback onNewConversation;
  final VoidCallback onShowHistory;
  final VoidCallback? onCollapse;
  final GlobalKey? collapseTargetKey;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.48),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.sm,
          AppSpacing.md,
        ),
        child: Row(
          children: [
          _LibreriaMark(
            color: theme.colorScheme.primary,
            size: 40,
            iconSize: 18,
            showShadow: true,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'LibrerIA',
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w800,
                    fontSize: 22,
                    height: 1,
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: Color(0xFF2EAD68),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Flexible(
                      child: Text(
                        'Tu asistente de lectura',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.primary.withValues(
                            alpha: 0.76,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          PopupMenuButton<_CoachPanelAction>(
            tooltip: 'Acciones de LibrerIA',
            onSelected: (action) {
              switch (action) {
                case _CoachPanelAction.newConversation:
                  onNewConversation();
                  return;
                case _CoachPanelAction.history:
                  onShowHistory();
                  return;
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: _CoachPanelAction.newConversation,
                child: Semantics(
                  button: true,
                  label: 'Nueva conversacion',
                  child: const Text('Nueva conversacion'),
                ),
              ),
              PopupMenuItem(
                value: _CoachPanelAction.history,
                child: Semantics(
                  button: true,
                  label: 'Historial de conversaciones',
                  child: const Text('Historial'),
                ),
              ),
            ],
            icon: const Icon(Icons.more_horiz),
          ),
          KeyedSubtree(
            key: collapseTargetKey,
            child: Semantics(
              button: true,
              label: 'Colapsar LibrerIA',
              child: IconButton(
              key: const ValueKey('collapse-libreria'),
              tooltip: 'Colapsar LibrerIA',
              onPressed: onCollapse,
              style: IconButton.styleFrom(
                backgroundColor: theme.colorScheme.surface.withValues(
                  alpha: 0.58,
                ),
                foregroundColor: theme.colorScheme.primary,
              ),
              icon: const Icon(Icons.keyboard_arrow_down_rounded),
              ),
            ),
          ),
          ],
        ),
      ),
    );
  }
}

class _CoachMessageItem extends ConsumerWidget {
  const _CoachMessageItem({super.key, required this.index});

  final int index;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final item = ref.watch(
      coachControllerProvider.select((state) {
        if (index >= state.messages.length) return null;
        final message = state.messages[index];
        final isActive = state.activeAssistantIndex == index;
        return (
          message: message,
          isWaiting: isActive && state.isWaitingFirstChunk,
          isStreaming: isActive && state.hasPartialResponse,
          showRegenerate:
              index == state.messages.length - 1 && state.canRegenerate,
        );
      }),
    );
    if (item == null) return const SizedBox.shrink();
    return CoachMessageBubble(
      key: ValueKey('coach-message-${item.message.id}'),
      message: item.message,
      isWaiting: item.isWaiting,
      isStreaming: item.isStreaming,
      showRegenerate: item.showRegenerate,
      onRegenerate: () =>
          ref.read(coachControllerProvider.notifier).regenerateLastResponse(),
    );
  }
}

class _CoachEmptyState extends StatelessWidget {
  const _CoachEmptyState({required this.onSuggestion});

  static const suggestions = [
    'Recomiéndame un libro',
    'Resume mi progreso de lectura',
    'Ayúdame a crear un hábito',
  ];

  final ValueChanged<String> onSuggestion;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.xl,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      children: [
        Center(
          child: _LibreriaMark(
            color: theme.colorScheme.primary,
            size: 44,
            iconSize: 21,
            showShadow: true,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          '¿Sobre qué quieres leer hoy?',
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
            fontSize: 24,
            height: 1.1,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Explora nuevas lecturas, comprende tu progreso y construye un hábito a tu ritmo.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            height: 1.45,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        for (final suggestion in suggestions)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Semantics(
              button: true,
              label: suggestion,
              child: OutlinedButton(
                onPressed: () => onSuggestion(suggestion),
                style: OutlinedButton.styleFrom(
                  alignment: Alignment.centerLeft,
                  minimumSize: const Size.fromHeight(48),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.arrow_outward_rounded,
                      size: 18,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(child: Text(suggestion)),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _CoachErrorBanner extends StatelessWidget {
  const _CoachErrorBanner({required this.message, this.onRetry});
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: colors.errorContainer,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: colors.onErrorContainer),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(message)),
          if (onRetry != null)
            Semantics(
              button: true,
              label: 'Reintentar respuesta',
              child: TextButton(
                onPressed: onRetry,
                child: const Text('Reintentar'),
              ),
            ),
        ],
      ),
    );
  }
}

class _CoachComposer extends StatelessWidget {
  const _CoachComposer({
    required this.controller,
    required this.focusNode,
    required this.isGenerating,
    required this.useBottomSafeArea,
    required this.onSend,
    required this.onStop,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isGenerating;
  final bool useBottomSafeArea;
  final VoidCallback onSend;
  final VoidCallback onStop;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      key: const ValueKey('coach-composer'),
      top: false,
      bottom: useBottomSafeArea,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.sm,
          AppSpacing.md,
          AppSpacing.sm,
        ),
        child: Material(
          color: theme.colorScheme.primaryContainer.withValues(alpha: 0.22),
          elevation: 0,
          shadowColor: theme.colorScheme.shadow.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(28),
          child: Container(
            constraints: const BoxConstraints(minHeight: 54),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: theme.colorScheme.primary.withValues(alpha: 0.20),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Focus(
                    onKeyEvent: (_, event) {
                      if (event is! KeyDownEvent ||
                          event.logicalKey != LogicalKeyboardKey.enter) {
                        return KeyEventResult.ignored;
                      }
                      if (HardwareKeyboard.instance.isShiftPressed) {
                        _insertNewLine(controller);
                      } else if (!isGenerating &&
                          controller.text.trim().isNotEmpty) {
                        onSend();
                      }
                      return KeyEventResult.handled;
                    },
                    child: TextField(
                      controller: controller,
                      focusNode: focusNode,
                      minLines: 1,
                      maxLines: 4,
                      scrollPadding: const EdgeInsets.only(bottom: 96),
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) {
                        if (!isGenerating &&
                            controller.text.trim().isNotEmpty) {
                          onSend();
                        }
                      },
                      decoration: const InputDecoration(
                      hintText: 'Escribe sobre tus lecturas…',
                      filled: false,
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: 15,
                      ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(7),
                  child: ValueListenableBuilder<TextEditingValue>(
                    valueListenable: controller,
                    builder: (context, value, _) => AnimatedSwitcher(
                      duration: AppMotion.fast,
                      switchInCurve: AppMotion.standard,
                      switchOutCurve: AppMotion.standard,
                      transitionBuilder: (child, animation) =>
                          ScaleTransition(scale: animation, child: child),
                      child: isGenerating
                          ? Semantics(
                              key: const ValueKey('composer-stop-state'),
                              button: true,
                              label: 'Detener respuesta',
                              child: IconButton.filledTonal(
                                key: const ValueKey('stop'),
                                tooltip: 'Detener respuesta',
                                onPressed: onStop,
                                icon: const Icon(Icons.stop_rounded),
                              ),
                            )
                          : Semantics(
                              key: const ValueKey('composer-send-state'),
                              button: true,
                              label: 'Enviar mensaje',
                              child: IconButton.filled(
                                key: const ValueKey('send'),
                                tooltip: 'Enviar mensaje',
                                onPressed: value.text.trim().isEmpty
                                    ? null
                                    : onSend,
                                icon: const Icon(Icons.send_rounded, size: 20),
                              ),
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static void _insertNewLine(TextEditingController controller) {
    final value = controller.value;
    final selection = value.selection.isValid
        ? value.selection
        : TextSelection.collapsed(offset: value.text.length);
    final updatedText = value.text.replaceRange(
      selection.start,
      selection.end,
      '\n',
    );
    controller.value = value.copyWith(
      text: updatedText,
      selection: TextSelection.collapsed(offset: selection.start + 1),
      composing: TextRange.empty,
    );
  }
}

class _LibreriaMark extends StatelessWidget {
  const _LibreriaMark({
    required this.color,
    this.size = 40,
    this.iconSize = 20,
    this.showShadow = false,
  });

  final Color color;
  final double size;
  final double iconSize;
  final bool showShadow;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(size * 0.32),
      boxShadow: showShadow ? AppShadows.soft(color) : null,
    ),
    child: Icon(
      Icons.auto_awesome_rounded,
      color: Colors.white,
      size: iconSize,
    ),
  );
}

extension<T> on List<T> {
  T? get lastOrNull => isEmpty ? null : last;
}
