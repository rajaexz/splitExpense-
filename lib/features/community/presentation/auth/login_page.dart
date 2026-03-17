import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_fonts.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../application/auth/auth_cubit.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);
  
  @override
  State<LoginPage> createState() => _LoginPageState();
}

enum _LoginMode { email, phone }

class _LoginPageState extends State<LoginPage> with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  late TabController _tabController;
  bool _rememberMe = true;
  bool _obscurePassword = true;
  _LoginMode _loginMode = _LoginMode.email;
  String? _verificationId;
  String? _phoneForOtp;
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
    _otpController.dispose();
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

  void _handleVerifyOtp() {
    final code = _otpController.text.trim();
    if (code.isEmpty || _verificationId == null) return;
    context.read<AuthCubit>().signInWithPhoneCredential(_verificationId!, code);
  }

  void _resetPhoneFlow() {
    context.read<AuthCubit>().resetPhoneVerification();
    setState(() {
      _verificationId = null;
      _phoneForOtp = null;
      _otpController.clear();
    });
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textBlack),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            }
          },
        ),
        centerTitle: true,
        title: const Text(
          AppStrings.candidate,
          style: TextStyle(
            color: AppColors.textBlack,
            fontSize: AppFonts.fontSize18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: BlocConsumer<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          } else if (state is AuthSuccess) {
            context.go(AppRoutes.home);
          } else if (state is AuthPhoneCodeSent) {
            setState(() {
              _verificationId = state.verificationId;
              _phoneForOtp = state.phoneNumber;
            });
          }
        },
        builder: (context, state) {
          final isPhoneCodeSent = state is AuthPhoneCodeSent;
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.padding24,
              vertical: AppDimensions.padding16,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Tab Bar
                  TabBar(
                    controller: _tabController,
                    indicatorColor: AppColors.primaryGreen,
                    labelColor: AppColors.primaryGreen,
                    unselectedLabelColor: AppColors.textBlack,
                    labelStyle: const TextStyle(
                      fontSize: AppFonts.fontSize16,
                      fontWeight: FontWeight.w600,
                    ),
                    unselectedLabelStyle: const TextStyle(
                      fontSize: AppFonts.fontSize16,
                      fontWeight: FontWeight.normal,
                    ),
                    tabs: const [
                      Tab(text: AppStrings.login),
                      Tab(text: AppStrings.register),
                    ],
                    onTap: (index) {
                      if (index == 1) {
                        context.go(AppRoutes.register);
                      }
                    },
                  ),
                  const SizedBox(height: AppDimensions.margin32),

                  // Email / Phone Toggle
                  Row(
                    children: [
                      Expanded(
                        child: _LoginModeChip(
                          label: AppStrings.loginWithEmail,
                          isSelected: _loginMode == _LoginMode.email && !isPhoneCodeSent,
                          onTap: () {
                            if (isPhoneCodeSent) _resetPhoneFlow();
                            setState(() => _loginMode = _LoginMode.email);
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _LoginModeChip(
                          label: AppStrings.loginWithPhone,
                          isSelected: _loginMode == _LoginMode.phone || isPhoneCodeSent,
                          onTap: () {
                            if (!isPhoneCodeSent) {
                              setState(() => _loginMode = _LoginMode.phone);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppDimensions.margin24),

                  if (isPhoneCodeSent) ...[
                    Text(
                      'OTP sent to $_phoneForOtp',
                      style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textGrey),
                    ),
                    const SizedBox(height: 12),
                    AppTextField(
                      label: AppStrings.enterOtp,
                      controller: _otpController,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: _resetPhoneFlow,
                      child: const Text('Change number'),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: AppButton(
                        text: AppStrings.verify,
                        onPressed: state is AuthLoading ? null : _handleVerifyOtp,
                        isLoading: state is AuthLoading,
                        backgroundColor: AppColors.primaryGreen,
                        textColor: AppColors.textWhite,
                      ),
                    ),
                  ] else if (_loginMode == _LoginMode.phone) ...[
                    Text(
                      AppStrings.yourPhone,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                          decoration: BoxDecoration(
                            color: AppColors.backgroundGrey,
                            borderRadius: BorderRadius.circular(AppDimensions.radius12),
                            border: Border.all(color: AppColors.borderGrey),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              GestureDetector(
                                onTap: () => setState(() => _countryCode = '+91'),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: _countryCode == '+91' ? AppColors.primaryGreen.withValues(alpha: 0.2) : null,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '+91',
                                    style: TextStyle(
                                      fontWeight: _countryCode == '+91' ? FontWeight.w600 : FontWeight.normal,
                                      color: _countryCode == '+91' ? AppColors.primaryGreen : AppColors.textGrey,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              GestureDetector(
                                onTap: () => setState(() => _countryCode = '+92'),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: _countryCode == '+92' ? AppColors.primaryGreen.withValues(alpha: 0.2) : null,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '+92',
                                    style: TextStyle(
                                      fontWeight: _countryCode == '+92' ? FontWeight.w600 : FontWeight.normal,
                                      color: _countryCode == '+92' ? AppColors.primaryGreen : AppColors.textGrey,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: AppTextField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            hint: _countryCode == '+91' ? '98765 43210' : '300 1234567',
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your phone number';
                              }
                              final digits = value.replaceAll(RegExp(r'[\s\-]'), '');
                              if (digits.length < 10) {
                                return 'Enter a valid phone number';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppDimensions.margin24),
                    AppButton(
                      text: AppStrings.sendOtp,
                      onPressed: state is AuthLoading ? null : () {
                        if (_formKey.currentState?.validate() ?? false) {
                          _handleSendOtp();
                        }
                      },
                      isLoading: state is AuthLoading,
                      backgroundColor: AppColors.primaryGreen,
                      textColor: AppColors.textWhite,
                    ),
                  ] else ...[
                    AppTextField(
                      label: AppStrings.yourEmail,
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your email';
                        }
                        if (!value.contains('@')) {
                          return 'Please enter a valid email';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppDimensions.margin16),
                    AppTextField(
                      label: AppStrings.password,
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_off : Icons.visibility,
                          color: AppColors.textGrey,
                        ),
                        onPressed: () {
                          setState(() => _obscurePassword = !_obscurePassword);
                        },
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your password';
                        }
                        if (value.length < 6) {
                          return 'Password must be at least 6 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppDimensions.margin16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Checkbox(
                                value: _rememberMe,
                                onChanged: (value) {
                                  setState(() => _rememberMe = value ?? false);
                                },
                                activeColor: AppColors.primaryGreen,
                              ),
                              Flexible(
                                child: Text(
                                  AppStrings.rememberMe,
                                  style: theme.textTheme.bodyMedium,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: () {},
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text(
                            AppStrings.forgotPassword,
                            style: TextStyle(
                              color: AppColors.primaryGreen,
                              fontSize: AppFonts.fontSize14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppDimensions.margin24),
                    AppButton(
                      text: AppStrings.login,
                      onPressed: state is AuthLoading ? null : _handleLogin,
                      isLoading: state is AuthLoading,
                      backgroundColor: AppColors.textBlack,
                      textColor: AppColors.textWhite,
                    ),
                  ],
                  const SizedBox(height: AppDimensions.margin16),
                  
                  // Register Link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        AppStrings.dontHaveAccount,
                        style: theme.textTheme.bodyMedium,
                      ),
                      TextButton(
                        onPressed: () => context.go(AppRoutes.register),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.only(left: 4),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text(
                          AppStrings.register,
                          style: TextStyle(
                            color: AppColors.primaryGreen,
                            fontSize: AppFonts.fontSize14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppDimensions.margin24),
                  
                  // Social Login Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        AppStrings.orLoginWith,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppDimensions.margin16),
                  
                  // Social Icons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildSocialIcon(
                        icon: Icons.g_mobiledata,
                        onTap: () {
                          context.read<AuthCubit>().signInWithGoogle();
                        },
                      ),
                      const SizedBox(width: AppDimensions.margin24),
                      _buildSocialIcon(
                        icon: Icons.facebook,
                        onTap: () {
                          context.read<AuthCubit>().signInWithFacebook();
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildSocialIcon({required IconData icon, required VoidCallback onTap}) {
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

class _LoginModeChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _LoginModeChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryGreen.withValues(alpha: 0.15) : AppColors.backgroundGrey,
          borderRadius: BorderRadius.circular(AppDimensions.radius12),
          border: Border.all(
            color: isSelected ? AppColors.primaryGreen : AppColors.borderGrey,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            color: isSelected ? AppColors.primaryGreen : AppColors.textGrey,
          ),
        ),
      ),
    );
  }
}
