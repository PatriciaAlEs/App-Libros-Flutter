import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/providers/coach_repository_provider.dart';
import '../../domain/entities/coach_message.dart';
import '../../domain/models/reader_context.dart';
import '../../domain/repositories/coach_repository.dart';

final coachControllerProvider =
    StateNotifierProvider<CoachController, CoachControllerState>((ref) {
      return CoachController(repository: ref.watch(coachRepositoryProvider));
    });

enum CoachGenerationStatus {
  idle,
  waitingFirstChunk,
  streaming,
  completed,
  cancelled,
  failed,
}

class CoachControllerState {
  CoachControllerState({
    List<CoachMessage> messages = const [],
    this.generationStatus = CoachGenerationStatus.idle,
    this.errorMessage,
    this.activeAssistantIndex,
  }) : messages = List.unmodifiable(messages);

  final List<CoachMessage> messages;
  final CoachGenerationStatus generationStatus;
  final String? errorMessage;
  final int? activeAssistantIndex;

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
  }) {
    return CoachControllerState(
      messages: messages ?? this.messages,
      generationStatus: generationStatus ?? this.generationStatus,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      activeAssistantIndex: clearActiveAssistant
          ? null
          : activeAssistantIndex ?? this.activeAssistantIndex,
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
  CoachController({required CoachRepository repository})
    : _repository = repository,
      super(CoachControllerState());

  final CoachRepository _repository;
  StreamSubscription<String>? _activeSubscription;
  Completer<void>? _activeCompletion;
  ReaderContext? _lastReaderContext;
  int _generationId = 0;

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

    final conversation = state.messages;
    final visibleMessages = [...conversation, CoachMessage.user(userMessage)];
    await _startGeneration(
      userMessage: userMessage,
      conversation: conversation,
      visibleMessages: visibleMessages,
      readerContext: readerContext,
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
    if (activeIndex != null &&
        activeIndex < messages.length &&
        messages[activeIndex].content.trim().isEmpty) {
      messages.removeAt(activeIndex);
    }
    state = state.copyWith(
      messages: messages,
      generationStatus: CoachGenerationStatus.cancelled,
      clearError: true,
      clearActiveAssistant: true,
    );
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
  }) async {
    final generationId = ++_generationId;
    _lastReaderContext = readerContext;
    var accumulated = '';
    final assistantIndex = visibleMessages.length;
    final streamingMessages = [...visibleMessages, CoachMessage.assistant('')];
    state = state.copyWith(
      messages: streamingMessages,
      generationStatus: CoachGenerationStatus.waitingFirstChunk,
      activeAssistantIndex: assistantIndex,
      clearError: true,
    );

    final completed = Completer<void>();
    _activeCompletion = completed;
    try {
      final stream = _repository.streamReply(
        userMessage: userMessage,
        conversation: conversation,
        readerContext: readerContext,
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
          updatedMessages[assistantIndex] = CoachMessage.assistant(accumulated);
          state = state.copyWith(
            messages: updatedMessages,
            generationStatus: CoachGenerationStatus.streaming,
            clearError: true,
          );
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
        state = state.copyWith(
          generationStatus: CoachGenerationStatus.completed,
          clearError: true,
          clearActiveAssistant: true,
        );
      }
    } catch (_) {
      if (mounted && generationId == _generationId) {
        final messages = state.messages.toList();
        if (accumulated.trim().isEmpty && assistantIndex < messages.length) {
          messages.removeAt(assistantIndex);
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
    super.dispose();
  }
}

class CoachReplyException implements Exception {
  const CoachReplyException(this.message);
  final String message;

  @override
  String toString() => 'CoachReplyException: $message';
}
