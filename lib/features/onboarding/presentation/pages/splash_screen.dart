import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_fonts.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../../../core/utils/onboarding_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkOnboardingAndNavigate();
  }

  Future<void> _checkOnboardingAndNavigate() async {
    // Wait for splash screen duration
    await Future.delayed(const Duration(seconds: 3));
    
    if (!mounted) return;
    
    // Check if onboarding has been completed
    final onboardingService = di.sl<OnboardingService>();
    final isOnboardingCompleted = await onboardingService.isOnboardingCompleted();
    
    if (!mounted) return;
    
    // Navigate based on onboarding status
    if (isOnboardingCompleted) {
      // Skip onboarding and go to login
      context.go(AppRoutes.login);
    } else {
      // Show onboarding for first time
      context.go(AppRoutes.onboarding);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundBlack,
      body: Stack(
        children: [
          // Centered Logo Image
          Center(
            child: Image.asset(
              'assets/images/logo.png',
              width: 200,
              height: 200,
              fit: BoxFit.contain,
            ),
          ),
          // Version Text at bottom center
          const Positioned(
            bottom: AppDimensions.margin32,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                '${AppStrings.appName} ${AppStrings.appVersion}',
                style: TextStyle(
                  fontSize: AppFonts.fontSize12,
                  color: AppColors.textGrey,
                  fontWeight: FontWeight.normal,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
