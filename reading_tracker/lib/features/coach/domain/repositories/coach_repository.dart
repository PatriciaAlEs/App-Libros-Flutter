import '../entities/coach_message.dart';

abstract class CoachRepository {
  Future<String> generateReply(List<CoachMessage> messages);
}
