import 'package:flutter_test/flutter_test.dart';
import 'package:reading_tracker/core/preferences/reader_profile_text_validator.dart';

void main() {
  test('normalizes whitespace and capitalizes the first letter', () {
    final result = ReaderProfileTextValidator.validate('  álvaro   7  ');

    expect(result.isValid, isTrue);
    expect(result.value, 'Álvaro 7');
  });

  test('rejects names outside the supported length', () {
    expect(ReaderProfileTextValidator.validate('A').error, isNotNull);
    expect(
      ReaderProfileTextValidator.validate('Nombre demasiado largo').error,
      contains('15'),
    );
  });

  test('rejects unsupported characters', () {
    final result = ReaderProfileTextValidator.validate('Ana!');

    expect(result.error, contains('letras, números y espacios'));
  });

  test('rejects prohibited terms with or without accents', () {
    const prohibited = [
      'puta',
      'polla',
      'nazi',
      'mierda',
      'gilipollas',
      'cabron',
      'cabrón',
      'fascista',
      'hitler',
    ];

    for (final term in prohibited) {
      expect(
        ReaderProfileTextValidator.validate('Hola $term').error,
        contains('no permitido'),
        reason: term,
      );
    }
  });
}
