class RemoteProfile {
  const RemoteProfile({
    required this.id,
    this.readerName,
    this.greeting,
    this.customGreeting,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });

  final String id;
  final String? readerName;
  final String? greeting;
  final String? customGreeting;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;
}
