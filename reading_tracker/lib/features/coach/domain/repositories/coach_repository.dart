import '../entities/coach_message.dart';
import '../models/reader_context.dart';

abstract class CoachRepository {
  Stream<String> streamReply({
    required String userMessage,
    required List<CoachMessage> conversation,
    required ReaderContext readerContext,
    bool conversationIncludesCurrentMessage = false,
  });
}
