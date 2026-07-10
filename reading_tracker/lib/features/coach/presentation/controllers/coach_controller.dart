import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/providers/coach_repository_provider.dart';
import '../../domain/entities/coach_message.dart';
import '../../domain/models/reader_context.dart';
import '../../domain/repositories/coach_repository.dart';
import '../../domain/services/coach_system_\u0070rompt_builder.dart';
import '../../domain/services/context_formatter.dart';

final coachControllerProvider =
    StateNotifierProvider<CoachController, CoachControllerState>((ref) {
      return CoachController(
        repository: ref.watch(coachRepositoryProvider),
        contextFormatter: const MarkdownContextFormatter(),
        systemPromptBuilder: const DefaultCoachSystemPromptBuilder(),
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
    required ContextFormatter contextFormatter,
    required CoachSystemPromptBuilder systemPromptBuilder,
  }) : _repository = repository,
       _contextFormatter = contextFormatter,
       _systemPromptBuilder = systemPromptBuilder,
       super(CoachControllerState());

  final CoachRepository _repository;
  final ContextFormatter _contextFormatter;
  final CoachSystemPromptBuilder _systemPromptBuilder;

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

    final userCoachMessage = CoachMessage.user(userMessage);
    final visibleMessages = [...state.messages, userCoachMessage];

    state = state.copyWith(
      messages: visibleMessages,
      isLoading: true,
      clearError: true,
    );

    try {
      final reply = await _repository.generateReply(
        _requestMessages(
          readerContext: readerContext,
          visibleMessages: visibleMessages,
        ),
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

  List<CoachMessage> _requestMessages({
    required ReaderContext readerContext,
    required List<CoachMessage> visibleMessages,
  }) {
    return [
      CoachMessage.system(_systemPromptBuilder.build()),
      CoachMessage.system(_contextFormatter.format(readerContext)),
      ...visibleMessages,
    ];
  }
}

class CoachReplyException implements Exception {
  const CoachReplyException(this.message);

  final String message;

  @override
  String toString() => 'CoachReplyException: $message';
}
