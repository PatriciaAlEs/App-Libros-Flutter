import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
      imageAsset: 'assets/images/onboarding/slide_1.png',
      title: 'Tu biblioteca personal',
      message:
          'Organiza tus lecturas, guarda tus libros favoritos y sigue tu progreso página a página.',
    ),
    _OnboardingPageData(
      imageAsset: 'assets/images/onboarding/slide_2.png',
      title: 'Convierte la lectura en un hábito',
      message:
          'Registra páginas, tiempo y sesiones de lectura con un solo toque.',
    ),
    _OnboardingPageData(
      imageAsset: 'assets/images/onboarding/slide_3.png',
      title: 'Descubre tu perfil lector',
      message:
          'Autores favoritos, géneros preferidos, estadísticas e insights sobre tu forma de leer.',
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
              theme.colorScheme.primaryContainer.withValues(alpha: 0.16),
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
                const SizedBox(height: AppSpacing.lg),
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

    return Column(
      children: [
        Expanded(
          child: Center(
            child: _OnboardingIllustration(
              imageAsset: data.imageAsset,
              index: index,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        Text(
          data.title,
          textAlign: TextAlign.center,
          style: theme.textTheme.displaySmall?.copyWith(
            fontWeight: FontWeight.w900,
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
  const _OnboardingIllustration({
    required this.imageAsset,
    required this.index,
  });

  final String imageAsset;
  final int index;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      constraints: const BoxConstraints(maxWidth: 350, maxHeight: 390),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(34),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.14),
            blurRadius: 32,
            offset: const Offset(0, 18),
          ),
          BoxShadow(
            color: theme.colorScheme.secondary.withValues(alpha: 0.10),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(34),
        child: Image.asset(
          imageAsset,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              width: double.infinity,
              height: 330,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: theme.colorScheme.surface.withValues(alpha: 0.76),
                borderRadius: BorderRadius.circular(34),
                border: Border.all(
                  color: theme.colorScheme.primary.withValues(alpha: 0.10),
                ),
              ),
              child: Icon(
                index == 0
                    ? AppIcons.library
                    : index == 1
                    ? AppIcons.calendar
                    : AppIcons.insightsNav,
                color: theme.colorScheme.primary,
                size: 44,
              ),
            );
          },
        ),
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
    required this.imageAsset,
    required this.title,
    required this.message,
  });

  final String imageAsset;
  final String title;
  final String message;
}
