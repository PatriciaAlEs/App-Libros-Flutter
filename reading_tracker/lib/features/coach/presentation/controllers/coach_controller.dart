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

class CoachControllerState {
  CoachControllerState({
    List<CoachMessage> messages = const [],
    this.isLoading = false,
    this.errorMessage,
  }) : messages = List.unmodifiable(messages);

  final List<CoachMessage> messages;
  final bool isLoading;
  final String? errorMessage;

  CoachControllerState copyWith({
    List<CoachMessage>? messages,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return CoachControllerState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

class CoachController extends StateNotifier<CoachControllerState> {
  CoachController({required CoachRepository repository})
    : _repository = repository,
      super(CoachControllerState());

  final CoachRepository _repository;
  StreamSubscription<String>? _activeSubscription;
  Completer<void>? _activeCompletion;

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
    final userCoachMessage = CoachMessage.user(userMessage);
    final userMessages = [...conversation, userCoachMessage];
    final streamingMessages = [...userMessages, CoachMessage.assistant('')];

    state = state.copyWith(
      messages: streamingMessages,
      isLoading: true,
      clearError: true,
    );

    var accumulated = '';
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
          if (!mounted || chunk.isEmpty) {
            return;
          }
          accumulated += chunk;
          state = state.copyWith(
            messages: [...userMessages, CoachMessage.assistant(accumulated)],
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

      if (accumulated.trim().isEmpty) {
        throw const CoachReplyException('Empty assistant reply');
      }
    } catch (_) {
      if (mounted) {
        state = state.copyWith(
          messages: accumulated.trim().isEmpty ? userMessages : state.messages,
          errorMessage:
              'No se ha podido generar la respuesta. Intentalo de nuevo.',
        );
      }
    } finally {
      await _activeSubscription?.cancel();
      _activeSubscription = null;
      _activeCompletion = null;
      if (mounted) {
        state = state.copyWith(isLoading: false);
      }
    }
  }

  @override
  void dispose() {
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
