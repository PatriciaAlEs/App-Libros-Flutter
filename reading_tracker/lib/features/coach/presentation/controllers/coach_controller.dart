import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../data/providers/coach_repository_provider.dart';
import '../../domain/entities/coach_message.dart';
import '../../domain/entities/coach_conversation.dart';
import '../../domain/models/reader_context.dart';
import '../../domain/repositories/coach_conversation_repository.dart';
import '../../domain/repositories/coach_repository.dart';
import '../../domain/services/conversation_summary_service.dart';

final coachControllerProvider =
    StateNotifierProvider<CoachController, CoachControllerState>((ref) {
      final controller = CoachController(
        repository: ref.watch(coachRepositoryProvider),
        conversationRepository: ref.watch(coachConversationRepositoryProvider),
        summaryService: ref.watch(conversationSummaryServiceProvider),
      );
      Future.microtask(controller.restoreMostRecentConversation);
      return controller;
    });

enum CoachGenerationStatus {
  idle,
  waitingFirstChunk,
  streaming,
  completed,
  cancelled,
  failed,
}

enum CoachConversationLoadStatus { idle, loading, loaded, failed }

class CoachControllerState {
  CoachControllerState({
    List<CoachMessage> messages = const [],
    this.generationStatus = CoachGenerationStatus.idle,
    this.errorMessage,
    this.activeAssistantIndex,
    this.activeConversation,
    this.conversationLoadStatus = CoachConversationLoadStatus.idle,
    List<CoachConversation> conversations = const [],
  }) : messages = List.unmodifiable(messages),
       conversations = List.unmodifiable(conversations);

  final List<CoachMessage> messages;
  final CoachGenerationStatus generationStatus;
  final String? errorMessage;
  final int? activeAssistantIndex;
  final CoachConversation? activeConversation;
  final CoachConversationLoadStatus conversationLoadStatus;
  final List<CoachConversation> conversations;

  bool get isLoading =>
      generationStatus == CoachGenerationStatus.waitingFirstChunk ||
      generationStatus == CoachGenerationStatus.streaming;
  bool get isWaitingFirstChunk =>
      generationStatus == CoachGenerationStatus.waitingFirstChunk;
  bool get hasPartialResponse =>
      generationStatus == CoachGenerationStatus.streaming;
  bool get wasCancelled => generationStatus == CoachGenerationStatus.cancelled;
  bool get canRetry =>
      generationStatus == CoachGenerationStatus.failed &&
      _lastUserIndex(messages) != null;
  bool get canRegenerate =>
      !isLoading &&
      messages.isNotEmpty &&
      messages.last.role == CoachMessageRole.assistant &&
      messages.last.content.trim().isNotEmpty &&
      _lastUserIndex(messages) != null;

  CoachControllerState copyWith({
    List<CoachMessage>? messages,
    CoachGenerationStatus? generationStatus,
    String? errorMessage,
    bool clearError = false,
    int? activeAssistantIndex,
    bool clearActiveAssistant = false,
    CoachConversation? activeConversation,
    bool clearActiveConversation = false,
    CoachConversationLoadStatus? conversationLoadStatus,
    List<CoachConversation>? conversations,
  }) {
    return CoachControllerState(
      messages: messages ?? this.messages,
      generationStatus: generationStatus ?? this.generationStatus,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      activeAssistantIndex: clearActiveAssistant
          ? null
          : activeAssistantIndex ?? this.activeAssistantIndex,
      activeConversation: clearActiveConversation
          ? null
          : activeConversation ?? this.activeConversation,
      conversationLoadStatus:
          conversationLoadStatus ?? this.conversationLoadStatus,
      conversations: conversations ?? this.conversations,
    );
  }

  static int? _lastUserIndex(List<CoachMessage> messages) {
    for (var index = messages.length - 1; index >= 0; index--) {
      if (messages[index].role == CoachMessageRole.user) {
        return index;
      }
    }
    return null;
  }
}

class CoachController extends StateNotifier<CoachControllerState> {
  CoachController({
    required CoachRepository repository,
    CoachConversationRepository? conversationRepository,
    ConversationSummaryService? summaryService,
  }) : _repository = repository,
       _conversationRepository = conversationRepository,
       _summaryService = summaryService,
       super(CoachControllerState());

