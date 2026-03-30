import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../application/auth/auth_cubit.dart';

/// STEM design: OTP Verification with 4-digit inputs, custom keypad,
/// resend timer, Verify button.
class OtpVerificationPage extends StatefulWidget {
  final String verificationId;
  final String phoneNumber;

  const OtpVerificationPage({
    super.key,
    required this.verificationId,
    required this.phoneNumber,
  });

  @override
  State<OtpVerificationPage> createState() => _OtpVerificationPageState();
}

class _OtpVerificationPageState extends State<OtpVerificationPage> {
  final List<TextEditingController> _controllers =
      List.generate(4, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(4, (_) => FocusNode());
  int _resendSeconds = 45;
  bool _canResend = false;
  late String _verificationId;

  @override
  void initState() {
    super.initState();
    _verificationId = widget.verificationId;
    _startResendTimer();
  }

  void _startResendTimer() {
    setState(() {
      _resendSeconds = 45;
      _canResend = false;
    });
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      setState(() {
        _resendSeconds--;
        if (_resendSeconds <= 0) _canResend = true;
      });
      return _resendSeconds > 0;
    });
  }

  @override
  void dispose() {
    for (final c in _controllers) c.dispose();
    for (final f in _focusNodes) f.dispose();
    super.dispose();
  }

  String get _otp =>
      _controllers.map((c) => c.text).join();

  void _appendDigit(String digit) {
    for (int i = 0; i < 4; i++) {
      if (_controllers[i].text.isEmpty) {
        _controllers[i].text = digit;
        if (i < 3) _focusNodes[i + 1].requestFocus();
        setState(() {});
        return;
      }
    }
  }

  void _backspace() {
    for (int i = 3; i >= 0; i--) {
      if (_controllers[i].text.isNotEmpty) {
        _controllers[i].clear();
        if (i > 0) _focusNodes[i - 1].requestFocus();
        setState(() {});
        return;
      }
    }
  }

  void _verify() {
    if (_otp.length != 4) return;
    context.read<AuthCubit>().signInWithPhoneCredential(
          _verificationId,
          _otp,
        );
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
            setState(() => _verificationId = state.verificationId);
          }
        },
        builder: (context, state) {
          final isLoading = state is AuthLoading;
          return SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => context.pop(),
                        icon: const Icon(
                          Icons.arrow_back,
                          color: AppColors.stemLightText,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'JobCrak',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.stemEmerald,
                        ),
                      ),
                      const Spacer(),
                      const SizedBox(width: 48),
                    ],
                  ),
                ),
                // Main content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 48,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Verify Phone',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 30,
                            fontWeight: FontWeight.w700,
                            color: AppColors.stemLightText,
                            letterSpacing: -0.75,
                          ),
                        ),
                        const SizedBox(height: 16),
                        RichText(
                          text: TextSpan(
                            style: GoogleFonts.manrope(
                              fontSize: 16,
                              color: AppColors.stemMutedText,
                            ),
                            children: [
                              const TextSpan(
                                text: 'Enter the 4-digit code sent to ',
                              ),
                              TextSpan(
                                text: '+91\n',
                                style: GoogleFonts.manrope(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.stemEmerald,
                                ),
                              ),
                              TextSpan(
                                text: widget.phoneNumber,
                                style: GoogleFonts.manrope(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.stemEmerald,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 40),
                        // OTP inputs
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: List.generate(4, (i) {
                            final hasValue = _controllers[i].text.isNotEmpty;
                            final isActive = _focusNodes[i].hasFocus;
                            return SizedBox(
                              width: 64,
                              height: 80,
                              child: TextFormField(
                                controller: _controllers[i],
                                focusNode: _focusNodes[i],
                                keyboardType: TextInputType.number,
                                maxLength: 1,
                                textAlign: TextAlign.center,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 30,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.stemLightText,
                                ),
                                decoration: InputDecoration(
                                  counterText: '',
                                  filled: true,
                                  fillColor: hasValue || isActive
                                      ? AppColors.stemSurface
                                      : AppColors.stemCard,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(24),
                                    borderSide: BorderSide(
                                      color: hasValue || isActive
                                          ? AppColors.stemEmerald
                                          : const Color(0xFF404944)
                                              .withValues(alpha: 0.15),
                                      width: hasValue || isActive ? 2 : 1,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(24),
                                    borderSide: BorderSide(
                                      color: hasValue || isActive
                                          ? AppColors.stemEmerald
                                          : const Color(0xFF404944)
                                              .withValues(alpha: 0.15),
                                      width: hasValue || isActive ? 2 : 1,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(24),
                                    borderSide: const BorderSide(
                                      color: AppColors.stemEmerald,
                                      width: 2,
                                    ),
                                  ),
                                ),
                                onChanged: (_) {
                                  if (_controllers[i].text.isNotEmpty && i < 3) {
                                    _focusNodes[i + 1].requestFocus();
                                  }
                                  setState(() {});
                                },
                              ),
                            );
                          }),
                        ),
                        const SizedBox(height: 40),
                        // Resend section
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.stemSurface,
                                borderRadius: BorderRadius.circular(9999),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.timer_outlined,
                                    size: 12,
                                    color: AppColors.stemEmerald,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _canResend
                                        ? '00:00'
                                        : '00:${_resendSeconds.toString().padLeft(2, '0')}',
                                    style: GoogleFonts.manrope(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.stemEmerald,
                                      letterSpacing: 1.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Center(
                          child: GestureDetector(
                            onTap: _canResend
                                ? () {
                                    context
                                        .read<AuthCubit>()
                                        .verifyPhone(widget.phoneNumber);
                                    _startResendTimer();
                                  }
                                : null,
                            child: Text(
                              'RESEND CODE',
                              style: GoogleFonts.manrope(
                                fontSize: 14,
                                color: _canResend
                                    ? AppColors.stemMutedText
                                    : AppColors.stemMutedText
                                        .withValues(alpha: 0.5),
                                letterSpacing: 1.4,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 48),
                        // Verify button
                        SizedBox(
                          width: double.infinity,
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: isLoading || _otp.length != 4
                                  ? null
                                  : _verify,
                              borderRadius: BorderRadius.circular(24),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 20,
                                ),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      AppColors.stemEmerald,
                                      AppColors.primaryGreen,
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(24),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.4),
                                      blurRadius: 40,
                                      offset: const Offset(0, 20),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: isLoading
                                      ? const SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: AppColors.stemButtonText,
                                          ),
                                        )
                                      : Text(
                                          'Verify',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                            color: const Color(0xFF003B29),
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
                // Custom keypad
                Container(
                  padding: const EdgeInsets.fromLTRB(32, 25, 32, 40),
                  decoration: BoxDecoration(
                    color: AppColors.stemCard.withValues(alpha: 0.8),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(32),
                    ),
                    border: Border(
                      top: BorderSide(
                        color: const Color(0xFF404944).withValues(alpha: 0.1),
                      ),
                    ),
                  ),
                  child: ClipRect(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          GridView.count(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisCount: 3,
                            mainAxisSpacing: 24,
                            crossAxisSpacing: 48,
                            childAspectRatio: 2.5,
                            children: [
                              for (int i = 1; i <= 9; i++)
                                _KeypadButton(
                                  label: '$i',
                                  onTap: () => _appendDigit('$i'),
                                ),
                              const SizedBox(),
                              _KeypadButton(
                                label: '0',
                                onTap: () => _appendDigit('0'),
                              ),
                              _KeypadButton(
                                icon: Icons.backspace_outlined,
                                onTap: _backspace,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _KeypadButton extends StatelessWidget {
  final String? label;
  final IconData? icon;
  final VoidCallback onTap;

  const _KeypadButton({
    this.label,
    this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Center(
          child: label != null
              ? Text(
                  label!,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: AppColors.stemLightText,
                  ),
                )
              : Icon(icon, size: 20, color: AppColors.stemLightText),
        ),
      ),
    );
  }
}
