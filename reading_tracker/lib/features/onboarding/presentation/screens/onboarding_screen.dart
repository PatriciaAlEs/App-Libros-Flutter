import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/branding/app_brand.dart';
import '../../../../core/design_system/design_system.dart';
import '../providers/onboarding_controller.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pageController = PageController();
  int _currentPage = 0;

  static const _pages = [
    _OnboardingPageData(
      title: 'Tu biblioteca personal',
      message:
          'Organiza tus lecturas, guarda tus libros favoritos y sigue tu progreso página a página.',
    ),
    _OnboardingPageData(
      title: 'Sigue tu avance lector',
      message:
          'Registra sesiones, páginas y tiempo de lectura para mantener tu hábito.',
    ),
    _OnboardingPageData(
      title: 'Descubre tu perfil lector',
      message:
          'Conoce tus hábitos, estadísticas y objetivos para leer más y mejor.',
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    await ref.read(onboardingControllerProvider.notifier).complete();
  }

  void _next() {
    if (_currentPage == _pages.length - 1) {
      _finish();
      return;
    }

    _pageController.nextPage(
      duration: AppMotion.normal,
      curve: AppMotion.emphasized,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLastPage = _currentPage == _pages.length - 1;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              theme.scaffoldBackgroundColor,
              theme.colorScheme.primaryContainer.withValues(alpha: 0.10),
              theme.scaffoldBackgroundColor,
            ],
            stops: const [0, 0.42, 1],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 16, 22, 24),
            child: Column(
              children: [
                Row(
                  children: [
                    const _BrandLogo(),
                    const Spacer(),
                    TextButton(onPressed: _finish, child: const Text('Omitir')),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: _pages.length,
                    onPageChanged: (page) =>
                        setState(() => _currentPage = page),
                    itemBuilder: (context, index) {
                      return _OnboardingPage(data: _pages[index], index: index);
                    },
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                _PageIndicator(
                  currentPage: _currentPage,
                  pageCount: _pages.length,
                ),
                const SizedBox(height: AppSpacing.xl),
                FilledButton(
                  onPressed: _next,
                  child: Text(isLastPage ? 'Empezar' : 'Siguiente'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BrandLogo extends StatelessWidget {
  const _BrandLogo();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      width: 156,
      height: 58,
      child: Image.asset(
        AppBrand.headerLogoAsset,
        fit: BoxFit.contain,
        alignment: Alignment.centerLeft,
        errorBuilder: (context, error, stackTrace) {
          return Align(
            alignment: Alignment.centerLeft,
            child: Text(
              AppBrand.name,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.w900,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  const _OnboardingPage({required this.data, required this.index});

  final _OnboardingPageData data;
  final int index;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final illustrationHeight = (MediaQuery.sizeOf(context).height * 0.40).clamp(
      260.0,
      390.0,
    );

    return Column(
      children: [
        SizedBox(
          height: illustrationHeight,
          child: Center(
            child: _OnboardingIllustration(
              index: index,
              maxHeight: illustrationHeight,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xxl),
        Text(
          data.title,
          textAlign: TextAlign.center,
          style: GoogleFonts.cormorantGaramond(
            textStyle: theme.textTheme.displaySmall?.copyWith(
              color: theme.colorScheme.primary,
              fontSize: 39,
              fontWeight: FontWeight.w700,
              height: 1.02,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          data.message,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontSize: 16,
            height: 1.45,
          ),
        ),
      ],
    );
  }
}

class _OnboardingIllustration extends StatelessWidget {
  const _OnboardingIllustration({required this.index, required this.maxHeight});

  final int index;
  final double maxHeight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      height: maxHeight,
      width: double.infinity,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            bottom: maxHeight * 0.10,
            child: Container(
              width: 250,
              height: 34,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          if (index == 0) const _LibraryIllustration(),
          if (index == 1) const _ProgressIllustration(),
          if (index == 2) const _InsightsIllustration(),
        ],
      ),
    );
  }
}

class _LibraryIllustration extends StatelessWidget {
  const _LibraryIllustration();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      width: 300,
      height: 280,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(top: 18, child: _SoftCircle(size: 210, alpha: 0.14)),
          Positioned(
            left: 28,
            bottom: 70,
            child: _BookSpine(
              width: 44,
              height: 134,
              color: theme.colorScheme.primary,
              rotation: -0.10,
            ),
          ),
          Positioned(
            left: 78,
            bottom: 62,
            child: _BookSpine(
              width: 52,
              height: 158,
              color: theme.colorScheme.secondary,
              rotation: 0.04,
            ),
          ),
          Positioned(
            right: 82,
            bottom: 65,
            child: _BookSpine(
              width: 48,
              height: 146,
              color: Color.lerp(theme.colorScheme.primary, Colors.black, 0.18)!,
              rotation: -0.03,
            ),
          ),
          Positioned(
            right: 28,
            bottom: 74,
            child: _BookSpine(
              width: 42,
              height: 124,
              color: theme.colorScheme.tertiary,
              rotation: 0.10,
            ),
          ),
          Positioned(
            bottom: 52,
            child: Container(
              width: 260,
              height: 18,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.20),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          const Positioned(
            top: 54,
            right: 46,
            child: _Spark(icon: AppIcons.star, size: 30),
          ),
          const Positioned(
            top: 92,
            left: 42,
            child: _Spark(icon: AppIcons.bookmark, size: 24),
          ),
        ],
      ),
    );
  }
}

class _ProgressIllustration extends StatelessWidget {
  const _ProgressIllustration();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      width: 310,
      height: 280,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(top: 16, child: _SoftCircle(size: 220, alpha: 0.12)),
          Positioned(
            bottom: 72,
            child: Transform.rotate(
              angle: -0.05,
              child: Container(
                width: 178,
                height: 210,
                padding: const EdgeInsets.fromLTRB(24, 26, 24, 22),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface.withValues(alpha: 0.96),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: theme.colorScheme.primary.withValues(alpha: 0.16),
                  ),
                  boxShadow: AppShadows.editorial(theme.colorScheme.primary),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 74,
                      height: 10,
                      decoration: _lineDecoration(theme, alpha: 0.24),
                    ),
                    const SizedBox(height: 18),
                    Container(
                      width: 128,
                      height: 8,
                      decoration: _lineDecoration(theme, alpha: 0.12),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      width: 100,
                      height: 8,
                      decoration: _lineDecoration(theme, alpha: 0.12),
                    ),
                    const Spacer(),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: 0.68,
                        minHeight: 10,
                        backgroundColor: theme.colorScheme.primaryContainer
                            .withValues(alpha: 0.28),
                        color: theme.colorScheme.secondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const Positioned(
            right: 54,
            top: 66,
            child: _FloatingBadge(icon: AppIcons.bookmark),
          ),
          const Positioned(
            left: 42,
            bottom: 82,
            child: _FloatingBadge(icon: AppIcons.time),
          ),
        ],
      ),
    );
  }
}

class _InsightsIllustration extends StatelessWidget {
  const _InsightsIllustration();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      width: 310,
      height: 280,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(top: 14, child: _SoftCircle(size: 220, alpha: 0.12)),
          Positioned(
            bottom: 64,
            child: Container(
              width: 218,
              height: 184,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface.withValues(alpha: 0.96),
                borderRadius: BorderRadius.circular(32),
                border: Border.all(
                  color: theme.colorScheme.primary.withValues(alpha: 0.16),
                ),
                boxShadow: AppShadows.editorial(theme.colorScheme.primary),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: const [
                  _ChartBar(height: 54, alpha: 0.28),
                  SizedBox(width: 12),
                  _ChartBar(height: 98, alpha: 0.72),
                  SizedBox(width: 12),
                  _ChartBar(height: 76, alpha: 0.44),
                  SizedBox(width: 12),
                  _ChartBar(height: 124, alpha: 0.86),
                ],
              ),
            ),
          ),
          const Positioned(
            top: 58,
            right: 48,
            child: _FloatingBadge(icon: AppIcons.star),
          ),
          const Positioned(
            top: 84,
            left: 44,
            child: _FloatingBadge(icon: AppIcons.insightsNav),
          ),
        ],
      ),
    );
  }
}

