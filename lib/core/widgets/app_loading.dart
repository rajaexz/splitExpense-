import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class AppLoading extends StatelessWidget {
  final Color? color;
  final double? size;
  
  const AppLoading({
    Key? key,
    this.color,
    this.size,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: size ?? 40,
        height: size ?? 40,
        child: CircularProgressIndicator(
          strokeWidth: 3,
          valueColor: AlwaysStoppedAnimation<Color>(
            color ?? AppColors.primaryGreen,
          ),
        ),
      ),
    );
  }
}

