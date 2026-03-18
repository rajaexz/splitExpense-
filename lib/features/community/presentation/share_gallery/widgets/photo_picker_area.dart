import 'dart:io';

import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_dimensions.dart';
import '../../../../../core/constants/app_fonts.dart';

/// Tap-to-select photo area with optional grid of selected images.
class PhotoPickerArea extends StatelessWidget {
  final List<File> selectedImages;
  final VoidCallback onTap;
  final void Function(int index) onRemoveImage;

  const PhotoPickerArea({
    super.key,
    required this.selectedImages,
    required this.onTap,
    required this.onRemoveImage,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            height: 120,
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : AppColors.backgroundGrey,
              borderRadius: BorderRadius.circular(AppDimensions.radius12),
              border: Border.all(
                color: AppColors.primaryGreen,
                style: BorderStyle.solid,
              ),
            ),
            child: selectedImages.isEmpty
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.photo_library, size: 48, color: AppColors.primaryGreen),
                      const SizedBox(height: 8),
                      Text(
                        'Tap to select photos',
                        style: TextStyle(
                          fontSize: AppFonts.fontSize14,
                          color: AppColors.textGrey,
                        ),
                      ),
                    ],
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(8),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      crossAxisSpacing: 4,
                      mainAxisSpacing: 4,
                      childAspectRatio: 1,
                    ),
                    itemCount: selectedImages.length,
                    itemBuilder: (context, i) {
                      return Stack(
                        fit: StackFit.expand,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(selectedImages[i], fit: BoxFit.cover),
                          ),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: GestureDetector(
                              onTap: () => onRemoveImage(i),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: AppColors.error,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.close, size: 16, color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
          ),
        ),
        if (selectedImages.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              '${selectedImages.length} photo(s) selected',
              style: TextStyle(fontSize: AppFonts.fontSize12, color: AppColors.textGrey),
            ),
          ),
      ],
    );
  }
}
