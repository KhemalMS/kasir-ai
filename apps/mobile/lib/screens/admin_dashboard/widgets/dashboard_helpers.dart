import 'package:flutter/material.dart';
import '../../../../config/app_theme.dart';



Widget sectionCard({required String title, required IconData icon, required Widget child, Widget? trailing}) {
  return Container(
    decoration: BoxDecoration(
      color: AppTheme.cardDark,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppTheme.surfaceDark),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
          child: Row(
            children: [
              Icon(icon, size: 20, color: AppTheme.primary),
              const SizedBox(width: 8),
              Expanded(child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white))),
              if (trailing != null) trailing,
            ],

          ),
        ),
        const Divider(height: 1, color: AppTheme.surfaceDark),
        child,
      ],
    ),
  );
}

num n(dynamic v) => v is num ? v : num.tryParse(v?.toString() ?? '') ?? 0;
