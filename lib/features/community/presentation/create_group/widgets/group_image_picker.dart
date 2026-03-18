import 'dart:io';

import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_dimensions.dart';

class GroupImagePicker extends StatelessWidget {
  final File? imageFile;
  final bool isDark;
  final VoidCallback onTap;

  const GroupImagePicker({
    super.key,
    required this.imageFile,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.backgroundGrey,
          borderRadius: BorderRadius.circular(AppDimensions.radius12),
        ),
        child: imageFile != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(AppDimensions.radius12),
                child: Image.file(imageFile!, fit: BoxFit.cover),
              )
            : Icon(
                Icons.add_a_photo,
                color: isDark ? AppColors.textWhite : AppColors.textBlack,
                size: 28,
              ),
      ),
    );
  }
}
