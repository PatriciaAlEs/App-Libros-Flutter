import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart';

class LibreriaMetricCard extends StatelessWidget {
  const LibreriaMetricCard({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    required this.period,
  });

  final IconData icon;
  final String value;
  final String label;
  final String period;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$label: $value. Periodo: $period',
      child: ExcludeSemantics(
        child: MetricCard(
          icon: icon,
          value: value,
          label: label,
          subtitle: period,
        ),
      ),
    );
  }
}
