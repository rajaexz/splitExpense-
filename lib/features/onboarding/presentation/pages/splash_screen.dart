import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../../../core/utils/onboarding_service.dart';

/// STEM design: Splash with JobCrak branding, minimalist loader, atmospheric blur.
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
    await Future.delayed(const Duration(seconds: 3));
    
    if (!mounted) return;
    
    final onboardingService = di.sl<OnboardingService>();
    final isOnboardingCompleted =
        await onboardingService.isOnboardingCompleted();
    
    if (!mounted) return;
    
    if (isOnboardingCompleted) {
      context.go(AppRoutes.login);
    } else {
      context.go(AppRoutes.onboarding);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.stemBackground,
      body: Stack(
        children: [
          // Main content
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
            child: Column(
              children: [
                const Spacer(),
                // Abstract atmospheric background blurs
                SizedBox(
                  height: 353,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Logo cluster
                      Positioned(
                        top: 0,
                        child: Container(
                          width: 112,
                          height: 112,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                AppColors.stemEmerald,
                                AppColors.primaryGreen,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(32),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.5),
                                blurRadius: 20,
                                offset: const Offset(0, 20),
                              ),
                            ],
                          ),
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
          Center(
            child: Image.asset(
                                  'assets/icons/logo.png',
                                  width: 51,
                                  height: 37,
              fit: BoxFit.contain,
                                  errorBuilder: (_, __, ___) => Icon(
                                    Icons.account_balance_wallet,
                                    size: 48,
                                    color: AppColors.stemButtonText,
                                  ),
                                ),
                              ),
                              Positioned(
                                right: -8,
                                bottom: -8,
                                child: Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: AppColors.stemInactive,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: AppColors.stemBackground,
                                      width: 2,
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.currency_rupee,
                                    color: AppColors.stemLightText,
                                    size: 22,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Branding text
                      Positioned(
                        top: 160,
                        left: 0,
                        right: 0,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'JobCrak',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 36,
                                fontWeight: FontWeight.w800,
                                color: AppColors.stemLightText,
                                letterSpacing: -1.8,
                                height: 1,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Opacity(
                              opacity: 0.8,
                              child: Text(
                                'Split fairly, live freely.',
                                style: GoogleFonts.manrope(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.stemMutedText,
                                  letterSpacing: 0.45,
                                  height: 1,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                // Minimalist loader
                Column(
                  children: [
                    Container(
                      width: 140,
                      height: 2,
                      decoration: BoxDecoration(
                        color: AppColors.stemCard,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'INITIALIZING LEDGER',
                      style: GoogleFonts.manrope(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppColors.stemMutedText.withValues(alpha: 0.4),
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 48),
              ],
            ),
          ),
          // Atmospheric blurs
          Positioned(
            left: -39,
            top: -88,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
              child: Container(
                width: 195,
                height: 442,
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(9999),
                ),
              ),
            ),
          ),
          Positioned(
            right: -39,
            bottom: -177,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 75, sigmaY: 75),
              child: Container(
                width: 234,
                height: 530,
                decoration: BoxDecoration(
                  color: const Color(0xFF344C40).withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(9999),
                ),
              ),
            ),
          ),
          // Decorative corner
          Positioned(
            top: 32,
            right: 32,
            child: Opacity(
              opacity: 0.2,
              child: Container(
                width: 128,
                height: 128,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: const Color(0xFF404944).withValues(alpha: 0.1),
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
            ),
          ),
          // Footnote
          Positioned(
            bottom: 48,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                'Premium Financial Atelier © 2024',
                style: GoogleFonts.manrope(
                  fontSize: 10,
                  fontWeight: FontWeight.w400,
                  color: AppColors.stemMutedText.withValues(alpha: 0.2),
                  letterSpacing: 1,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
