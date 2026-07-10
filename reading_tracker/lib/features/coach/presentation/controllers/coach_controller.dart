import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/providers/coach_repository_provider.dart';
import '../../domain/entities/coach_message.dart';
import '../../domain/models/reader_context.dart';
import '../../domain/repositories/coach_repository.dart';

final coachControllerProvider =
    StateNotifierProvider<CoachController, CoachControllerState>((ref) {
      return CoachController(
        repository: ref.watch(coachRepositoryProvider),
      );
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
  CoachController({
    required CoachRepository repository,
  }) : _repository = repository,
       super(CoachControllerState());

  final CoachRepository _repository;

  Future<void> sendMessage({
    required String userMessage,
    required ReaderContext readerContext,
  }) async {
    if (userMessage.trim().isEmpty) {
      throw ArgumentError.value(
        userMessage,
        'userMessage',
        'User message cannot be empty',
      );
    }

    final conversation = state.messages;
    final userCoachMessage = CoachMessage.user(userMessage);
    final visibleMessages = [...conversation, userCoachMessage];

    state = state.copyWith(
      messages: visibleMessages,
      isLoading: true,
      clearError: true,
    );

    try {
      final reply = await _repository.generateReply(
        userMessage: userMessage,
        conversation: conversation,
        readerContext: readerContext,
      );

      if (reply.trim().isEmpty) {
        throw const CoachReplyException('Empty assistant reply');
      }

      state = state.copyWith(
        messages: [...visibleMessages, CoachMessage.assistant(reply)],
        isLoading: false,
        clearError: true,
      );
    } catch (_) {
      state = state.copyWith(
        messages: visibleMessages,
        isLoading: false,
        errorMessage:
            'No se ha podido generar la respuesta. Intentalo de nuevo.',
      );
    }
  }
}

class CoachReplyException implements Exception {
  const CoachReplyException(this.message);

  final String message;

  @override
  String toString() => 'CoachReplyException: $message';
}
