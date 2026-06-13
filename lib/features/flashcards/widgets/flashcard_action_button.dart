import 'package:flutter/material.dart';
import 'package:remember_me_please/core/theme/app_theme.dart';

class FlashcardActionButton extends StatelessWidget {
  final VoidCallback onTap;
  final IconData icon;
  final String label;
  final Color? backgroundColor;
  final Color contentColor;

  const FlashcardActionButton({
    super.key,
    required this.onTap,
    required this.icon,
    required this.label,
    this.backgroundColor = AppColors.primary,
    this.contentColor = AppColors.onPrimary,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        // height: 72,
        decoration: BoxDecoration(
          color: backgroundColor!.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(12),
        ),

        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: contentColor, size: 20),
              Text(
                label,
                style: TextStyle(
                  color: contentColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
