import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_motion.dart';

class AppPressable extends StatefulWidget {
  const AppPressable({
    super.key,
    required this.child,
    this.onTap,
    this.pressedScale = 0.98,
    this.borderRadius,
  });

  final Widget child;
  final VoidCallback? onTap;
  final double pressedScale;
  final BorderRadius? borderRadius;

  @override
  State<AppPressable> createState() => _AppPressableState();
}

class _AppPressableState extends State<AppPressable> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _isPressed ? widget.pressedScale : 1,
      duration: AppMotion.fast,
      curve: AppMotion.standard,
      child: InkWell(
        borderRadius: widget.borderRadius,
        onTap: widget.onTap == null
            ? null
            : () {
                HapticFeedback.selectionClick();
                widget.onTap!();
              },
        onTapDown: (_) => _setPressed(true),
        onTapCancel: () => _setPressed(false),
        onTapUp: (_) => _setPressed(false),
        child: widget.child,
      ),
    );
  }

  void _setPressed(bool value) {
    if (!mounted) return;
    setState(() => _isPressed = value);
  }
}
