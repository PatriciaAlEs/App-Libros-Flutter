import 'remote_model_utils.dart';

class RemoteProfileDto {
  const RemoteProfileDto({
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

  factory RemoteProfileDto.fromJson(Map<String, dynamic> json) {
    return RemoteProfileDto(
      id: json['id'] as String,
      readerName: json['reader_name'] as String?,
      greeting: json['greeting'] as String?,
      customGreeting: json['custom_greeting'] as String?,
      createdAt: readDateTime(json, 'created_at'),
      updatedAt: readDateTime(json, 'updated_at'),
      deletedAt: readDateTime(json, 'deleted_at'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'reader_name': readerName,
      'greeting': greeting,
      'custom_greeting': customGreeting,
      'created_at': writeDateTime(createdAt),
      'updated_at': writeDateTime(updatedAt),
      'deleted_at': writeDateTime(deletedAt),
    };
  }
}
