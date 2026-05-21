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

  String get label {
    switch (this) {
      case BookStatus.pending:
        return 'Pendiente';
      case BookStatus.reading:
        return 'Leyendo';
      case BookStatus.completed:
        return 'Completado';
    }
  }
}
