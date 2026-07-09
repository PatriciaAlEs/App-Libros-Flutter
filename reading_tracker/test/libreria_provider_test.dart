import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reading_tracker/features/libreria/domain/entities/libreria_engine_state.dart';
import 'package:reading_tracker/features/libreria/domain/services/libreria_engine.dart';
import 'package:reading_tracker/features/libreria/engine/libreria_engine.dart';
import 'package:reading_tracker/features/libreria/presentation/models/libreria_view_state.dart';
import 'package:reading_tracker/features/libreria/presentation/providers/libreria_provider.dart';

void main() {
  test('libreriaEngineProvider resolves the central engine', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final engine = container.read(libreriaEngineProvider);

    expect(engine, isA<LibreriaEngine>());
    expect(engine, isA<LibrerIAEngine>());
  });

  test(
    'libreriaViewStateProvider derives the initial UI state from engine',
    () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final viewState = container.read(libreriaViewStateProvider);

      expect(viewState.status, LibreriaViewStatus.initial);
      expect(viewState.message, 'Preparando coach de lectura');
    },
  );

  test('view state maps the preparation engine state to initial UI', () {
    final viewState = LibreriaViewState.fromEngineState(
      const LibreriaEngineState(),
    );

    expect(viewState.status, LibreriaViewStatus.initial);
    expect(viewState.message, 'Preparando coach de lectura');
  });

  test('libreria feature has no direct real AI provider dependency', () {
    final source = _readLibreriaSource();

    expect(source, isNot(contains('openai')));
    expect(source, isNot(contains('gemini')));
    expect(source, isNot(contains('claude')));
    expect(source, isNot(contains('aiprovider')));
  });

  test('libreria UI has no direct real tool dependency', () {
    final source = _readDartSource(
      Directory('lib/features/libreria/presentation'),
    );

    expect(source, isNot(contains('contextbuilder')));
    expect(source, isNot(contains('toolmanager')));
    expect(source, isNot(contains('tool manager')));
    expect(source, isNot(contains('openai')));
  });
}

String _readLibreriaSource() {
  return _readDartSource(Directory('lib/features/libreria'));
}

String _readDartSource(Directory directory) {
  return directory
      .listSync(recursive: true)
      .whereType<File>()
      .where((file) => file.path.endsWith('.dart'))
      .map((file) => file.readAsStringSync().toLowerCase())
      .join('\n');
}
