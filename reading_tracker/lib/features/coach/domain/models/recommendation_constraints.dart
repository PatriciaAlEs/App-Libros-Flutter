import '../entities/coach_message.dart';

class RecommendationConstraints {
  const RecommendationConstraints({
    this.requiresExternalSearch = false,
    this.outsideLibrary = false,
    this.standalone = false,
    this.completedSeries = false,
    this.authorGender,
    this.genre,
    this.format,
    this.language,
    this.maxPages,
    this.avoidedTrope,
  });

  final bool requiresExternalSearch;
  final bool outsideLibrary;
  final bool standalone;
  final bool completedSeries;
  final String? authorGender;
  final String? genre;
  final String? format;
  final String? language;
  final int? maxPages;
  final String? avoidedTrope;

  bool get hasBibliographicRestrictions =>
      outsideLibrary ||
      standalone ||
      completedSeries ||
      authorGender != null ||
      genre != null ||
      format != null ||
      language != null ||
      maxPages != null ||
      avoidedTrope != null;
}

class RecommendationConstraintExtractor {
  const RecommendationConstraintExtractor();

  RecommendationConstraints extract({
    required String userMessage,
    required List<CoachMessage> conversation,
  }) {
    final current = _normalize(userMessage);
    if (_isNonRecommendationIntent(current)) {
      return const RecommendationConstraints();
    }

    final userTurns = [
      ...conversation
          .where((message) => message.role == CoachMessageRole.user)
          .map((message) => message.content),
      userMessage,
    ];
    var start = userTurns.lastIndexWhere(
      (message) => _startsExternalRecommendation(_normalize(message)),
    );
    if (start < 0) return const RecommendationConstraints();

    var outsideLibrary = false;
    var standalone = false;
    var completedSeries = false;
    String? authorGender;
    String? genre;
    String? format;
    String? language;
    int? maxPages;
    String? avoidedTrope;

    for (final rawTurn in userTurns.skip(start)) {
      final turn = _normalize(rawTurn);
      if (_removesSeriesRestriction(turn)) {
        standalone = false;
        completedSeries = false;
      }
      if (turn.contains('fuera de mi biblioteca') ||
          turn.contains('no este en mi biblioteca') ||
          turn.contains('no este ya en mi biblioteca')) {
        outsideLibrary = true;
      }
      if (turn.contains('autoconclusiv') || turn.contains('standalone')) {
        standalone = true;
      }
      if (turn.contains('saga terminada') ||
          turn.contains('saga completa') ||
          turn.contains('fantasia cerrada')) {
        completedSeries = true;
      }
      if (turn.contains('escrit') && turn.contains('mujer') ||
          turn.contains('escrita por una autora')) {
        authorGender = 'mujer';
      }
      if (turn.contains('fantasia')) genre = 'fantasia';
      if (turn.contains('ciencia ficcion')) genre = 'ciencia ficcion';
      if (turn.contains('romance')) genre = 'romance';
      if (turn.contains('audiolibro')) format = 'audiolibro';
      if (turn.contains('ebook') || turn.contains('libro electronico')) {
        format = 'ebook';
      }
      if (turn.contains('tapa dura')) format = 'tapa dura';
      if (turn.contains('tapa blanda')) format = 'tapa blanda';
      if (turn.contains(' en espanol') || turn.contains('idioma espanol')) {
        language = 'es';
      }
      final pages = RegExp(
        r'(?:maximo|menos de|hasta)\s+(\d{2,4})\s+paginas',
      ).firstMatch(turn);
      if (pages != null) maxPages = int.tryParse(pages.group(1)!);
      final avoided = RegExp(r'(?:sin|evita)\s+([a-z ]+?)(?:\.|,|$)')
          .firstMatch(turn);
      if (avoided != null) avoidedTrope = avoided.group(1)?.trim();
    }

    return RecommendationConstraints(
      requiresExternalSearch: true,
      outsideLibrary: outsideLibrary,
      standalone: standalone,
      completedSeries: completedSeries,
      authorGender: authorGender,
      genre: genre,
      format: format,
      language: language,
      maxPages: maxPages,
      avoidedTrope: avoidedTrope,
    );
  }

  bool _startsExternalRecommendation(String value) {
    final recommendation = value.contains('recomiend') ||
        value.contains('quiero') ||
        value.contains('que puedo leer') ||
        value.contains('busco');
    final bookish = value.contains('libro') ||
        value.contains('lectura') ||
        value.contains('fantasia') ||
        value.contains('novela');
    final explicitlyExternal = value.contains('fuera de mi biblioteca') ||
        value.contains('no este en mi biblioteca') ||
        value.contains('libro externo') ||
        value.contains('descubrir algo nuevo');
    return recommendation && bookish && explicitlyExternal;
  }

  bool _isNonRecommendationIntent(String value) =>
      value.contains('progreso') ||
      value.contains('paginas lei') ||
      value.contains('habito') ||
      value.contains('racha') ||
      value.contains('resume mi');

  bool _removesSeriesRestriction(String value) =>
      value.contains('da igual que sea una saga') ||
      value.contains('puede ser una saga') ||
      value.contains('no importa que sea una saga');
}

String normalizeRecommendationText(String value) {
  const accents = {
    'á': 'a', 'à': 'a', 'ä': 'a', 'â': 'a',
    'é': 'e', 'è': 'e', 'ë': 'e', 'ê': 'e',
    'í': 'i', 'ì': 'i', 'ï': 'i', 'î': 'i',
    'ó': 'o', 'ò': 'o', 'ö': 'o', 'ô': 'o',
    'ú': 'u', 'ù': 'u', 'ü': 'u', 'û': 'u',
    'ñ': 'n', 'ç': 'c',
  };
  return value
      .toLowerCase()
      .split('')
      .map((character) => accents[character] ?? character)
      .join()
      .replaceAll(RegExp(r'[^a-z0-9\s]'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

String _normalize(String value) => normalizeRecommendationText(value);
