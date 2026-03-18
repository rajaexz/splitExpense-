import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_dimensions.dart';
import '../../../../../core/constants/app_fonts.dart';
import '../../../../../data/models/shared_gallery_model.dart';

/// Card for displaying a shared gallery (used in SharedWithMe and SharedByMe tabs).
class GalleryCard extends StatelessWidget {
  final SharedGalleryModel gallery;
  final bool isDark;
  final VoidCallback onTap;
  final String? title;
  final String? subtitle;
  final VoidCallback? onDelete;

  const GalleryCard({
    super.key,
    required this.gallery,
    required this.isDark,
    required this.onTap,
    this.title,
    this.subtitle,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final thumbUrl = gallery.imageUrls.isNotEmpty ? gallery.imageUrls.first : null;
    final displayTitle = title ?? '${gallery.ownerName}\'s Gallery';
    final hasCustomSubtitle = subtitle != null && subtitle!.isNotEmpty;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppDimensions.margin16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.backgroundWhite,
          borderRadius: BorderRadius.circular(AppDimensions.radius16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppDimensions.radius16),
                bottomLeft: Radius.circular(AppDimensions.radius16),
              ),
              child: SizedBox(
                width: 100,
                height: 100,
                child: thumbUrl != null
                    ? CachedNetworkImage(
                        imageUrl: thumbUrl,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(
                          color: AppColors.backgroundGrey,
                          child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                        ),
                        errorWidget: (_, __, ___) => Container(
                          color: AppColors.backgroundGrey,
                          child: Icon(Icons.photo_library, color: AppColors.textGrey),
                        ),
                      )
                    : Container(
                        color: AppColors.backgroundGrey,
                        child: Icon(Icons.photo_library, size: 40, color: AppColors.textGrey),
                      ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(AppDimensions.padding16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.photo_library, size: 20, color: AppColors.primaryGreen),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            displayTitle,
                            style: TextStyle(
                              fontSize: AppFonts.fontSize16,
                              fontWeight: FontWeight.bold,
                              color: isDark ? AppColors.textWhite : AppColors.textBlack,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      hasCustomSubtitle
                          ? subtitle!
                          : '${gallery.imageUrls.length} photo(s)',
                      style: TextStyle(
                        fontSize: AppFonts.fontSize14,
                        color: AppColors.textGrey,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (!hasCustomSubtitle) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Tap to view & download',
                        style: TextStyle(
                          fontSize: AppFonts.fontSize12,
                          color: AppColors.primaryGreen,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            if (onDelete != null)
              IconButton(
                icon: Icon(Icons.delete_outline, size: 22, color: AppColors.error),
                onPressed: onDelete,
                tooltip: 'Delete',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              ),
            Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.textGrey),
            const SizedBox(width: 12),
          ],
        ),
      ),
    );
  }
}
