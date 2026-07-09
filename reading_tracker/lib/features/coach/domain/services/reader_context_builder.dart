import '../models/reader_context.dart';

abstract class ReaderContextBuilder {
  Future<ReaderContext> build();
}
