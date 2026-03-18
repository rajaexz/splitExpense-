import 'dart:io';

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_fonts.dart';

/// Avatar with optional photo picker overlay. Used in profile and edit profile.
class ProfileAvatarPicker extends StatelessWidget {
  final String? photoUrl;
  final File? localFile;
  final String initial;
  final double radius;
  final bool showCameraOverlay;
  final VoidCallback? onTap;

  const ProfileAvatarPicker({
    super.key,
    this.photoUrl,
    this.localFile,
    required this.initial,
    this.radius = 50,
    this.showCameraOverlay = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final size = radius * 2;

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          CircleAvatar(
            radius: radius,
            backgroundColor: AppColors.primaryGreen,
            child: localFile != null
                ? ClipOval(
                    child: Image.file(
                      localFile!,
                      width: size,
                      height: size,
                      fit: BoxFit.cover,
                    ),
                  )
                : photoUrl != null && photoUrl!.isNotEmpty
                    ? ClipOval(
                        child: CachedNetworkImage(
                          imageUrl: photoUrl!,
                          width: size,
                          height: size,
                          fit: BoxFit.cover,
                          placeholder: (_, __) =>
                              const CircularProgressIndicator(),
                          errorWidget: (_, __, ___) => _buildInitialText(),
                        ),
                      )
                    : _buildInitialText(),
          ),
          if (showCameraOverlay && onTap != null)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: AppColors.primaryGreen,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.camera_alt,
                  color: AppColors.textWhite,
                  size: 20,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInitialText() {
    final fontSize = radius * 0.72;
    return Text(
      initial,
      style: TextStyle(
        fontSize: fontSize.clamp(24, 48),
        color: AppColors.textWhite,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}
