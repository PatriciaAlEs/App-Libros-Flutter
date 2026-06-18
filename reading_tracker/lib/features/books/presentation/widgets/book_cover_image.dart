import 'dart:io';

import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart';

class BookCoverImage extends StatelessWidget {
  const BookCoverImage({
    super.key,
    required this.url,
    required this.width,
    required this.height,
    this.radius = 4,
    this.icon,
  });

  final String? url;
  final double width;
  final double height;
  final double radius;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final placeholder = _placeholder(context);
    final value = url;
    if (value == null || value.isEmpty) return placeholder;

    final uri = Uri.tryParse(value);
    if (uri != null && uri.scheme == 'file') {
      return ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Image.file(
          File.fromUri(uri),
          width: width,
          height: height,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => placeholder,
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Image.network(
        value,
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => placeholder,
      ),
    );
  }

  Widget _placeholder(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: width,
      height: height,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Icon(icon ?? AppIcons.book, color: theme.colorScheme.primary),
    );
  }
}
