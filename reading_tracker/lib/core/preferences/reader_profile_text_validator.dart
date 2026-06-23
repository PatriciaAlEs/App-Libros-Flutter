class ReaderProfileTextValidation {
  const ReaderProfileTextValidation({required this.value, this.error});

  final String value;
  final String? error;

  bool get isValid => error == null;
}

class ReaderProfileTextValidator {
  const ReaderProfileTextValidator._();

  static const minLength = 2;
  static const maxLength = 15;

  static final RegExp _allowedCharacters = RegExp(
    r'^[A-Za-zÀ-ÖØ-öø-ÿ0-9]+(?: [A-Za-zÀ-ÖØ-öø-ÿ0-9]+)*$',
  );

  static const _forbiddenTerms = {
    'puta',
    'polla',
    'nazi',
    'mierda',
    'gilipollas',
    'cabron',
    'fascista',
    'hitler',
  };

  static ReaderProfileTextValidation validate(
    String input, {
    String fieldLabel = 'El nombre',
  }) {
    final value = normalize(input);
    if (value.length < minLength) {
      return ReaderProfileTextValidation(
        value: value,
        error: '$fieldLabel debe tener al menos $minLength caracteres.',
      );
    }
    if (value.length > maxLength) {
      return ReaderProfileTextValidation(
        value: value,
        error: '$fieldLabel puede tener como máximo $maxLength caracteres.',
      );
    }
    if (!_allowedCharacters.hasMatch(value)) {
      return ReaderProfileTextValidation(
        value: value,
        error: '$fieldLabel solo puede incluir letras, números y espacios.',
      );
    }
    final words = _foldDiacritics(value.toLowerCase()).split(' ');
    if (words.any(_forbiddenTerms.contains)) {
      return ReaderProfileTextValidation(
        value: value,
        error: '$fieldLabel contiene un término no permitido.',
      );
    }
    return ReaderProfileTextValidation(value: value);
  }

  static String normalize(String input) {
    final trimmed = input.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (trimmed.isEmpty) return '';
    return '${trimmed[0].toUpperCase()}${trimmed.substring(1)}';
  }

  static String _foldDiacritics(String value) {
    const replacements = {
      'á': 'a',
      'à': 'a',
      'ä': 'a',
      'â': 'a',
      'ã': 'a',
      'é': 'e',
      'è': 'e',
      'ë': 'e',
      'ê': 'e',
      'í': 'i',
      'ì': 'i',
      'ï': 'i',
      'î': 'i',
      'ó': 'o',
      'ò': 'o',
      'ö': 'o',
      'ô': 'o',
      'õ': 'o',
      'ú': 'u',
      'ù': 'u',
      'ü': 'u',
      'û': 'u',
    };
    return value.split('').map((char) => replacements[char] ?? char).join();
  }
}
