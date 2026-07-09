import '../entities/coach_message.dart';

abstract class LlmClient {
  Future<String> complete({required List<CoachMessage> messages});
}