  final CoachRepository _repository;
  final CoachConversationRepository? _conversationRepository;
  final ConversationSummaryService? _summaryService;
  StreamSubscription<String>? _activeSubscription;
  Completer<void>? _activeCompletion;
  ReaderContext? _lastReaderContext;
  int _generationId = 0;
  Timer? _persistenceDebounce;
  Future<void>? _persistenceReady;

  Future<void> restoreMostRecentConversation() async {
    final repository = _conversationRepository;
    if (repository == null || state.isLoading) {
      return;
    }
    final restoreGenerationId = _generationId;
    if (state.messages.isNotEmpty || state.activeConversation != null) {
      return;
    }
    state = state.copyWith(
      conversationLoadStatus: CoachConversationLoadStatus.loading,
      clearError: true,
    );
    try {
      final conversations = await repository.getConversations();
      if (!mounted) {
        return;
      }
      if (restoreGenerationId != _generationId ||
          state.messages.isNotEmpty ||
          state.activeConversation != null) {
        return;
      }
      if (conversations.isEmpty) {
        state = state.copyWith(
          conversations: const [],
          conversationLoadStatus: CoachConversationLoadStatus.loaded,
          clearActiveConversation: true,
          messages: const [],
        );
        return;
      }
      await openConversation(
        conversations.first.id,
        conversations: conversations,
      );
    } catch (_) {
      if (mounted) {
        state = state.copyWith(
          conversationLoadStatus: CoachConversationLoadStatus.failed,
          errorMessage: 'No se pudo cargar el historial del Coach.',
        );
      }
    }
  }

  Future<void> openConversation(
    String id, {
    List<CoachConversation>? conversations,
  }) async {
    await cancelGeneration();
    final repository = _conversationRepository;
    if (repository == null) {
      return;
    }
    state = state.copyWith(
      conversationLoadStatus: CoachConversationLoadStatus.loading,
    );
    try {
      final conversation = await repository.getConversation(id);
      if (conversation == null) {
        return;
      }
      final messages = await repository.getMessages(id);
      if (!mounted) {
        return;
      }
      state = state.copyWith(
        messages: messages,
        activeConversation: conversation,
        conversations: conversations ?? state.conversations,
        conversationLoadStatus: CoachConversationLoadStatus.loaded,
        generationStatus: CoachGenerationStatus.idle,
        clearError: true,
        clearActiveAssistant: true,
      );
    } catch (_) {
      if (mounted) {
        state = state.copyWith(
          conversationLoadStatus: CoachConversationLoadStatus.failed,
          errorMessage: 'No se pudo abrir la conversación.',
        );
      }
    }
  }

  Future<void> startNewConversation() async {
    await cancelGeneration();
    state = state.copyWith(
      messages: const [],
      generationStatus: CoachGenerationStatus.idle,
      conversationLoadStatus: CoachConversationLoadStatus.loaded,
      clearActiveConversation: true,
      clearActiveAssistant: true,
      clearError: true,
    );
  }

  Future<void> deleteConversation(String id) async {
    await cancelGeneration();
    final repository = _conversationRepository;
    if (repository == null) {
      return;
    }
    await repository.deleteConversation(id);
    await restoreMostRecentConversation();
  }

  Future<void> sendMessage({
    required String userMessage,
    required ReaderContext readerContext,
  }) async {
    if (state.isLoading) {
      return;
    }
    if (userMessage.trim().isEmpty) {
      throw ArgumentError.value(
        userMessage,
        'userMessage',
        'User message cannot be empty',
      );
    }

    var activeConversation = state.activeConversation;
    final memoryRepository = _conversationRepository;
    Future<void>? preparePersistence;
    if (activeConversation == null && memoryRepository != null) {
      final now = DateTime.now();
      final normalizedTitle = userMessage
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();
      activeConversation = CoachConversation(
        id: const Uuid().v4(),
        title: normalizedTitle.length <= 60
            ? normalizedTitle
            : '${normalizedTitle.substring(0, 57)}…',
        createdAt: now,
        updatedAt: now,
        lastMessageAt: now,
      );
      state = state.copyWith(
        activeConversation: activeConversation,
        conversations: [activeConversation, ...state.conversations],
        conversationLoadStatus: CoachConversationLoadStatus.loaded,
      );
    }
    final conversation = state.messages;
    final userCoachMessage = CoachMessage.user(
      userMessage,
      conversationId: activeConversation?.id,
      sequence: conversation.length,
    );
    if (memoryRepository != null && activeConversation != null) {
      preparePersistence = () async {
        await memoryRepository.saveConversation(activeConversation!);
        await memoryRepository.saveMessage(userCoachMessage);
      }();
    }
    final visibleMessages = [...conversation, userCoachMessage];
    await _startGeneration(
      userMessage: userMessage,
      conversation: conversation,
      visibleMessages: visibleMessages,
      readerContext: readerContext,
      preparePersistence: preparePersistence,
    );
  }

