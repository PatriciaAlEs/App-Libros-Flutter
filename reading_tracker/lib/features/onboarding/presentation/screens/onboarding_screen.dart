import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/branding/app_brand.dart';
import '../../../../core/design_system/design_system.dart';
import '../../../../core/theme/app_typography.dart';
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
      icon: AppIcons.library,
      title: 'Tu viaje lector, en un solo lugar',
      message:
          'Organiza tu biblioteca, sigue tu progreso y descubre tus hábitos de lectura.',
    ),
    _OnboardingPageData(
      icon: AppIcons.calendar,
      title: 'Registra tus lecturas',
      message:
          'Anota páginas, tiempo y sesiones para construir tu historial lector.',
    ),
    _OnboardingPageData(
      icon: AppIcons.insightsNav,
      title: 'Descubre tu perfil lector',
      message:
          'Explora estadísticas, rachas e insights sobre tu forma de leer.',
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
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 16, 22, 24),
          child: Column(
            children: [
              Row(
                children: [
                  const _BrandMark(),
                  const Spacer(),
                  TextButton(onPressed: _finish, child: const Text('Omitir')),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _pages.length,
                  onPageChanged: (page) => setState(() => _currentPage = page),
                  itemBuilder: (context, index) {
                    return _OnboardingPage(data: _pages[index], index: index);
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              _PageIndicator(
                currentPage: _currentPage,
                pageCount: _pages.length,
              ),
              const SizedBox(height: AppSpacing.xl),
              FilledButton(
                onPressed: _next,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(54),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                child: Text(isLastPage ? 'Empezar' : 'Siguiente'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Container(
          width: 46,
          height: 46,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: theme.colorScheme.secondary.withValues(alpha: 0.70),
            boxShadow: AppShadows.soft(theme.colorScheme.secondary),
          ),
          child: Text(
            'dP',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.primary,
              fontFamily: AppTypography.displayFontFamily,
              fontFamilyFallback: AppTypography.displayFallback,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Text(
          AppBrand.name,
          style: theme.textTheme.titleLarge?.copyWith(
            color: theme.colorScheme.primary,
            fontFamily: AppTypography.displayFontFamily,
            fontFamilyFallback: AppTypography.displayFallback,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
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

    return Column(
      children: [
        Expanded(
          child: Center(
            child: _OnboardingIllustration(icon: data.icon, index: index),
          ),
        ),
        const SizedBox(height: AppSpacing.xxl),
        Text(
          data.title,
          textAlign: TextAlign.center,
          style: theme.textTheme.displaySmall?.copyWith(
            fontWeight: FontWeight.w800,
            height: 1.08,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
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
  const _OnboardingIllustration({required this.icon, required this.index});

  final IconData icon;
  final int index;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final accent = theme.colorScheme.secondary;

    return AspectRatio(
      aspectRatio: 0.92,
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 330),
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [primary, Color.lerp(primary, Colors.black, 0.30)!],
          ),
          borderRadius: BorderRadius.circular(34),
          boxShadow: [
            BoxShadow(
              color: primary.withValues(alpha: 0.22),
              blurRadius: 34,
              offset: const Offset(0, 18),
            ),
          ],
        ),
        child: Stack(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: _SoftCircle(size: 76, color: accent),
            ),
            Align(
              alignment: Alignment.bottomLeft,
              child: _SoftCircle(size: 118, color: Colors.white),
            ),
            Center(
              child: _VisualCard(icon: icon, index: index),
            ),
          ],
        ),
      ),
    );
  }
}

class _VisualCard extends StatelessWidget {
  const _VisualCard({required this.icon, required this.index});

  final IconData icon;
  final int index;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.secondary;

    return Transform.rotate(
      angle: index == 1 ? -0.04 : 0.04,
      child: Container(
        width: 180,
        height: 228,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: accent.withValues(alpha: 0.28)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.16),
              blurRadius: 26,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accent.withValues(alpha: 0.24),
              ),
              child: Icon(icon, color: theme.colorScheme.primary, size: 26),
            ),
            const Spacer(),
            Container(
              height: 10,
              width: 112,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.82),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Container(
              height: 8,
              width: 76,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.72),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: index == 0
                    ? 0.34
                    : index == 1
                    ? 0.62
                    : 0.82,
                minHeight: 6,
                backgroundColor: accent.withValues(alpha: 0.20),
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SoftCircle extends StatelessWidget {
  const _SoftCircle({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.12),
      ),
    );
  }
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
                  ? theme.colorScheme.primary
                  : theme.colorScheme.primary.withValues(alpha: 0.18),
            ),
          ),
          if (index < pageCount - 1) const SizedBox(width: AppSpacing.sm),
        ],
      ],
    );
  }
}

class _OnboardingPageData {
  const _OnboardingPageData({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;
}
