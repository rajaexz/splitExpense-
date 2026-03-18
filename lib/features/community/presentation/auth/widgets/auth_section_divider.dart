import 'package:flutter/material.dart';

/// Centered text divider for auth sections (e.g. "Or login with")
class AuthSectionDivider extends StatelessWidget {
  final String text;

  const AuthSectionDivider({
    super.key,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(text, style: theme.textTheme.bodyMedium),
      ],
    );
  }
}
