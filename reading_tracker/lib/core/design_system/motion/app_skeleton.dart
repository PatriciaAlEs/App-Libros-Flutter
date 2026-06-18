import 'package:flutter/material.dart';

import '../../theme/app_theme_tokens.dart';
import 'app_motion.dart';

class AppSkeleton extends StatefulWidget {
  const AppSkeleton({super.key, required this.child, this.enabled = true});

  final Widget child;
  final bool enabled;

  @override
  State<AppSkeleton> createState() => _AppSkeletonState();
}

class _AppSkeletonState extends State<AppSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    if (widget.enabled) _controller.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant AppSkeleton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.enabled && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!widget.enabled && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final value = widget.enabled ? _controller.value : 0.35;
        final color = Color.lerp(
          theme.colorScheme.primary.withValues(alpha: 0.06),
          theme.colorScheme.primary.withValues(alpha: 0.14),
          value,
        )!;
        return IconTheme.merge(
          data: IconThemeData(color: color),
          child: DefaultTextStyle.merge(
            style: TextStyle(color: color),
            child: ColorFiltered(
              colorFilter: ColorFilter.mode(color, BlendMode.srcATop),
              child: child,
            ),
          ),
        );
      },
      child: widget.child,
    );
  }
}

class AppSearchSkeletonList extends StatelessWidget {
  const AppSearchSkeletonList({super.key, this.itemCount = 3});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppFadeSlideTransition(
      offset: const Offset(0, 0.02),
      duration: AppMotion.normal,
      child: Column(
        children: [
          for (var index = 0; index < itemCount; index++) ...[
            _SkeletonResultTile(
              color: theme.colorScheme.surface,
              borderColor: theme.colorScheme.primary.withValues(alpha: 0.07),
            ),
            if (index != itemCount - 1) const SizedBox(height: AppSpacing.sm),
          ],
        ],
      ),
    );
  }
}

class _SkeletonResultTile extends StatelessWidget {
  const _SkeletonResultTile({required this.color, required this.borderColor});

  final Color color;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: borderColor),
      ),
      child: AppSkeleton(
        child: Row(
          children: [
            const _SkeletonBlock(width: 54, height: 78, radius: 12),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  _SkeletonBlock(widthFactor: 0.78, height: 14),
                  SizedBox(height: 10),
                  _SkeletonBlock(widthFactor: 0.54, height: 10),
                  SizedBox(height: 8),
                  _SkeletonBlock(widthFactor: 0.42, height: 10),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SkeletonBlock extends StatelessWidget {
  const _SkeletonBlock({
    this.width,
    this.widthFactor,
    required this.height,
    this.radius = 999,
  });

  final double? width;
  final double? widthFactor;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final block = Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
      ),
    );

    final factor = widthFactor;
    if (factor == null) return block;
    return FractionallySizedBox(widthFactor: factor, child: block);
  }
}
