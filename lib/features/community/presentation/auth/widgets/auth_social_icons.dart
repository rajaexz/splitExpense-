import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_dimensions.dart';

/// Social login icons (Google, Facebook, etc.)
class AuthSocialIcons extends StatelessWidget {
  final List<AuthSocialIconItem> items;

  const AuthSocialIcons({
    super.key,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (int i = 0; i < items.length; i++) ...[
          _AuthSocialIcon(
            icon: items[i].icon,
            onTap: items[i].onTap,
          ),
          if (i < items.length - 1) const SizedBox(width: AppDimensions.margin24),
        ],
      ],
    );
  }
}

class AuthSocialIconItem {
  final IconData icon;
  final VoidCallback onTap;

  const AuthSocialIconItem({
    required this.icon,
    required this.onTap,
  });
}

class _AuthSocialIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _AuthSocialIcon({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: AppColors.borderGrey,
            width: 1,
          ),
        ),
        child: Icon(
          icon,
          size: AppDimensions.iconSize24,
          color: AppColors.textBlack,
        ),
      ),
    );
  }
}
