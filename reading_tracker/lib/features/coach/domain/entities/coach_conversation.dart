class CoachConversation {
  const CoachConversation({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    required this.lastMessageAt,
    this.summary,
  });

  final String id;
  final String title;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime lastMessageAt;
  final String? summary;

  CoachConversation copyWith({
    String? title,
    DateTime? updatedAt,
    DateTime? lastMessageAt,
    String? summary,
    bool clearSummary = false,
  }) {
    return CoachConversation(
      id: id,
      title: title ?? this.title,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      summary: clearSummary ? null : summary ?? this.summary,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoachConversation &&
          id == other.id &&
          title == other.title &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt &&
          lastMessageAt == other.lastMessageAt &&
          summary == other.summary;

  @override
  int get hashCode =>
      Object.hash(id, title, createdAt, updatedAt, lastMessageAt, summary);
}
