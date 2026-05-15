enum BookStatus {
  pending,
  reading,
  completed;

  // ── String → Enum ──────────────────────────────────────
  static BookStatus fromString(String value) {
    return BookStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => BookStatus.pending,
    );
  }

  // ── Enum → String ──────────────────────────────────────
  String toValue() => name;
}