import 'package:reading_tracker/features/coach/domain/entities/coach_message.dart';
import 'package:reading_tracker/features/coach/domain/services/llm_client.dart';

class FakeLlmClient implements LlmClient {
  FakeLlmClient(this.response);

  final String response;
  List<CoachMessage>? lastMessages;

  @override
  Future<String> complete({required List<CoachMessage> messages}) async {
    if (messages.isEmpty) {
      throw ArgumentError.value(
        messages,
        'messages',
        'Messages cannot be empty',
      );
    }

    lastMessages = List.unmodifiable(messages);
    return response;
  }
}
