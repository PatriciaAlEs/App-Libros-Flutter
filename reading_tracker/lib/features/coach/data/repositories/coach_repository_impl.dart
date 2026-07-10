import '../../domain/entities/coach_message.dart';
import '../../domain/repositories/coach_repository.dart';
import '../../domain/services/llm_client.dart';

class CoachRepositoryImpl implements CoachRepository {
  const CoachRepositoryImpl(this._llmClient);

  final LlmClient _llmClient;

  @override
  Future<String> generateReply(List<CoachMessage> messages) {
    return _llmClient.complete(messages: messages);
  }
}
