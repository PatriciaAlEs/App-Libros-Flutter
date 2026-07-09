import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reading_tracker/features/libreria/domain/services/libreria_engine.dart';
import 'package:reading_tracker/features/libreria/engine/libreria_engine.dart';
import 'package:reading_tracker/features/libreria/presentation/providers/libreria_provider.dart';

void main() {
  test('libreriaEngineProvider resolves the central engine', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final engine = container.read(libreriaEngineProvider);

    expect(engine, isA<LibreriaEngine>());
    expect(engine, isA<LibrerIAEngine>());
  });

  test('engine layer has no direct real AI provider dependency', () {
    final engineDirectory = Directory('lib/features/libreria/engine');
    final source = engineDirectory
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'))
        .map((file) => file.readAsStringSync().toLowerCase())
        .join('\n');

    expect(source, isNot(contains('openai')));
    expect(source, isNot(contains('gemini')));
    expect(source, isNot(contains('claude')));
    expect(source, isNot(contains('aiprovider')));
  });
}
