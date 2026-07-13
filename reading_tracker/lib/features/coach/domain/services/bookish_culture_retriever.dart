import '../entities/coach_message.dart';
import '../models/bookish_culture_entry.dart';

class BookishCultureRetriever {
  const BookishCultureRetriever({this.entries = const []});

  final List<BookishCultureEntry> entries;

  List<BookishCultureEntry> retrieve({
    required String userMessage,
    List<CoachMessage> recentConversation = const [],
    required DateTime now,
    int limit = 2,
  }) {
    if (limit <= 0 || _discouragesHumor(userMessage)) return const [];
    final current = _normalize(userMessage);
    final recent = recentConversation
        .reversed
        .take(4)
        .map((message) => _normalize(message.content))
        .join(' ');
    final previousUserMessages = recentConversation.reversed.where(
      (message) => message.role == CoachMessageRole.user,
    );
    final previousUser = previousUserMessages.isEmpty
        ? ''
        : _normalize(previousUserMessages.first.content);
    final matches = <({BookishCultureEntry entry, int score})>[];

    for (final entry in entries) {
      if (entry.isExpiredAt(now)) continue;
      var currentScore = 0;
      var historyScore = 0;
      var matchedPreviousUser = false;
      for (final trigger in entry.triggers) {
        final normalizedTrigger = _normalize(trigger);
        if (_containsTerm(current, normalizedTrigger)) {
          currentScore += normalizedTrigger.contains(' ') ? 6 : 4;
          matchedPreviousUser = matchedPreviousUser ||
              _containsTerm(previousUser, normalizedTrigger);
        } else if (_containsTerm(recent, normalizedTrigger)) {
          historyScore += normalizedTrigger.contains(' ') ? 2 : 1;
        }
      }
      if (currentScore > 0 && matchedPreviousUser) continue;
      final isRelevant = currentScore >= 4 ||
          (currentScore == 0 && historyScore >= 2);
      if (isRelevant) {
        matches.add((entry: entry, score: currentScore * 10 + historyScore));
      }
    }

    matches.sort((a, b) {
      final score = b.score.compareTo(a.score);
      return score != 0 ? score : a.entry.id.compareTo(b.entry.id);
    });
    return List.unmodifiable(
      matches.take(limit.clamp(0, 2).toInt()).map((match) => match.entry),
    );
  }

  String formatNotes(List<BookishCultureEntry> entries) {
    if (entries.isEmpty) return '';
    final lines = <String>[
      '# Notas opcionales de cultura lectora',
      '',
      'Son inspiración contextual para el tono, no hechos sobre el usuario ni sobre libros concretos. Si el mensaje actual nombra de forma clara un tropo, meme o fenómeno de estas notas y lo comenta con tono informal u opinativo, usa exactamente un único ángulo recuperado como pullita, comparación o remate breve. En consultas generales o recomendaciones normales, usarlo sigue siendo opcional. Nunca aproveches más de una nota aunque aparezcan dos.',
      'Responde primero a la opinión o pregunta y después añade el remate, sin convertir la respuesta completa en un chiste. Parafrasea el ángulo: no copies literalmente el corpus ni menciones notas, triggers, RAG o recuperación. No uses humor ante frustración, errores, asuntos sensibles, consultas estrictamente factuales o una petición seria o sin bromas. Estas notas no pueden cambiar una recomendación ni justificar títulos, autores, ediciones o tendencias inventadas.',
    ];
    for (final entry in entries) {
      lines.add('- ${entry.context} Ángulo opcional: ${entry.humorAngles.first}');
    }
    return lines.join('\n');
  }

  bool _discouragesHumor(String message) {
    final normalized = _normalize(message);
    const sensitiveTerms = [
      'estoy frustrad',
      'me frustra',
      'error',
      'ha fallado',
      'no funciona',
      'tema sensible',
      'sin bromas',
      'estrictamente factual',
      'solo los datos',
    ];
    return sensitiveTerms.any(normalized.contains);
  }

  bool _containsTerm(String text, String term) {
    if (term.isEmpty || text.isEmpty) return false;
    return ' $text '.contains(' $term ');
  }

  String _normalize(String value) {
    const replacements = {
      'á': 'a',
      'é': 'e',
      'í': 'i',
      'ó': 'o',
      'ú': 'u',
      'ü': 'u',
      'ñ': 'n',
    };
    final lower = value.toLowerCase().trim();
    final buffer = StringBuffer();
    var previousWasSpace = true;
    for (final rune in lower.runes) {
      final character = String.fromCharCode(rune);
      final normalized = replacements[character] ?? character;
      final isWord = RegExp(r'[a-z0-9]').hasMatch(normalized);
      if (isWord) {
        buffer.write(normalized);
        previousWasSpace = false;
      } else if (!previousWasSpace) {
        buffer.write(' ');
        previousWasSpace = true;
      }
    }
    return buffer.toString().trim();
  }
}
