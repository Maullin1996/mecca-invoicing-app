import 'package:flutter/material.dart';
import 'package:mecca/core/theme/app_colors.dart';

class EmptyScreenWidget extends StatelessWidget {
  final String title;
  final String gift;
  const EmptyScreenWidget({super.key, required this.title, required this.gift});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(maxWidth: 300),
      padding: EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 150),
            child: Image.asset(gift, cacheHeight: 600, cacheWidth: 600),
          ),
          const SizedBox(height: 24),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
