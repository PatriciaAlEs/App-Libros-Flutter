import 'package:flutter/foundation.dart';

void logSyncDebugError({
  required String operation,
  required Object error,
  String? table,
  String? entityType,
  String? localId,
  String? userId,
  StackTrace? stackTrace,
}) {
  if (!kDebugMode) return;

  final parts = <String>[
    'operation=$operation',
    if (table != null) 'table=$table',
    if (entityType != null) 'entity=$entityType',
    if (localId != null) 'localId=$localId',
    if (userId != null) 'userId=${_redactUserId(userId)}',
    'errorType=${error.runtimeType}',
    'error=$error',
    if (_dynamicField(error, 'code') case final code?) 'code=$code',
    if (_dynamicField(error, 'status') case final status?) 'status=$status',
    if (_dynamicField(error, 'details') case final details?) 'details=$details',
    if (_dynamicField(error, 'hint') case final hint?) 'hint=$hint',
  ];

  debugPrint('[ReadPp sync] ${parts.join(' ')}');
  if (stackTrace != null) {
    debugPrint('[ReadPp sync] stackTrace=$stackTrace');
  }
}

String syncFailureMessage({
  required String operation,
  required Object error,
  String? entityType,
  String? localId,
  String? table,
}) {
  final code = _dynamicField(error, 'code');
  final status = _dynamicField(error, 'status');
  final locationParts = <String>[];
  if (table != null) locationParts.add(table);
  if (entityType != null) locationParts.add(entityType);
  if (localId != null) locationParts.add(localId);
  final location = locationParts.join('/');
  final suffix = [
    if (code != null) 'code=$code',
    if (status != null) 'status=$status',
  ].join(' ');

  return [
    operation,
    if (location.isNotEmpty) location,
    error.toString(),
    if (suffix.isNotEmpty) suffix,
  ].join(' - ');
}

Object? _dynamicField(Object error, String field) {
  try {
    final dynamic value = error;
    return switch (field) {
      'code' => value.code,
      'status' => value.status,
      'details' => value.details,
      'hint' => value.hint,
      _ => null,
    };
  } catch (_) {
    return null;
  }
}

String _redactUserId(String userId) {
  if (userId.length <= 8) return '***';
  return '***${userId.substring(userId.length - 8)}';
}
