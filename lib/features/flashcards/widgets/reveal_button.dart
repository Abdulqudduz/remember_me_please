import 'package:flutter/material.dart';
import 'package:remember_me_please/core/theme/app_theme.dart';

class RevealButton extends StatelessWidget {
  final VoidCallback onTap;

  const RevealButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.tertiary, AppColors.tertiaryContainer],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.visibility, color: AppColors.onTertiary, size: 24),
            SizedBox(width: 8),
            Text(
              'Reveal',
              style: TextStyle(
                color: AppColors.onTertiary,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
