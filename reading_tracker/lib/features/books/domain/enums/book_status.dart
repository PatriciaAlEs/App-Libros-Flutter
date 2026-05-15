enum BookStatus {
  pending,
  reading,
  completed;

  static BookStatus fromString(String value) {
    return BookStatus.values.firstWhere(
      (status) => status.name == value,
      orElse: () => BookStatus.pending,
    );
  }

  String toValue() => name;
}
