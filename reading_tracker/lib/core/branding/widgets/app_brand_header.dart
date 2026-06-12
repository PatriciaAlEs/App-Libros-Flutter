import 'package:flutter/material.dart';

import '../../design_system/design_system.dart';
import '../../preferences/reader_profile_controller.dart';
import '../../theme/app_typography.dart';
import '../app_brand.dart';

class AppBrandHeader extends StatelessWidget {
  const AppBrandHeader({
    super.key,
    this.readerName = 'Lectora',
    this.readerProfile,
    this.showGreeting = true,
    this.onTap,
  });

  final String readerName;
  final ReaderProfile? readerProfile;
  final bool showGreeting;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cleanName = readerName.trim();
    final displayName = cleanName.isEmpty ? 'Lectora' : cleanName;
    final greeting = readerProfile == null
        ? '${_greeting()}, $displayName'
        : readerProfile!.homeGreeting(DateTime.now());

    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: theme.colorScheme.secondary.withValues(alpha: 0.68),
              boxShadow: AppShadows.soft(theme.colorScheme.secondary),
            ),
            child: Text(
              AppBrand.symbol,
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontFamily: AppTypography.displayFontFamily,
                fontFamilyFallback: AppTypography.displayFallback,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppBrand.name,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (showGreeting) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    greeting,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.primary.withValues(alpha: 0.70),
                      letterSpacing: 1.6,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Buenos días';
    if (hour < 20) return 'Buenas tardes';
    return 'Buenas noches';
  }
}
