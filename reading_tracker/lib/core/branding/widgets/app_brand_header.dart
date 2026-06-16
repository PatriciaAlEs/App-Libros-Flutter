import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../design_system/design_system.dart';
import '../../preferences/reader_profile_controller.dart';
import '../app_brand.dart';

class AppBrandHeader extends StatelessWidget {
  const AppBrandHeader({
    super.key,
    this.readerName = 'Lectora',
    this.readerProfile,
    this.showGreeting = true,
    this.onTap,
    this.onProfileTap,
    this.onAddBookTap,
    this.onCalendarTap,
  });

  final String readerName;
  final ReaderProfile? readerProfile;
  final bool showGreeting;
  final VoidCallback? onTap;
  final VoidCallback? onProfileTap;
  final VoidCallback? onAddBookTap;
  final VoidCallback? onCalendarTap;

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
        final compact = constraints.maxWidth < 320;
        final logoWidth = compact ? 156.0 : 184.0;
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
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(child: headerLogo),
                if (onProfileTap != null) ...[
                  const SizedBox(width: AppSpacing.md),
                  _BrandHeaderIconButton(
                    icon: AppIcons.profile,
                    tooltip: 'Perfil',
                    onTap: onProfileTap!,
                  ),
                ],
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            RichText(
              text: TextSpan(
                style: GoogleFonts.cormorantGaramond(
                  textStyle: theme.textTheme.headlineSmall?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.88),
                    fontSize: 28,
                    fontWeight: FontWeight.w600,
                    height: 1.05,
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
                          fontSize: 38,
                          fontWeight: FontWeight.w700,
                          height: 1,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (onAddBookTap != null || onCalendarTap != null) ...[
              const SizedBox(height: AppSpacing.md),
              Wrap(
                alignment: WrapAlignment.end,
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  if (onAddBookTap != null)
                    _BrandHeaderPillButton(
                      icon: AppIcons.add,
                      label: 'Libro',
                      onTap: onAddBookTap!,
                    ),
                  if (onCalendarTap != null)
                    _BrandHeaderPillButton(
                      icon: AppIcons.calendar,
                      label: 'Calendario',
                      onTap: onCalendarTap!,
                    ),
                ],
              ),
            ],
          ],
        );
      },
    );
  }
}

class _BrandHeaderPillButton extends StatelessWidget {
  const _BrandHeaderPillButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.surface.withValues(alpha: 0.94),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: theme.colorScheme.primary.withValues(alpha: 0.10),
            ),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.primary.withValues(alpha: 0.08),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: theme.colorScheme.primary, size: 18),
              const SizedBox(width: AppSpacing.sm),
              Text(
                label,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BrandHeaderIconButton extends StatelessWidget {
  const _BrandHeaderIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Tooltip(
      message: tooltip,
      child: Material(
        color: theme.colorScheme.surface.withValues(alpha: 0.72),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: theme.colorScheme.primary.withValues(alpha: 0.10),
              ),
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.primary.withValues(alpha: 0.07),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Icon(icon, color: theme.colorScheme.primary, size: 22),
          ),
        ),
      ),
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
