import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';

/// Auth scaffold with theme-aware background.
class AuthScaffold extends StatelessWidget {
  final PreferredSizeWidget? appBar;
  final Widget body;
  final bool isDark;

  const AuthScaffold({
    super.key,
    this.appBar,
    required this.body,
    this.isDark = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.backgroundWhite,
      appBar: appBar,
      body: body,
    );
  }
}
