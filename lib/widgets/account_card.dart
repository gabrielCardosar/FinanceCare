import 'package:flutter/material.dart';
import '../utils/constants.dart';

class AccountCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final Color? backgroundColor;
  final Color? valueColor;
  final IconData? icon;

  const AccountCard({
    Key? key,
    required this.title,
    required this.value,
    required this.subtitle,
    this.backgroundColor,
    this.valueColor,
    this.icon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor ??
            (isDark ? AppColors.darkCardBg : AppColors.lightCardBg),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: isDark ? AppColors.darkSubText : AppColors.lightSubText,
                      fontWeight: FontWeight.w500,
                    ),
              ),
              if (icon != null)
                Icon(icon, color: AppColors.primary, size: 20),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: valueColor,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: isDark ? AppColors.darkSubText : AppColors.lightSubText,
                ),
          ),
        ],
      ),
    );
  }
}