import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
    final commaIndex = greetingText.indexOf(',');
    final greetingLead = commaIndex == -1
        ? greetingText
        : greetingText.substring(0, commaIndex + 1);
    final greetingName = commaIndex == -1
        ? ''
        : greetingText.substring(commaIndex + 1).trim();

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
            RichText(
              text: TextSpan(
                style: GoogleFonts.cormorantGaramond(
                  textStyle: theme.textTheme.headlineSmall?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.88),
                    fontSize: 26,
                    fontWeight: FontWeight.w600,
                    height: 1.08,
                  ),
                ),
                children: [
                  TextSpan(
                    text: greetingName.isEmpty
                        ? '$greetingLead \u{1F44B}'
                        : '$greetingLead\n',
                  ),
                  if (greetingName.isNotEmpty)
                    TextSpan(
                      text: '$greetingName \u{1F44B}',
                      style: GoogleFonts.cormorantGaramond(
                        textStyle: theme.textTheme.displaySmall?.copyWith(
                          color: colorScheme.primary,
                          fontSize: 34,
                          fontWeight: FontWeight.w700,
                          height: 1.02,
                        ),
                      ),
                    ),
                ],
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
