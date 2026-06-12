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

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 260;
        final logo = _HeaderLogo(theme: theme, compact: compact);
        final greetingText = Text(
          showGreeting ? '$greeting 👋' : '',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.primary.withValues(alpha: 0.82),
            fontWeight: FontWeight.w900,
          ),
        );

        return InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: onTap,
          child: compact
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    logo,
                    if (showGreeting) ...[
                      const SizedBox(height: AppSpacing.xs),
                      greetingText,
                    ],
                  ],
                )
              : Row(
                  children: [
                    logo,
                    if (showGreeting) ...[
                      const SizedBox(width: AppSpacing.md),
                      Expanded(child: greetingText),
                    ] else
                      const Spacer(),
                  ],
                ),
        );
      },
    );
  }
}

class _HeaderLogo extends StatelessWidget {
  const _HeaderLogo({required this.theme, required this.compact});

  final ThemeData theme;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final width = compact ? 142.0 : 168.0;
    final height = compact ? 58.0 : 68.0;

    return Container(
      width: width,
      height: height,
      alignment: Alignment.centerLeft,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: AppShadows.soft(theme.colorScheme.secondary),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Image.asset(
          AppBrand.headerLogoAsset,
          width: width,
          height: height,
          fit: BoxFit.contain,
          alignment: Alignment.centerLeft,
          errorBuilder: (context, error, stackTrace) => Container(
            width: 58,
            height: 58,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: theme.colorScheme.secondary.withValues(alpha: 0.68),
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
        ),
      ),
    );
  }
}

String _greeting() {
  final hour = DateTime.now().hour;
  if (hour < 12) return 'Buenos días';
  if (hour < 20) return 'Buenas tardes';
  return 'Buenas noches';
}
