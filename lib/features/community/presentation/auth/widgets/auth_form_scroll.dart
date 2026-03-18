import 'package:flutter/material.dart';
import '../../../../../core/constants/app_dimensions.dart';

/// Scrollable form container for auth screens with consistent padding.
class AuthFormScroll extends StatelessWidget {
  final Widget child;

  const AuthFormScroll({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.padding24,
        vertical: AppDimensions.padding16,
      ),
      child: child,
    );
  }
}
