import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../application/auth/auth_cubit.dart';
import 'widgets/stem_auth_widgets.dart';

/// STEM design: Dark theme login with JobCrak branding, Email/Phone toggle,
/// auth card, forgot password, Google sign-in.
class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

enum _LoginMode { email, phone }

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  late TabController _tabController;
  bool _obscurePassword = true;
  _LoginMode _loginMode = _LoginMode.email;
  String _countryCode = '+91';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _handleLogin() {
    if (_formKey.currentState!.validate()) {
      context.read<AuthCubit>().login(
            _emailController.text.trim(),
            _passwordController.text,
          );
    }
  }

  void _handleSendOtp() {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) return;
    final normalized = phone.startsWith('+') ? phone : '$_countryCode$phone';
    context.read<AuthCubit>().verifyPhone(normalized);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.stemBackground,
      body: BlocConsumer<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          } else if (state is AuthSuccess) {
            context.go(AppRoutes.home);
          } else if (state is AuthPhoneCodeSent) {
            context.push(AppRoutes.otpVerification, extra: {
              'verificationId': state.verificationId,
              'phoneNumber': state.phoneNumber,
            });
          }
        },
        builder: (context, state) {
          final isLoading = state is AuthLoading;
          return Stack(
            children: [
              // Decorative blurs
              Positioned(
                right: -20,
                top: -92,
                child: ImageFiltered(
                  imageFilter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
                  child: Container(
                    width: 400,
                    height: 400,
                    decoration: BoxDecoration(
                      color: AppColors.stemEmerald.withValues(alpha: 0.05),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
              Positioned(
                left: -20,
                bottom: -92,
                child: ImageFiltered(
                  imageFilter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
                  child: Container(
                    width: 300,
                    height: 300,
                    decoration: BoxDecoration(
                      color: const Color(0xFFB2CDBE).withValues(alpha: 0.05),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
              // Main content
              SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 44,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Branding
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'JobCrak',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 36,
                              fontWeight: FontWeight.w800,
                              color: AppColors.stemEmerald,
                              letterSpacing: -1.8,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'The Financial Ledger',
                            style: GoogleFonts.manrope(
                              fontSize: 10,
                              color: AppColors.stemMutedText,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      // Auth card
                      Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: AppColors.stemCard,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.25),
                              blurRadius: 50,
                              offset: const Offset(0, 25),
                            ),
                          ],
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Header
                              Text(
                                'Welcome back',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.stemLightText,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Enter your credentials to access your\nledger.',
                                style: GoogleFonts.manrope(
                                  fontSize: 16,
                                  color: AppColors.stemMutedText,
                                  height: 1.5,
                                ),
                              ),
                              const SizedBox(height: 32),
                              // Toggle Email / Phone
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: AppColors.stemInputBg,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: GestureDetector(
                                        onTap: () {
                                          setState(() => _loginMode = _LoginMode.email);
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 8,
                                          ),
                                          decoration: BoxDecoration(
                                            color: _loginMode == _LoginMode.email
                                                ? AppColors.stemSurface
                                                : Colors.transparent,
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Center(
                                            child: Text(
                                              'Email',
                                              style: GoogleFonts.manrope(
                                                fontSize: 14,
                                                fontWeight: _loginMode == _LoginMode.email
                                                    ? FontWeight.w600
                                                    : FontWeight.w500,
                                                color: _loginMode == _LoginMode.email
                                                    ? AppColors.stemEmerald
                                                    : AppColors.stemMutedText,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: GestureDetector(
                                        onTap: () {
                                          setState(() =>
                                              _loginMode = _LoginMode.phone);
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 8,
                                          ),
                                          child: Center(
                                            child: Text(
                                              'Phone',
                                              style: GoogleFonts.manrope(
                                                fontSize: 14,
                                                fontWeight: _loginMode == _LoginMode.phone
                                                    ? FontWeight.w600
                                                    : FontWeight.w500,
                                                color: _loginMode == _LoginMode.phone
                                                    ? AppColors.stemEmerald
                                                    : AppColors.stemMutedText,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 32),
                              if (_loginMode == _LoginMode.phone) ...[
                                _StemTextField(
                                  controller: _phoneController,
                                  hint: _countryCode == '+91'
                                      ? '98765 43210'
                                      : '300 1234567',
                                  keyboardType: TextInputType.phone,
                                  prefixIcon: Icons.phone_outlined,
                                ),
                                const SizedBox(height: 24),
                                StemPrimaryButton(
                                  label: 'Send OTP',
                                  onPressed: isLoading
                                      ? null
                                      : () {
                                          if (_phoneController.text.trim().isEmpty) {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(const SnackBar(
                                                    content: Text(
                                                        'Enter phone number')));
                                            return;
                                          }
                                          _handleSendOtp();
                                        },
                                  isLoading: isLoading,
                                ),
                              ] else ...[
                                StemInputField(
                                  fillColor: AppColors.stemInputBg,
                                  label: 'EMAIL ADDRESS',
                                  controller: _emailController,
                                  hint: 'name@company.com',
                                  prefixIcon: Icons.email_outlined,
                                  keyboardType: TextInputType.emailAddress,
                                  validator: (v) {
                                    if (v == null || v.trim().isEmpty) {
                                      return 'Please enter your email';
                                    }
                                    if (!v.contains('@')) {
                                      return 'Enter a valid email';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 23),
                                StemInputField(
                                  fillColor: AppColors.stemInputBg,
                                  label: 'PASSWORD',
                                  controller: _passwordController,
                                  hint: '••••••••',
                                  obscureText: _obscurePassword,
                                  prefixIcon: Icons.lock_outline,
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                      size: 20,
                                      color: AppColors.stemMutedText,
                                    ),
                                    onPressed: () {
                                      setState(
                                          () => _obscurePassword = !_obscurePassword);
                                    },
                                  ),
                                  rightLabel: GestureDetector(
                                    onTap: () =>
                                        context.push(AppRoutes.forgotPassword),
                                    child: Text(
                                      'Forgot Password?',
                                      style: GoogleFonts.manrope(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.stemEmerald,
                                      ),
                                    ),
                                  ),
                                  validator: (v) {
                                    if (v == null || v.isEmpty) {
                                      return 'Please enter your password';
                                    }
                                    if (v.length < 6) {
                                      return 'Password must be at least 6 characters';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 23),
                                StemPrimaryButton(
                                  label: 'Login',
                                  onPressed: isLoading ? null : _handleLogin,
                                  isLoading: isLoading,
                                ),
                              ],
                              const SizedBox(height: 24),
                              // Divider
                              Row(
                                children: [
                                  Expanded(
                                    child: Container(
                                      height: 1,
                                      color: const Color(0xFF404944)
                                          .withValues(alpha: 0.15),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16),
                                    child: Text(
                                      'OR CONTINUE WITH',
                                      style: GoogleFonts.manrope(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.stemGreyText,
                                        letterSpacing: 1,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Container(
                                      height: 1,
                                      color: const Color(0xFF404944)
                                          .withValues(alpha: 0.15),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),
                              // Google button
                              StemOutlinedButton(
                                icon: Icons.g_mobiledata,
                                label: 'Google',
                                onPressed: () =>
                                    context.read<AuthCubit>().signInWithGoogle(),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      // Footer
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Don't have an account? ",
                            style: GoogleFonts.manrope(
                              fontSize: 16,
                              color: AppColors.stemMutedText,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => context.go(AppRoutes.register),
                            child: Text(
                              'Sign up',
                              style: GoogleFonts.manrope(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppColors.stemEmerald,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _StemTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final TextInputType? keyboardType;
  final IconData? prefixIcon;

  const _StemTextField({
    required this.controller,
    required this.hint,
    this.keyboardType,
    this.prefixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.stemInputBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        style: GoogleFonts.manrope(
          fontSize: 16,
          color: AppColors.stemLightText,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.manrope(
            fontSize: 16,
            color: AppColors.stemGreyText.withValues(alpha: 0.5),
          ),
          prefixIcon: prefixIcon != null
              ? Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: Icon(
                    prefixIcon!,
                    size: 18,
                    color: AppColors.stemMutedText,
                  ),
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 17,
          ),
        ),
      ),
    );
  }
}
