import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_fonts.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../../../core/utils/onboarding_service.dart';
import '../../data/models/onboarding_data.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({Key? key}) : super(key: key);
  
  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  
  final List<OnboardingData> _pages = [
    OnboardingData(
      title: AppStrings.onboardingTitle1,
      description: AppStrings.onboardingDescription1,
      imagePath: 'assets/images/onbording/intro.png',
      buttonText: AppStrings.skip,
      isOutlined: true,
    ),
    OnboardingData(
      title: AppStrings.onboardingTitle2,
      description: AppStrings.onboardingDescription2,
      imagePath: 'assets/images/onbording/intro1.png', // Update with second image path
      buttonText: AppStrings.letsGo,
      isOutlined: false,
    ),
  ];
  
  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
  
  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _goToLogin();
    }
  }
  
  Future<void> _goToLogin() async {
    // Mark onboarding as completed
    final onboardingService = di.sl<OnboardingService>();
    await onboardingService.setOnboardingCompleted();
    
    // Navigate to login
    if (mounted) {
      context.go(AppRoutes.login);
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  return _buildOnboardingPage(_pages[index]);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildOnboardingPage(OnboardingData data) {
    return Column(
      children: [
        // Illustration Section - Takes upper half
        Expanded(
          flex: 2,
          child: Container(
            width: double.infinity,
            color: AppColors.backgroundWhite,
            child: Center(
              child: Image.asset(
                data.imagePath,
                fit: BoxFit.contain,
                width: double.infinity,
                height: double.infinity,
              ),
            ),
          ),
        ),
        // Content Box - Takes lower half with ClipPath for smooth curves
        Expanded(
          flex: 2,
          child: ClipPath(
            clipper: _SmoothCurveClipper(),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.padding24,
                vertical: AppDimensions.padding32,
              ),
              decoration: const BoxDecoration(
                color: AppColors.primaryGreen,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    children: [
                      // Headline
                      Text(
                        data.title,
                        style: const TextStyle(
                          fontSize: AppFonts.fontSize24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textWhite,
                          height: 1.2,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppDimensions.margin16),
                      // Body Text
                      Text(
                        data.description,
                        style: const TextStyle(
                          fontSize: AppFonts.fontSize14,
                          color: AppColors.textWhite,
                          height: 1.4,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppDimensions.buttonHeight52),
                       const SizedBox(height: AppDimensions.buttonHeight52),
                      // Navigation Dots
                      Row(
                        
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          _pages.length,
                          (index) => _buildDot(index == _currentPage),
                        ),
                      ),
                    ],
                  ),
                  // Skip Button with ClipPath
                  ClipPath(
                    clipper: _ButtonCurveClipper(),
                    child: Container(
                      width: 120,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.primaryGreenDark,
                        borderRadius: BorderRadius.circular(AppDimensions.radius12),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _currentPage == _pages.length - 1
                              ? _goToLogin
                              : _nextPage,
                          borderRadius: BorderRadius.circular(AppDimensions.radius12),
                          child: Center(
                            child: Text(
                              data.buttonText,
                              style: const TextStyle(
                                fontSize: AppFonts.fontSize16,
                                color: AppColors.textWhite,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildDot(bool isActive) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: isActive ? 10 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: isActive 
            ? AppColors.textWhite 
            : AppColors.textWhite.withOpacity(0.4),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

// Custom Clipper for smooth top curves
class _SmoothCurveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    final curveHeight = 30.0;
    
    // Start from bottom left
    path.moveTo(0, size.height);
    
    // Line to bottom right
    path.lineTo(size.width, size.height);
    
    // Line to top right
    path.lineTo(size.width, curveHeight);
    
    // Smooth curve to top right
    path.quadraticBezierTo(
      size.width,
      0,
      size.width - curveHeight,
      0,
    );
    
    // Smooth curve to top left
    path.quadraticBezierTo(
      curveHeight,
      0,
      0,
      curveHeight,
    );
    
    // Close path
    path.lineTo(0, size.height);
    path.close();
    
    return path;
  }
  
  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

// Custom Clipper for button smooth curves
class _ButtonCurveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    final radius = 12.0;
    
    // Rounded rectangle path
    path.moveTo(radius, 0);
    path.lineTo(size.width - radius, 0);
    path.quadraticBezierTo(size.width, 0, size.width, radius);
    path.lineTo(size.width, size.height - radius);
    path.quadraticBezierTo(size.width, size.height, size.width - radius, size.height);
    path.lineTo(radius, size.height);
    path.quadraticBezierTo(0, size.height, 0, size.height - radius);
    path.lineTo(0, radius);
    path.quadraticBezierTo(0, 0, radius, 0);
    path.close();
    
    return path;
  }
  
  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}



