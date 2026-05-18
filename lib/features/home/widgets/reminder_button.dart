import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class ReminderButton extends StatelessWidget {
  final IconData? icon;
  final String label;
  final Color? backgroundColor;
  final Color contentColor;
  final VoidCallback onTap;
  const ReminderButton({
    super.key,
    this.icon,
    required this.label,
    this.backgroundColor,
    required this.contentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      // padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        // Replaced hardcoded Colors.transparent with AppColors.transparent to match design system
        color: backgroundColor ?? AppColors.transparent,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(label),
    );
  }
}
