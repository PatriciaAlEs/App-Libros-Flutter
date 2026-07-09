enum LibreriaInsightKind { progress, activity, annualGoal, currentReading }

class LibreriaInsight {
  const LibreriaInsight({
    required this.id,
    required this.kind,
    required this.title,
    required this.message,
    required this.sourceLabel,
  });

  final String id;
  final LibreriaInsightKind kind;
  final String title;
  final String message;
  final String sourceLabel;
}
