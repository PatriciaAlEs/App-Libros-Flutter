class BookishCultureEntry {
  const BookishCultureEntry({
    required this.id,
    required this.topics,
    required this.triggers,
    required this.context,
    required this.humorAngles,
    required this.avoidWhen,
    required this.evergreen,
    required this.reviewedAt,
    this.expiresAt,
  });

  final String id;
  final List<String> topics;
  final List<String> triggers;
  final String context;
  final List<String> humorAngles;
  final List<String> avoidWhen;
  final bool evergreen;
  final String reviewedAt;
  final String? expiresAt;

  bool isExpiredAt(DateTime date) {
    final expiry = expiresAt == null ? null : DateTime.tryParse(expiresAt!);
    return expiry != null && date.isAfter(expiry);
  }
}
