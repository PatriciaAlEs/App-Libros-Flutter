import 'package:flutter/material.dart';

import '../../preferences/reader_profile_controller.dart';
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

  String get _greeting {
    final trimmedName = readerName.trim();
    if (trimmedName.isEmpty) {
      return 'Hola, Lectora';
    }
    return 'Hola, $trimmedName';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final greetingText =
        readerProfile?.homeGreeting(DateTime.now()) ?? _greeting;

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 280;
        final logoWidth = compact ? 150.0 : 184.0;
        final logoHeight = compact ? 56.0 : 68.0;

        final logo = _HeaderLogo(
          width: logoWidth,
          height: logoHeight,
          colorScheme: colorScheme,
        );

        final headerLogo = onTap == null
            ? logo
            : InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(18),
                child: logo,
              );

        if (!showGreeting) {
          return Align(alignment: Alignment.centerLeft, child: headerLogo);
        }

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            headerLogo,
            const SizedBox(height: 8),
            Text(
              '$greetingText 👋',
              softWrap: true,
              overflow: TextOverflow.visible,
              style: theme.textTheme.titleLarge?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w800,
                height: 1.15,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _HeaderLogo extends StatelessWidget {
  const _HeaderLogo({
    required this.width,
    required this.height,
    required this.colorScheme,
  });

  final double width;
  final double height;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: Image.asset(
        AppBrand.headerLogoAsset,
        fit: BoxFit.contain,
        alignment: Alignment.centerLeft,
        errorBuilder: (context, error, stackTrace) {
          return Align(
            alignment: Alignment.centerLeft,
            child: Container(
              width: height,
              height: height,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Text(
                AppBrand.symbol,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
