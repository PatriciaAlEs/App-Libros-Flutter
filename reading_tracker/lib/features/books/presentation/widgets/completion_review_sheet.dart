import 'package:flutter/material.dart';

class CompletionReview {
  const CompletionReview({this.rating, this.note});

  final double? rating;
  final String? note;

  bool get hasContent => rating != null || (note != null && note!.isNotEmpty);
}

class CompletionReviewSheet extends StatefulWidget {
  const CompletionReviewSheet({
    super.key,
    required this.title,
    this.initialRating,
    this.initialNote,
  });

  final String title;
  final double? initialRating;
  final String? initialNote;

  @override
  State<CompletionReviewSheet> createState() => _CompletionReviewSheetState();
}

class _CompletionReviewSheetState extends State<CompletionReviewSheet> {
  late double _rating;
  late final TextEditingController _noteController;

  @override
  void initState() {
    super.initState();
    _rating = widget.initialRating?.clamp(1, 5).toDouble() ?? 5;
    _noteController = TextEditingController(text: widget.initialNote ?? '');
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  void _save() {
    final note = _noteController.text.trim();
    Navigator.pop(
      context,
      CompletionReview(rating: _rating, note: note.isEmpty ? null : note),
    );
  }

  void _skip() {
    Navigator.pop(context, const CompletionReview());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(24, 0, 24, bottomInset + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Valora tu lectura',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            Semantics(
              label: 'Valoracion de ${_formatRating(_rating)} de 5 estrellas',
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (var index = 1; index <= 5; index++)
                        Icon(
                          _starIcon(index),
                          color: theme.colorScheme.primary,
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${_formatRating(_rating)} / 5',
                    style: theme.textTheme.titleMedium,
                  ),
                  Slider(
                    value: _rating,
                    min: 1,
                    max: 5,
                    divisions: 16,
                    label: _formatRating(_rating),
                    onChanged: (value) => setState(() => _rating = value),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _noteController,
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Resena u opinion corta',
                hintText: 'Opcional',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _save,
              child: const Text('Guardar valoracion'),
            ),
            const SizedBox(height: 8),
            TextButton(onPressed: _skip, child: const Text('Ahora no')),
          ],
        ),
      ),
    );
  }

  IconData _starIcon(int index) {
    if (_rating >= index) return Icons.star;
    if (_rating >= index - 0.5) return Icons.star_half;
    return Icons.star_border;
  }

  String _formatRating(double rating) {
    return rating.toStringAsFixed(rating % 1 == 0 ? 1 : 2);
  }
}
