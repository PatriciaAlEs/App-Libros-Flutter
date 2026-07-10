import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design_system/design_system.dart';
import '../../domain/providers/reader_context_provider.dart';
import '../controllers/coach_controller.dart';
import '../widgets/coach_message_bubble.dart';

class CoachScreen extends ConsumerStatefulWidget {
  const CoachScreen({super.key});

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
    _scrollController.addListener(_handleScroll);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_handleScroll)
      ..dispose();
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
    final state = ref.watch(coachControllerProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('ReadPp Coach'),
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
            onPressed: () => _showConversationHistory(state),
            icon: const Icon(Icons.history),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: Stack(
                children: [
                  if (state.messages.isEmpty)
                    _CoachEmptyState(onSuggestion: _sendSuggestion)
                  else
                    ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg,
                        AppSpacing.lg,
                        AppSpacing.lg,
                        96,
                      ),
                      itemCount: state.messages.length,
                      itemBuilder: (context, index) {
                        final message = state.messages[index];
                        final isActive = state.activeAssistantIndex == index;
                        return CoachMessageBubble(
                          key: ValueKey('coach-message-${message.id}'),
                          message: message,
                          isWaiting: isActive && state.isWaitingFirstChunk,
                          isStreaming: isActive && state.hasPartialResponse,
                          showRegenerate:
                              index == state.messages.length - 1 &&
                              state.canRegenerate,
                          onRegenerate: () => ref
                              .read(coachControllerProvider.notifier)
                              .regenerateLastResponse(),
                        );
                      },
                    ),
                  Positioned(
                    right: AppSpacing.lg,
                    bottom: AppSpacing.md,
                    child: AnimatedSwitcher(
                      duration: _motionDuration(context),
                      child: _followTail
                          ? const SizedBox.shrink()
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
            if (state.errorMessage != null)
              _CoachErrorBanner(
                message: state.errorMessage!,
                onRetry: state.canRetry
                    ? () => ref
                          .read(coachControllerProvider.notifier)
                          .retryLastResponse()
                    : null,
              ),
            _CoachComposer(
              controller: _textController,
              focusNode: _focusNode,
              isGenerating: state.isLoading,
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

  void _handleScroll() {
    if (!_scrollController.hasClients) {
      return;
    }
    final distance =
        _scrollController.position.maxScrollExtent -
        _scrollController.position.pixels;
    final shouldFollow = distance <= _bottomThreshold;
    if (shouldFollow != _followTail && mounted) {
      setState(() => _followTail = shouldFollow);
    }
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

class _CoachEmptyState extends StatelessWidget {
  const _CoachEmptyState({required this.onSuggestion});

  static const suggestions = [
    'Resume mi progreso de lectura',
    'Recomiéndame mi próxima lectura',
    'Analiza mis hábitos lectores',
    'Ayúdame a crear un objetivo de lectura',
  ];

  final ValueChanged<String> onSuggestion;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.xxl,
        AppSpacing.lg,
        AppSpacing.xl,
      ),
      children: [
        Icon(Icons.auto_awesome, size: 42, color: theme.colorScheme.primary),
        const SizedBox(height: AppSpacing.md),
        Text(
          '¿Qué te gustaría explorar?',
          style: theme.textTheme.headlineSmall,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Conversa sobre tu progreso, tus hábitos y tus próximas lecturas.',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
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
                  padding: const EdgeInsets.all(AppSpacing.md),
                ),
                child: Text(suggestion),
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
    required this.onSend,
    required this.onStop,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isGenerating;
  final VoidCallback onSend;
  final VoidCallback onStop;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.sm,
          AppSpacing.md,
          92,
        ),
        child: Material(
          color: theme.colorScheme.surface,
          elevation: 2,
          borderRadius: BorderRadius.circular(24),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  minLines: 1,
                  maxLines: 5,
                  textInputAction: TextInputAction.newline,
                  decoration: const InputDecoration(
                    hintText: 'Pregunta al Coach…',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.all(AppSpacing.md),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(6),
                child: AnimatedSwitcher(
                  duration: AppMotion.normal,
                  child: isGenerating
                      ? Semantics(
                          button: true,
                          label: 'Detener respuesta',
                          child: IconButton.filled(
                            key: const ValueKey('stop'),
                            onPressed: onStop,
                            icon: const Icon(Icons.stop_rounded),
                          ),
                        )
                      : Semantics(
                          button: true,
                          label: 'Enviar mensaje',
                          child: IconButton.filled(
                            key: const ValueKey('send'),
                            onPressed: onSend,
                            icon: const Icon(Icons.arrow_upward_rounded),
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

extension<T> on List<T> {
  T? get lastOrNull => isEmpty ? null : last;
}
