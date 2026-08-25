import 'package:flutter/material.dart';

import '../../theme/nightTheme.dart';

class StudentLabIconSurface extends StatelessWidget {
  final IconData? icon;
  final Widget? child;
  final Color accent;
  final double size;
  final double iconSize;
  final double borderRadius;

  const StudentLabIconSurface({
    super.key,
    this.icon,
    this.child,
    this.accent = AppColors.adminCyan,
    this.size = 44,
    this.iconSize = 22,
    this.borderRadius = 13,
  }) : assert(
          icon != null || child != null,
          'Serve icon oppure child.',
        );

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(1.5),
      decoration: BoxDecoration(
        gradient: AppColors.adminIconGradient,
        borderRadius: BorderRadius.circular(
          borderRadius,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: AppColors.adminDarkSurfaceGradient,
          borderRadius: BorderRadius.circular(
            borderRadius - 1.5,
          ),
        ),
        alignment: Alignment.center,
        child: child ??
            Icon(
              icon,
              color: accent,
              size: iconSize,
            ),
      ),
    );
  }
}