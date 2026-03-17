import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';
import '../constants/app_fonts.dart';

class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final Color? backgroundColor;
  final Color? textColor;
  final double? width;
  final double? height;
  final IconData? icon;
  final bool isOutlined;
  
  const AppButton({
    Key? key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.backgroundColor,
    this.textColor,
    this.width,
    this.height,
    this.icon,
    this.isOutlined = false,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    if (isOutlined) {
      return OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          minimumSize: Size(
            width ?? double.infinity,
            height ?? AppDimensions.buttonHeight52,
          ),
          side: BorderSide(
            color: backgroundColor ?? AppColors.primaryGreen,
            width: 2,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radius12),
          ),
        ),
        child: isLoading
            ? SizedBox(
                height: AppDimensions.iconSize20,
                width: AppDimensions.iconSize20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    textColor ?? AppColors.primaryGreen,
                  ),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: AppDimensions.iconSize20, color: textColor ?? AppColors.primaryGreen),
                    const SizedBox(width: AppDimensions.padding8),
                  ],
                  Text(
                    text,
                    style: TextStyle(
                      fontFamily: AppFonts.poppins,
                      fontSize: AppFonts.fontSize16,
                      fontWeight: FontWeight.w600,
                      color: textColor ?? AppColors.primaryGreen,
                    ),
                  ),
                ],
              ),
      );
    }
    
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor ?? theme.colorScheme.primary,
        foregroundColor: textColor ?? AppColors.textWhite,
        minimumSize: Size(
          width ?? double.infinity,
          height ?? AppDimensions.buttonHeight52,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radius12),
        ),
        elevation: 0,
      ),
      child: isLoading
          ? SizedBox(
              height: AppDimensions.iconSize20,
              width: AppDimensions.iconSize20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  textColor ?? AppColors.textWhite,
                ),
              ),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: AppDimensions.iconSize20),
                  const SizedBox(width: AppDimensions.padding8),
                ],
                Text(
                  text,
                  style: TextStyle(
                    fontFamily: AppFonts.poppins,
                    fontSize: AppFonts.fontSize16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
    );
  }
}

