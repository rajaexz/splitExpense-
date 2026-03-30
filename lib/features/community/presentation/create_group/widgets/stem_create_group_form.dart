import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/constants/app_colors.dart';

/// STEM-styled form field for Create Group.
class StemFormField extends StatelessWidget {
  final String label;
  final Widget child;

  const StemFormField({
    super.key,
    required this.label,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.manrope(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppColors.primaryGreen,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}
