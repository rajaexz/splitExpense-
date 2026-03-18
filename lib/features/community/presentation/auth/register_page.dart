import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../application/auth/auth_cubit.dart';
import 'widgets/auth_widgets.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({Key? key}) : super(key: key);
  
  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController(text: 'ferdous@gmail.com');
  final _nameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  late TabController _tabController;
  bool _agreeToTerms = true;
  bool _obscurePassword = true;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this, initialIndex: 1);
  }
  
  @override
  void dispose() {
    _emailController.dispose();
    _nameController.dispose();
    _passwordController.dispose();
    _tabController.dispose();
    super.dispose();
  }
  
  void _handleRegister() {
    if (_formKey.currentState!.validate()) {
      if (!_agreeToTerms) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please agree to Terms of Services & Privacy Policy')),
        );
        return;
      }
      context.read<AuthCubit>().register(
        _emailController.text.trim(),
        _nameController.text.trim(),
        _passwordController.text,
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      appBar: AuthAppBar(title: AppStrings.candidate),
      body: BlocConsumer<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          } else if (state is AuthSuccess) {
            context.go(AppRoutes.home);
          }
        },
        builder: (context, state) {
          return AuthFormScroll(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AuthTabBar(
                    controller: _tabController,
                    loginLabel: AppStrings.login,
                    registerLabel: AppStrings.register,
                    onLoginTap: () => context.go(AppRoutes.login),
                  ),
                  const SizedBox(height: AppDimensions.margin32),
                  
                  // Email Field
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
                  
                  // Username Field (meaningful & unique, e.g. Raja123)
                  AppTextField(
                    label: AppStrings.username,
                    hint: AppStrings.usernameHint,
                    controller: _nameController,
                    keyboardType: TextInputType.text,
                    validator: (value) {
                      final v = (value ?? '').trim();
                      if (v.isEmpty) return 'Please enter a username';
                      if (v.length < 3) return 'Username must be at least 3 characters';
                      if (v.length > 20) return 'Username must be at most 20 characters';
                      if (!RegExp(r'^[a-zA-Z][a-zA-Z0-9]{2,19}$').hasMatch(v)) {
                        return 'Start with a letter, use letters & numbers only (e.g. Raja123)';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppDimensions.margin16),
                  
                  // Password Field
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
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
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
                  
                  // Terms and Privacy Checkbox
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Checkbox(
                        value: _agreeToTerms,
                        onChanged: (value) {
                          setState(() {
                            _agreeToTerms = value ?? false;
                          });
                        },
                        activeColor: AppColors.primaryGreen,
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(top: AppDimensions.padding12),
                          child: RichText(
                            text: TextSpan(
                              style: theme.textTheme.bodyMedium,
                              children: [
                                const TextSpan(text: 'I agree to the '),
                                TextSpan(
                                  text: AppStrings.termsOfServices,
                                  style: const TextStyle(
                                    color: AppColors.primaryGreen,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const TextSpan(text: ' & '),
                                TextSpan(
                                  text: AppStrings.privacyPolicy,
                                  style: const TextStyle(
                                    color: AppColors.primaryGreen,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppDimensions.margin24),
                  
                  // Register Button
                  AppButton(
                    text: AppStrings.register,
                    onPressed: state is AuthLoading ? null : _handleRegister,
                    isLoading: state is AuthLoading,
                    backgroundColor: AppColors.textBlack,
                    textColor: AppColors.textWhite,
                  ),
                  const SizedBox(height: AppDimensions.margin16),
                  
                  AuthLinkRow(
                    text: AppStrings.haveAccount,
                    linkText: AppStrings.login,
                    onLinkTap: () => context.go(AppRoutes.login),
                  ),
                  const SizedBox(height: AppDimensions.margin24),
                  
                  AuthSectionDivider(text: AppStrings.orRegisterWith),
                  const SizedBox(height: AppDimensions.margin16),
                  AuthSocialIcons(
                    items: [
                      AuthSocialIconItem(
                        icon: Icons.g_mobiledata,
                        onTap: () => context.read<AuthCubit>().signInWithGoogle(),
                      ),
                      AuthSocialIconItem(
                        icon: Icons.facebook,
                        onTap: () => context.read<AuthCubit>().signInWithFacebook(),
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
}