class _BookSpine extends StatelessWidget {
  const _BookSpine({
    required this.width,
    required this.height,
    required this.color,
    required this.rotation,
  });

  final double width;
  final double height;
  final Color color;
  final double rotation;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: rotation,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.22),
              blurRadius: 24,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: Align(
          alignment: Alignment.topCenter,
          child: Container(
            margin: const EdgeInsets.only(top: 18),
            width: width * 0.46,
            height: 6,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.42),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        ),
      ),
    );
  }
}

class _SoftCircle extends StatelessWidget {
  const _SoftCircle({required this.size, required this.alpha});

  final double size;
  final double alpha;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: theme.colorScheme.secondary.withValues(alpha: alpha),
      ),
    );
  }
}

class _FloatingBadge extends StatelessWidget {
  const _FloatingBadge({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: 54,
      height: 54,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.94),
        shape: BoxShape.circle,
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.14),
        ),
        boxShadow: AppShadows.editorial(theme.colorScheme.primary),
      ),
      child: Icon(icon, color: theme.colorScheme.primary, size: 26),
    );
  }
}

class _Spark extends StatelessWidget {
  const _Spark({required this.icon, required this.size});

  final IconData icon;
  final double size;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Icon(
      icon,
      color: theme.colorScheme.primary.withValues(alpha: 0.66),
      size: size,
    );
  }
}

class _ChartBar extends StatelessWidget {
  const _ChartBar({required this.height, required this.alpha});

  final double height;
  final double alpha;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Expanded(
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withValues(alpha: alpha),
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    );
  }
}

BoxDecoration _lineDecoration(ThemeData theme, {required double alpha}) {
  return BoxDecoration(
    color: theme.colorScheme.primary.withValues(alpha: alpha),
    borderRadius: BorderRadius.circular(999),
  );
}

class _PageIndicator extends StatelessWidget {
  const _PageIndicator({required this.currentPage, required this.pageCount});

  final int currentPage;
  final int pageCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var index = 0; index < pageCount; index++) ...[
          AnimatedContainer(
            duration: AppMotion.fast,
            curve: AppMotion.standard,
            width: index == currentPage ? 26 : 8,
            height: 8,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              color: index == currentPage
                  ? theme.colorScheme.primary.withValues(alpha: 0.82)
                  : theme.colorScheme.primary.withValues(alpha: 0.16),
            ),
          ),
          if (index < pageCount - 1) const SizedBox(width: AppSpacing.sm),
        ],
      ],
    );
  }
}

class _OnboardingPageData {
  const _OnboardingPageData({required this.title, required this.message});

  final String title;
  final String message;
}
