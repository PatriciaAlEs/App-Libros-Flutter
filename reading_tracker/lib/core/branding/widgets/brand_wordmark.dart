import 'package:flutter/material.dart';

import '../../theme/app_typography.dart';
import '../app_brand.dart';

class BrandWordmark extends StatelessWidget {
  const BrandWordmark({
    super.key,
    this.assetPath,
    this.showDot = true,
    this.height,
    this.textStyle,
  });

  final String? assetPath;
  final bool showDot;
  final double? height;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    final path = assetPath;
    if (path != null && path.isNotEmpty) {
      return Image.asset(
        path,
        height: height,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) =>
            _FallbackWordmark(showDot: showDot, textStyle: textStyle),
      );
    }

    return _FallbackWordmark(showDot: showDot, textStyle: textStyle);
  }
}

class _FallbackWordmark extends StatelessWidget {
  const _FallbackWordmark({required this.showDot, this.textStyle});

  final bool showDot;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Text(
      showDot ? '${AppBrand.wordmark} \u2022' : AppBrand.wordmark,
      style:
          textStyle ??
          theme.textTheme.displaySmall?.copyWith(
            color: theme.colorScheme.primary,
            fontFamily: AppTypography.displayFontFamily,
            fontFamilyFallback: AppTypography.displayFallback,
            fontWeight: FontWeight.w800,
          ),
    );
  }
}
