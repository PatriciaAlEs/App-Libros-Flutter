import '../models/bibliographic_candidate.dart';
import '../models/recommendation_constraints.dart';
import 'bibliographic_verification_service.dart';

class VerifiedBibliographicContextFormatter {
  const VerifiedBibliographicContextFormatter();

  String format({
    required RecommendationConstraints constraints,
    required BibliographicVerificationResult result,
  }) {
    final lines = <String>[
      '# Candidatos bibliográficos verificados',
      '',
      'Esta sección no forma parte de la biblioteca de la persona.',
      'Para esta petición recomienda exclusivamente títulos incluidos aquí. No añadas títulos externos por conocimiento propio.',
      if (constraints.hasBibliographicRestrictions)
        'Todos los filtros obligatorios ya se han aplicado antes de crear esta lista.',
    ];
    if (result.verifiedCandidates.isEmpty) {
      lines.add(
        'No he encontrado una opción que pueda verificar con todos esos filtros.',
      );
      if (result.blockingFields.isNotEmpty) {
        lines.add(
          'Condición bloqueante: ${result.blockingFields.toList()..sort()}',
        );
      }
      lines.add(
        'Explica solo la condición bloqueante más relevante y, como máximo, propone flexibilizar una.',
      );
      return lines.join('\n');
    }

    for (final candidate in result.verifiedCandidates) {
      final metadata = <String>[
        'Título: ${candidate.title}',
        'Título normalizado: ${candidate.normalizedTitle}',
        if (candidate.authors.isNotEmpty)
          'Autoría: ${candidate.authors.join(', ')}',
        if (candidate.isbn != null) 'ISBN: ${candidate.isbn}',
        if (candidate.categories.isNotEmpty)
          'Categorías: ${candidate.categories.join(', ')}',
        if (candidate.language != null) 'Idioma: ${candidate.language}',
        if (candidate.pageCount != null)
          'Páginas: ${candidate.pageCount}',
        if (candidate.publishedYear != null)
          'Publicación: ${candidate.publishedYear}',
        'Fuente: ${candidate.source}',
        'Condiciones verificadas: ${candidate.evidence.where((item) => item.isMandatory && item.level == BibliographicVerificationLevel.verified).map((item) => item.field).join(', ')}',
        'Evidencia: ${candidate.evidence.map((item) => '${item.field}=${item.level.name}').join(', ')}',
      ];
      lines.add('- ${metadata.join(' | ')}');
    }
    return lines.join('\n');
  }
}
