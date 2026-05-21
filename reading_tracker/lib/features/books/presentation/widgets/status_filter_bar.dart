import 'package:flutter/material.dart';

import '../../domain/enums/book_status.dart';

class StatusFilterBar extends StatelessWidget {
  const StatusFilterBar({
    super.key,
    required this.selectedStatus,
    required this.onChanged,
  });

  final BookStatus? selectedStatus;
  final ValueChanged<BookStatus?> onChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          ChoiceChip(
            label: const Text('Todos'),
            selected: selectedStatus == null,
            onSelected: (_) => onChanged(null),
          ),
          const SizedBox(width: 8),
          for (final status in BookStatus.values) ...[
            ChoiceChip(
              label: Text(status.label),
              selected: selectedStatus == status,
              onSelected: (_) => onChanged(status),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}