  Future<void> cancelGeneration() async {
    if (!state.isLoading) {
      return;
    }
    _generationId++;
    final subscription = _activeSubscription;
    _activeSubscription = null;
    final completion = _activeCompletion;
    if (completion != null && !completion.isCompleted) {
      completion.complete();
    }
    _activeCompletion = null;
    if (!mounted) {
      return;
    }

    final messages = state.messages.toList();
    final activeIndex = state.activeAssistantIndex;
    CoachMessage? removedMessage;
    CoachMessage? partialMessage;
    if (activeIndex != null &&
        activeIndex < messages.length &&
        messages[activeIndex].content.trim().isEmpty) {
      removedMessage = messages.removeAt(activeIndex);
    } else if (activeIndex != null && activeIndex < messages.length) {
      partialMessage = messages[activeIndex];
    }
    state = state.copyWith(
      messages: messages,
      generationStatus: CoachGenerationStatus.cancelled,
      clearError: true,
      clearActiveAssistant: true,
    );
    if (removedMessage != null) {
      await _persistenceReady;
      await _conversationRepository?.deleteMessage(removedMessage.id);
    } else if (partialMessage != null) {
      await _flushPersistentMessage(partialMessage);
    }
    await subscription?.cancel();
  }

  Future<void> regenerateLastResponse() async {
    if (state.isLoading || !state.canRegenerate) {
      return;
    }
    await _restartLastExchange();
  }

  Future<void> retryLastResponse() async {
    if (state.isLoading || !state.canRetry) {
      return;
    }
    await _restartLastExchange();
  }

  Future<void> _restartLastExchange() async {
    final readerContext = _lastReaderContext;
    if (readerContext == null) {
      return;
    }
    final messages = state.messages.toList();
    final userIndex = _lastUserIndex(messages);
    if (userIndex == null) {
      return;
    }
    final userMessage = messages[userIndex].content;
    if (messages.isNotEmpty &&
        messages.last.role == CoachMessageRole.assistant) {
      await _conversationRepository?.deleteMessage(messages.last.id);
    }
    final conversation = messages.sublist(0, userIndex);
    final visibleMessages = messages.sublist(0, userIndex + 1);
    await _startGeneration(
      userMessage: userMessage,
      conversation: conversation,
      visibleMessages: visibleMessages,
      readerContext: readerContext,
    );
  }

