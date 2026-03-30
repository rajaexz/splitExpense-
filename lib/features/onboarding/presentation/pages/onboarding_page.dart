import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../../../core/utils/onboarding_service.dart';

/// STEM design: Horizontal scroll onboarding with 3 sections -
/// Track Shared Expenses, Split with Geo-Fencing, Settle with UPI QR.
class OnboardingPage extends StatefulWidget {
  const OnboardingPage({Key? key}) : super(key: key);

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _goToLogin();
    }
  }

  Future<void> _goToLogin() async {
    final onboardingService = di.sl<OnboardingService>();
    await onboardingService.setOnboardingCompleted();
    if (mounted) context.go(AppRoutes.login);
  }

  Future<void> _skip() async {
    final onboardingService = di.sl<OnboardingService>();
    await onboardingService.setOnboardingCompleted();
    if (mounted) context.go(AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.stemBackground,
      body: SafeArea(
        child: Column(
          children: [
            // Header - JobCrak + Skip
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'JobCrak',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: AppColors.stemEmerald,
                      letterSpacing: -1.2,
                    ),
                  ),
                  GestureDetector(
                    onTap: _skip,
                    child: Text(
                      'SKIP',
                      style: GoogleFonts.manrope(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.stemMutedText,
                        letterSpacing: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Horizontal scroll content
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (i) => setState(() => _currentPage = i),
                children: [
                  _OnboardingSlide(
                    title1: 'Track Shared',
                    title2: 'Expenses',
                    body: 'Precision accounting for group\nbills. Never lose track of who paid\nfor what.',
                    illustration: _ExpenseTrackingIllustration(),
                  ),
                  _OnboardingSlide(
                    title1: 'Split with',
                    title2: 'Geo-Fencing',
                    body: "Automatically detect groups when\nyou're at the same restaurant or\nvenue.",
                    illustration: _GeoFenceIllustration(),
                  ),
                  _OnboardingSlide(
                    title1: 'Settle with',
                    title2: 'UPI QR',
                    body: "One-tap settlement using secure\nUPI integration. No more \"I'll pay\nyou later.\"",
                    illustration: _QrIllustration(),
                  ),
                ],
              ),
            ),
            // Footer - progress + Next / Get Started
            Padding(
              padding: const EdgeInsets.fromLTRB(32, 24, 32, 48),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: List.generate(
                          3,
                          (i) => Container(
                            margin: EdgeInsets.only(right: i < 2 ? 8 : 0),
                            width: i == _currentPage ? 32 : 8,
                            height: 6,
                            decoration: BoxDecoration(
                              color: i == _currentPage
                                  ? AppColors.stemEmerald
                                  : AppColors.stemInactive,
                              borderRadius: BorderRadius.circular(9999),
                            ),
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: _nextPage,
                        child: Row(
                          children: [
                            Text(
                              _currentPage == 2 ? 'GET STARTED' : 'NEXT',
                              style: GoogleFonts.manrope(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.stemEmerald,
                                letterSpacing: 1.4,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              Icons.arrow_forward,
                              size: 10,
                              color: AppColors.stemEmerald,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (_currentPage == 2) ...[
                    const SizedBox(height: 16),
                    Text(
                      'By continuing, you agree to JobCrak Terms',
                      style: GoogleFonts.manrope(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.stemMutedText.withValues(alpha: 0.5),
                        letterSpacing: 1,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingSlide extends StatelessWidget {
  final String title1;
  final String title2;
  final String body;
  final Widget illustration;

  const _OnboardingSlide({
    required this.title1,
    required this.title2,
    required this.body,
    required this.illustration,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 75),
            decoration: BoxDecoration(
              color: AppColors.stemCard,
              borderRadius: BorderRadius.circular(32),
            ),
            child: illustration,
          ),
          const SizedBox(height: 48),
          Text(
            title1,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 36,
              fontWeight: FontWeight.w800,
              color: AppColors.stemLightText,
              letterSpacing: -0.9,
              height: 1.25,
            ),
          ),
          Text(
            title2,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 36,
              fontWeight: FontWeight.w800,
              color: AppColors.stemEmerald,
              letterSpacing: -0.9,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 15),
          Text(
            body,
            style: GoogleFonts.manrope(
              fontSize: 18,
              color: AppColors.stemMutedText,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

class _ExpenseTrackingIllustration extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 192,
        padding: const EdgeInsets.all(17),
        decoration: BoxDecoration(
          color: AppColors.stemCard.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFF404944).withValues(alpha: 0.15),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 32,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.stemSurface,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 64,
                  height: 8,
                  decoration: BoxDecoration(
                    color: AppColors.stemEmerald.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                Container(
                  width: 40,
                  height: 8,
                  decoration: BoxDecoration(
                    color: AppColors.stemMutedText.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 80,
                  height: 8,
                  decoration: BoxDecoration(
                    color: AppColors.stemEmerald.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                Container(
                  width: 48,
                  height: 8,
                  decoration: BoxDecoration(
                    color: AppColors.stemMutedText.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 56,
                  height: 8,
                  decoration: BoxDecoration(
                    color: AppColors.stemEmerald.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                Container(
                  width: 32,
                  height: 8,
                  decoration: BoxDecoration(
                    color: AppColors.stemMutedText.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.stemInactive,
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.primaryGreen,
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  radius: 16,
                  backgroundColor: const Color(0xFF344C40),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _GeoFenceIllustration extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 200,
        height: 200,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.stemEmerald.withValues(alpha: 0.3),
                ),
              ),
            ),
            Container(
              margin: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.stemEmerald.withValues(alpha: 0.2),
                ),
              ),
            ),
            Container(
              margin: const EdgeInsets.all(66),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.stemEmerald.withValues(alpha: 0.1),
              ),
              child: Icon(
                Icons.location_on,
                size: 32,
                color: AppColors.stemEmerald.withValues(alpha: 0.8),
              ),
            ),
            Positioned(
              top: 0,
              right: 16,
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.stemCard.withValues(alpha: 0.6),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.stemEmerald.withValues(alpha: 0.3),
                  ),
                ),
                child: Icon(
                  Icons.people_outline,
                  size: 20,
                  color: AppColors.stemEmerald,
                ),
              ),
            ),
            Positioned(
              bottom: 48,
              left: 0,
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.stemCard.withValues(alpha: 0.6),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.stemEmerald.withValues(alpha: 0.3),
                  ),
                ),
                child: Icon(
                  Icons.people_outline,
                  size: 20,
                  color: AppColors.stemEmerald,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QrIllustration extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(33),
        decoration: BoxDecoration(
          color: AppColors.stemCard.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: const Color(0xFF404944).withValues(alpha: 0.15),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 128,
              height: 128,
              child: GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 3,
                mainAxisSpacing: 2,
                crossAxisSpacing: 2,
                children: List.generate(
                  9,
                  (i) => Container(
                    decoration: BoxDecoration(
                      color: i.isEven
                          ? AppColors.primaryGreen
                          : AppColors.stemInactive,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.stemEmerald.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.qr_code_scanner,
                    size: 12,
                    color: AppColors.stemEmerald,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'INSTANT SETTLE',
                  style: GoogleFonts.manrope(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.stemEmerald,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
