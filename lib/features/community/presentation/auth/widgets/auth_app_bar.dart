import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_fonts.dart';

/// Reusable auth app bar with back button and centered title.
class AuthAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final Color? foregroundColor;
  final bool showBackButton;

  const AuthAppBar({
    super.key,
    required this.title,
    this.foregroundColor,
    this.showBackButton = true,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final color = foregroundColor ?? AppColors.textBlack;

    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: showBackButton
          ? IconButton(
              icon: Icon(Icons.arrow_back, color: color),
              onPressed: () {
                if (context.canPop()) context.pop();
              },
            )
          : null,
      centerTitle: true,
      title: Text(
        title,
        style: TextStyle(
          color: color,
          fontSize: AppFonts.fontSize18,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