  Future<void> _startGeneration({
    required String userMessage,
    required List<CoachMessage> conversation,
    required List<CoachMessage> visibleMessages,
    required ReaderContext readerContext,
    Future<void>? preparePersistence,
  }) async {
    final generationId = ++_generationId;
    _lastReaderContext = readerContext;
    var accumulated = '';
    final assistantIndex = visibleMessages.length;
    final parentUser = visibleMessages.last;
    final assistantMessage = CoachMessage.assistant(
      '',
      conversationId: state.activeConversation?.id,
      parentUserMessageId: parentUser.id,
      sequence: assistantIndex,
    );
    final streamingMessages = [...visibleMessages, assistantMessage];
    state = state.copyWith(
      messages: streamingMessages,
      generationStatus: CoachGenerationStatus.waitingFirstChunk,
      activeAssistantIndex: assistantIndex,
      clearError: true,
    );
    _persistenceReady = () async {
      try {
        await preparePersistence;
        await _conversationRepository?.saveMessage(assistantMessage);
      } catch (_) {
        // Persistence failures must not block the conversational response.
      }
    }();

    final completed = Completer<void>();
    _activeCompletion = completed;
    try {
      final stream = _repository.streamReply(
        userMessage: userMessage,
        conversation: conversation,
        readerContext: readerContext,
        conversationSummary: state.activeConversation?.summary,
      );
      _activeSubscription = stream.listen(
        (chunk) {
          if (!mounted || generationId != _generationId || chunk.isEmpty) {
            return;
          }
          accumulated += chunk;
          final updatedMessages = state.messages.toList();
          if (assistantIndex >= updatedMessages.length) {
            return;
          }
          updatedMessages[assistantIndex] = updatedMessages[assistantIndex]
              .copyWith(content: accumulated);
          state = state.copyWith(
            messages: updatedMessages,
            generationStatus: CoachGenerationStatus.streaming,
            clearError: true,
          );
          _schedulePersistence(updatedMessages[assistantIndex]);
        },
        onError: (Object error, StackTrace stackTrace) {
          if (!completed.isCompleted) {
            completed.completeError(error, stackTrace);
          }
        },
        onDone: () {
          if (!completed.isCompleted) {
            completed.complete();
          }
        },
        cancelOnError: true,
      );
      await completed.future;
      if (generationId != _generationId) {
        return;
      }
      if (accumulated.trim().isEmpty) {
        throw const CoachReplyException('Empty assistant reply');
      }
      if (mounted) {
        await _flushPersistentMessage(state.messages[assistantIndex]);
        state = state.copyWith(
          generationStatus: CoachGenerationStatus.completed,
          clearError: true,
          clearActiveAssistant: true,
        );
        unawaited(_updateConversationMemory());
      }
    } catch (_) {
      if (mounted && generationId == _generationId) {
        final messages = state.messages.toList();
        if (accumulated.trim().isEmpty && assistantIndex < messages.length) {
          final removed = messages.removeAt(assistantIndex);
          await _conversationRepository?.deleteMessage(removed.id);
        } else if (assistantIndex < messages.length) {
          await _flushPersistentMessage(messages[assistantIndex]);
        }
        state = state.copyWith(
          messages: messages,
          generationStatus: CoachGenerationStatus.failed,
          errorMessage:
              'No se ha podido generar la respuesta. Inténtalo de nuevo.',
          clearActiveAssistant: true,
        );
      }
    } finally {
      if (generationId == _generationId) {
        await _activeSubscription?.cancel();
        _activeSubscription = null;
        _activeCompletion = null;
      }
    }
  }

  int? _lastUserIndex(List<CoachMessage> messages) {
    for (var index = messages.length - 1; index >= 0; index--) {
      if (messages[index].role == CoachMessageRole.user) {
        return index;
      }
    }
    return null;
  }

  void _schedulePersistence(CoachMessage message) {
    if (_conversationRepository == null) {
      return;
    }
    _persistenceDebounce?.cancel();
    _persistenceDebounce = Timer(const Duration(milliseconds: 400), () async {
      await _persistenceReady;
      await _conversationRepository.saveMessage(message);
    });
  }

  Future<void> _flushPersistentMessage(CoachMessage message) async {
    _persistenceDebounce?.cancel();
    _persistenceDebounce = null;
    await _persistenceReady;
    await _conversationRepository?.saveMessage(message);
  }

  Future<void> _updateConversationMemory() async {
    final repository = _conversationRepository;
    final conversation = state.activeConversation;
    if (repository == null || conversation == null) {
      return;
    }
    final now = DateTime.now();
    final summary = await _summaryService?.summarizeIfNeeded(
      messages: state.messages,
      previousSummary: conversation.summary,
    );
    final updated = conversation.copyWith(
      updatedAt: now,
      lastMessageAt: now,
      summary: summary,
    );
    await repository.saveConversation(updated);
    if (mounted) {
      state = state.copyWith(
        activeConversation: updated,
        conversations: [
          updated,
          ...state.conversations.where((item) => item.id != updated.id),
        ],
      );
    }
  }

  @override
  void dispose() {
    _generationId++;
    _activeSubscription?.cancel();
    _activeSubscription = null;
    final completion = _activeCompletion;
    if (completion != null && !completion.isCompleted) {
      completion.complete();
    }
    _activeCompletion = null;
    _persistenceDebounce?.cancel();
    _persistenceDebounce = null;
    _persistenceReady = null;
    super.dispose();
  }
}

class CoachReplyException implements Exception {
  const CoachReplyException(this.message);
  final String message;

  @override
  String toString() => 'CoachReplyException: $message';
}
