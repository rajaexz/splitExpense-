import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_dimensions.dart';
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
    final displaySubtitle = (subtitle != null && subtitle!.isNotEmpty)
        ? subtitle!
        : _buildSharedSubtitle(gallery.createdAt);
    final count = gallery.imageUrls.length;

    // Figma card sizing: image takes most of the vertical space.
    final screenW = MediaQuery.of(context).size.width;
    final imageHeight = screenW * 0.595; // ~232 at 390px width

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppDimensions.radius24),
      child: Container(
        margin: const EdgeInsets.only(bottom: AppDimensions.margin24),
        decoration: BoxDecoration(
          color: AppColors.stemCard,
          borderRadius: BorderRadius.circular(AppDimensions.radius24),
          border: Border.all(
            color: AppColors.borderGreyDark.withValues(alpha: 0.15),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.padding16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppDimensions.radius20),
                    child: SizedBox(
                      width: double.infinity,
                      height: imageHeight,
                      child: thumbUrl == null
                          ? Container(
                              color: AppColors.backgroundGrey,
                              child: Icon(
                                Icons.photo_library_outlined,
                                size: 44,
                                color: AppColors.textGrey,
                              ),
                            )
                          : CachedNetworkImage(
                              imageUrl: thumbUrl,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                color: AppColors.backgroundGrey,
                                child: const Center(
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              ),
                              errorWidget: (_, __, ___) => Container(
                                color: AppColors.backgroundGrey,
                                child: Icon(
                                  Icons.photo_library_outlined,
                                  size: 44,
                                  color: AppColors.textGrey,
                                ),
                              ),
                            ),
                    ),
                  ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          color: const Color.fromRGBO(19, 19, 19, 0.6),
                          child: Text(
                            '$count Photos',
                            style: GoogleFonts.manrope(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppColors.stemEmerald,
                              letterSpacing: 0.55,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            displayTitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: AppColors.stemLightText,
                              letterSpacing: -0.1,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            displaySubtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.manrope(
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              color: AppColors.stemMutedText,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _CircleActionButton(
                      backgroundColor: AppColors.stemInactive,
                      onPressed: onTap,
                      child: const Icon(
                        Icons.share,
                        size: 18,
                        color: AppColors.textWhite,
                      ),
                    ),
                    if (onDelete != null) ...[
                      const SizedBox(width: 10),
                      _CircleActionButton(
                        backgroundColor: AppColors.stemInactive,
                        onPressed: onDelete!,
                        child: const Icon(
                          Icons.delete_outline,
                          size: 18,
                          color: AppColors.error,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _buildSharedSubtitle(DateTime createdAt) {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inHours < 24) {
      return 'Shared ${diff.inHours} hours ago';
    }
    if (diff.inDays == 1) {
      return 'Shared yesterday';
    }
    // Match Figma style: "Shared Oct 24"
    final m = _monthShort(createdAt.month);
    return 'Shared $m ${createdAt.day}';
  }

  String _monthShort(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return (month >= 1 && month <= 12) ? months[month - 1] : 'Oct';
  }
}

class _CircleActionButton extends StatelessWidget {
  final Color backgroundColor;
  final VoidCallback onPressed;
  final Widget child;

  const _CircleActionButton({
    required this.backgroundColor,
    required this.onPressed,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 40,
      height: 40,
      child: ClipOval(
        child: Material(
          color: backgroundColor,
          child: InkWell(
            onTap: onPressed,
            child: Center(child: child),
          ),
        ),
      ),
    );
  }
}
