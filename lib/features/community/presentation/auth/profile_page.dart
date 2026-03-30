import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:rxdart/rxdart.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../../../core/widgets/app_button.dart';
import '../../../../application/addExpense/expense_cubit.dart';
import '../../../../application/group/group_cubit.dart';
import '../../../../core/utils/theme_cubit.dart';
import '../../../../data/models/expense_model.dart';
import '../../../../data/models/group_model.dart';
import '../../../../data/models/user_model.dart';
import '../../../../application/auth/auth_cubit.dart';
import 'widgets/auth_widgets.dart';
import 'package:google_fonts/google_fonts.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final extraProviders = [
      if (di.sl.isRegistered<GroupCubit>())
        BlocProvider(create: (_) => di.sl<GroupCubit>()),
      if (di.sl.isRegistered<ExpenseCubit>())
        BlocProvider(create: (_) => di.sl<ExpenseCubit>()),
    ];

    final child = Scaffold(
      backgroundColor: AppColors.stemBackground ,
      body: SafeArea(
        child: BlocConsumer<AuthCubit, AuthState>(
          listener: (context, state) {
            if (state is AuthError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.message)),
              );
            }
          },
          builder: (context, state) {
            if (state is AuthLoading && state is! AuthSuccess) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is AuthSuccess) {
              return _ProfileContent(
                user: state.user,
                isDark: isDark,
                theme: theme,
                authCubit: context.read<AuthCubit>(),
              );
            }

            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppDimensions.padding24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.person_outline,
                      size: 64,
                      color: AppColors.textGrey,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Please log in to view your profile',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: AppColors.textGrey,
                      ),
                    ),
                    const SizedBox(height: 24),
                    AppButton(
                      text: 'Log In',
                      onPressed: () => context.go(AppRoutes.login),
                      backgroundColor: AppColors.primaryGreen,
                      textColor: AppColors.textWhite,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );

    if (extraProviders.isEmpty) return child;
    return MultiBlocProvider(
      providers: extraProviders,
      child: child,
    );
  }
}

class _ProfileContent extends StatefulWidget {
  final UserModel user;
  final bool isDark;
  final ThemeData theme;
  final AuthCubit authCubit;

  const _ProfileContent({
    required this.user,
    required this.isDark,
    required this.theme,
    required this.authCubit,
  });

  @override
  State<_ProfileContent> createState() => _ProfileContentState();
}

class _ProfileContentState extends State<_ProfileContent> {
  bool _isEditMode = false;
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _upiController;
  File? _selectedPhoto;
  String? _profilePhone; // From Firestore (when user didn't login with phone)
  String? _profileUpiId; // From Firestore
  final _formKey = GlobalKey<FormState>();
  final _imagePicker = ImagePicker();

  bool get _canEditPhone =>
      widget.user.phoneNumber == null || widget.user.phoneNumber!.isEmpty;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.name ?? '');
    _phoneController = TextEditingController();
    _upiController = TextEditingController();
    if (_canEditPhone) {
      _loadProfilePhone();
    }
    _loadProfileUpiId();
  }

  Future<void> _loadProfilePhone() async {
    final phone = await widget.authCubit.getProfilePhone(widget.user.uid);
    if (mounted) {
      setState(() {
        _profilePhone = phone;
        _phoneController.text = phone ?? '';
      });
    }
  }

  Future<void> _loadProfileUpiId() async {
    final upiId = await widget.authCubit.getUpiId(widget.user.uid);
    if (mounted) {
      setState(() {
        _profileUpiId = upiId;
        _upiController.text = upiId ?? '';
      });
    }
  }

  @override
  void didUpdateWidget(covariant _ProfileContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.user != widget.user && !_isEditMode) {
      _nameController.text = widget.user.name ?? '';
      if (_canEditPhone && oldWidget.user.uid == widget.user.uid) {
        _loadProfilePhone();
      }
      if (oldWidget.user.uid == widget.user.uid) {
        _loadProfileUpiId();
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _upiController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _imagePicker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );
      if (picked != null && mounted) {
        setState(() => _selectedPhoto = File(picked.path));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick image: $e')),
        );
      }
    }
  }

  void _showImageSourcePicker() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _handleSave() {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    final phone = _canEditPhone ? _phoneController.text.trim() : null;
    final upiId = _upiController.text.trim();
    final hasChanges = name != (widget.user.name ?? '') ||
        _selectedPhoto != null ||
        (phone != null && phone != (_profilePhone ?? '')) ||
        upiId != (_profileUpiId ?? '');
    if (!hasChanges) {
      setState(() {
        _isEditMode = false;
        _selectedPhoto = null;
      });
      return;
    }

    widget.authCubit.updateProfile(
      name: name.isEmpty ? null : name,
      photoFile: _selectedPhoto,
      phone: _canEditPhone ? phone : null,
      upiId: upiId.isEmpty ? null : upiId,
    );
  }

  void _cancelEdit() {
    setState(() {
      _isEditMode = false;
      _nameController.text = widget.user.name ?? '';
      _phoneController.text = _profilePhone ?? '';
      _upiController.text = _profileUpiId ?? '';
      _selectedPhoto = null;
    });
  }

  Widget _buildEditAvatarSection({required String initial}) {
    return Center(
      child: Column(
        children: [
          Container(
            width: 128,
            height: 128,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [AppColors.stemEmerald, AppColors.primaryGreenDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            padding: const EdgeInsets.all(4),
            child: ProfileAvatarPicker(
              photoUrl: widget.user.photoUrl,
              localFile: _selectedPhoto,
              initial: initial,
              radius: 50,
              showCameraOverlay: true,
              onTap: _showImageSourcePicker,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'UPDATE AVATAR',
            style: GoogleFonts.manrope(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: AppColors.stemMutedText,
              letterSpacing: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    final displayName = user.name ?? 'User';
    final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : '?';

    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthSuccess && _isEditMode) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile updated successfully')),
          );
          setState(() {
            _isEditMode = false;
            _selectedPhoto = null;
            _nameController.text = state.user.name ?? '';
            if (_canEditPhone) {
              _profilePhone = _phoneController.text.trim().isEmpty
                  ? null
                  : _phoneController.text.trim();
            }
            _profileUpiId = _upiController.text.trim().isEmpty
                ? null
                : _upiController.text.trim();
          });
        }
      },
      child: _isEditMode
          ? _buildEditMode(initial)
          : _buildLedgerProfileView(user, initial),
    );
  }

  Widget _buildEditMode(String initial) {
    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimensions.padding16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _LedgerTopHeader(
                  title: 'Edit Profile',
                  leadingIcon: Icons.arrow_back_ios_new,
                  leadingOnTap: _cancelEdit,
                  trailing: null,
                ),
                const SizedBox(height: 24),
                _buildEditAvatarSection(initial: initial),
                const SizedBox(height: 16),
                _LedgerInfoCard(
                  isDark: widget.isDark,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _LedgerField(
                        label: 'Full Name',
                        child: TextFormField(
                          controller: _nameController,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: AppColors.stemLightText,
                          ),
                          decoration: const InputDecoration(
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            border: InputBorder.none,
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Please enter your name'
                              : null,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _LedgerField(
                        label: 'Email Address',
                        child: _LedgerReadOnlyValue(
                          value: (widget.user.email.isNotEmpty
                              ? widget.user.email
                              : 'Not set'),
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (_canEditPhone) ...[
                        _LedgerField(
                          label: 'Phone Number',
                          child: TextFormField(
                            controller: _phoneController,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: AppColors.stemLightText,
                            ),
                            keyboardType: TextInputType.phone,
                            decoration: const InputDecoration(
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              border: InputBorder.none,
                              hintText: '+92 300 1234567',
                              hintStyle: TextStyle(
                                color: AppColors.textGreyLight,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      _LedgerField(
                        label: 'UPI ID for Settlement',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            TextFormField(
                              controller: _upiController,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppColors.stemEmerald,
                              ),
                              decoration: const InputDecoration(
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                border: InputBorder.none,
                                hintText: 'yourname@upi',
                                hintStyle: TextStyle(
                                  color: AppColors.textGreyLight,
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'This ID will be used for all automatic settlements with your groups.',
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.stemMutedText,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _LedgerSecurityCard(),
                const SizedBox(height: 120), // Space for fixed footer
              ],
            ),
          ),
        ),
        Positioned(
          left: 24,
          right: 24,
          bottom: 24,
          child: GestureDetector(
            onTap: _handleSave,
            child: Container(
              height: 56,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.stemEmerald, AppColors.primaryGreenDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(AppDimensions.radius12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.4),
                    blurRadius: 40,
                    offset: const Offset(0, 20),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  'Save Changes',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF003B29),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLedgerProfileView(UserModel user, String initial) {
    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppDimensions.padding16,
            AppDimensions.padding16,
            AppDimensions.padding16,
            112,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _LedgerTopHeader(
                title: 'Profile',
                leadingIcon: Icons.arrow_back_ios_new,
                leadingOnTap: () => context.pop(),
                trailing: IconButton(
                  onPressed: () => context.push(AppRoutes.settings),
                  icon: const Icon(Icons.settings_outlined),
                  color: AppColors.stemLightText,
                ),
              ),
              const SizedBox(height: 28),
              _LedgerProfileHero(
                user: user,
                phone: user.phoneNumber ?? _profilePhone ?? 'Not set',
                initial: initial,
              ),
              const SizedBox(height: 24),
              _LedgerFinancialSummary(
                userId: user.uid,
                currencySymbol: _currencySymbolFromFirstGroup(),
              ),
              const SizedBox(height: 24),
              _LedgerPreferences(
                onPersonalInfo: () => setState(() => _isEditMode = true),
                onLogout: widget.authCubit.logout,
              ),
              const SizedBox(height: 24),
              Text(
                'JobCrak Ledger v2.4.1',
                textAlign: TextAlign.center,
                style: GoogleFonts.manrope(
                  fontSize: 10,
                  color: AppColors.stemGreyText,
                  letterSpacing: 2.0,
                ),
              ),
            ],
          ),
        ),

      ],
    );
  }

  String _currencySymbolFromFirstGroup() {
    // Default to INR symbol for UI; actual summary uses real currency computed from groups below.
    return '₹';
  }
}

class _LedgerTopHeader extends StatelessWidget {
  final String title;
  final IconData leadingIcon;
  final VoidCallback leadingOnTap;
  final Widget? trailing;

  const _LedgerTopHeader({
    required this.title,
    required this.leadingIcon,
    required this.leadingOnTap,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.padding16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: leadingOnTap,
            icon: Icon(leadingIcon, color: AppColors.stemMutedText),
          ),
          Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.stemEmerald,
              letterSpacing: -0.4,
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class _LedgerProfileHero extends StatelessWidget {
  final UserModel user;
  final String phone;
  final String initial;

  const _LedgerProfileHero({
    required this.user,
    required this.phone,
    required this.initial,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 128,
          height: 128,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [AppColors.stemEmerald, AppColors.primaryGreenDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          padding: const EdgeInsets.all(4),
          child: ProfileAvatarPicker(
            photoUrl: user.photoUrl,
            initial: initial,
            radius: 50,
            showCameraOverlay: false,
          ),
        ),
        const SizedBox(height: 18),
        Text(
          user.name ?? 'User',
          textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: AppColors.stemLightText,
            letterSpacing: -0.6,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          user.email.isNotEmpty ? user.email : 'Not set',
          textAlign: TextAlign.center,
          style: GoogleFonts.manrope(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: AppColors.stemMutedText,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          phone,
          textAlign: TextAlign.center,
          style: GoogleFonts.manrope(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: AppColors.stemMutedText,
          ),
        ),
      ],
    );
  }
}

class _LedgerInfoCard extends StatelessWidget {
  final bool isDark;
  final Widget child;

  const _LedgerInfoCard({
    required this.isDark,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
        child: Container(
          padding: const EdgeInsets.all(25),
          decoration: BoxDecoration(
            color: const Color(0xAA2A2A2A),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.borderGreyDark.withOpacity(0.15),
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _LedgerField extends StatelessWidget {
  final String label;
  final Widget child;

  const _LedgerField({
    required this.label,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.manrope(
            fontSize: 10,
            fontWeight: FontWeight.w400,
            letterSpacing: 0.5,
            color: AppColors.stemMutedText,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.stemCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.borderGreyDark.withOpacity(0.1),
            ),
          ),
          child: child,
        ),
      ],
    );
  }
}

class _LedgerReadOnlyValue extends StatelessWidget {
  final String value;

  const _LedgerReadOnlyValue({required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 13),
      child: Text(
        value,
        style: GoogleFonts.manrope(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: AppColors.stemMutedText,
        ),
      ),
    );
  }
}

class _LedgerSecurityCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(17),
          decoration: BoxDecoration(
            color: const Color(0xAA2A2A2A),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.borderGreyDark.withOpacity(0.15),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.stemEmerald.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.shield_outlined,
                    color: AppColors.stemEmerald, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Security Settings',
                      style: GoogleFonts.manrope(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.stemLightText,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '2FA and password management',
                      style: GoogleFonts.manrope(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: AppColors.stemMutedText,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.stemMutedText),
            ],
          ),
        ),
      ),
    );
  }
}

class _LedgerFinancialSummary extends StatelessWidget {
  final String userId;
  final String currencySymbol;

  const _LedgerFinancialSummary({
    required this.userId,
    required this.currencySymbol,
  });

  String _symbolFromCurrency(String currency) {
    switch (currency) {
      case 'INR':
        return '₹';
      case 'PKR':
        return 'Rs.';
      case 'USD':
        return '\$';
      default:
        return currency;
    }
  }

  @override
  Widget build(BuildContext context) {
    GroupCubit? groupCubit;
    ExpenseCubit? expenseCubit;
    try {
      groupCubit = BlocProvider.of<GroupCubit>(context);
      expenseCubit = BlocProvider.of<ExpenseCubit>(context);
    } catch (_) {
      // Providers not available (e.g., Firebase not initialized). Show zeroed summary.
    }

    if (groupCubit == null || expenseCubit == null) {
      return _LedgerTotalCard(
        net: 0,
        youAreOwed: 0,
        youOwe: 0,
        currencySymbol: currencySymbol,
      );
    }

    final groupCubitNonNull = groupCubit;
    final expenseCubitNonNull = expenseCubit;

    return StreamBuilder<List<GroupModel>>(
      stream: groupCubitNonNull.getUserGroupsStream(),
      builder: (context, groupsSnap) {
        final groups = groupsSnap.data ?? [];
        if (groups.isEmpty) {
          return _LedgerTotalCard(
            net: 0,
            youAreOwed: 0,
            youOwe: 0,
            currencySymbol: currencySymbol,
          );
        }

        final expensesStreams = groups
            .map((g) => expenseCubitNonNull.getGroupExpenses(g.id))
            .toList();

        return StreamBuilder<List<List<ExpenseModel>>>(
          stream: Rx.combineLatestList<List<ExpenseModel>>(expensesStreams),
          builder: (context, snap) {
            double totalOwed = 0;
            double totalLent = 0;
            if (snap.hasData) {
              for (final expenses in snap.data!) {
                final balances =
                    ExpenseCubit.calculateBalances(userId, expenses);
                for (final v in balances.values) {
                  if (v > 0) totalOwed += v;
                  if (v < 0) totalLent += -v;
                }
              }
            }
            final net = totalLent - totalOwed;
            final symbol = _symbolFromCurrency(groups.first.currency);
            return _LedgerTotalCard(
              net: net,
              youAreOwed: totalLent,
              youOwe: totalOwed,
              currencySymbol: symbol,
            );
          },
        );
      },
    );
  }
}

class _LedgerTotalCard extends StatelessWidget {
  final double net;
  final double youAreOwed;
  final double youOwe;
  final String currencySymbol;

  const _LedgerTotalCard({
    required this.net,
    required this.youAreOwed,
    required this.youOwe,
    required this.currencySymbol,
  });

  String _fmt(double value) {
    final rounded = value.abs().round();
    return NumberFormat('#,##0').format(rounded);
  }

  @override
  Widget build(BuildContext context) {
    final isSettled = net >= 0;
    final netAbs = _fmt(net);
    return Container(
      decoration: BoxDecoration(
        color: AppColors.darkCard.withOpacity(0.85),
        borderRadius: BorderRadius.circular(AppDimensions.radius24),
        border: Border.all(
          color: AppColors.stemEmerald.withOpacity(0.08),
        ),
      ),
      padding: const EdgeInsets.all(24),
      child: Stack(
        children: [
          Positioned(
            top: -96,
            right: -96,
            child: Container(
              width: 192,
              height: 192,
              decoration: BoxDecoration(
                color: AppColors.stemEmerald.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Total Net Balance',
                style: GoogleFonts.manrope(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                  color: AppColors.stemMutedText,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    '${currencySymbol}${netAbs}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 36,
                      fontWeight: FontWeight.w800,
                      color: AppColors.stemLightText,
                      letterSpacing: -1.8,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.stemEmerald.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      isSettled ? 'Settled' : 'Pending',
                      style: GoogleFonts.manrope(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.stemEmerald,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _LedgerMiniTile(
                      backgroundColor: const Color(0xFF201F1F),
                      title: 'You are owed',
                      value: youAreOwed,
                      currencySymbol: currencySymbol,
                      valueColor: AppColors.stemEmerald,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _LedgerMiniTile(
                      backgroundColor: const Color(0xFF201F1F),
                      title: 'You owe',
                      value: youOwe,
                      currencySymbol: currencySymbol,
                      valueColor: AppColors.stemOweColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LedgerMiniTile extends StatelessWidget {
  final Color backgroundColor;
  final String title;
  final double value;
  final String currencySymbol;
  final Color valueColor;

  const _LedgerMiniTile({
    required this.backgroundColor,
    required this.title,
    required this.value,
    required this.currencySymbol,
    required this.valueColor,
  });

  String _fmt(double v) {
    final rounded = v.abs().round();
    return NumberFormat('#,##0').format(rounded);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.manrope(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.0,
              color: valueColor.withOpacity(0.9),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '$currencySymbol${_fmt(value)}',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.stemLightText,
            ),
          ),
        ],
      ),
    );
  }
}

class _LedgerPreferences extends StatelessWidget {
  final VoidCallback onPersonalInfo;
  final VoidCallback onLogout;

  const _LedgerPreferences({
    required this.onPersonalInfo,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Account Preferences',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.stemMutedText,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: AppColors.darkCard.withOpacity(0.85),
            borderRadius: BorderRadius.circular(AppDimensions.radius24),
          ),
          child: Column(
            children: [
              _LedgerPrefRow(
                iconBg: AppColors.stemInactive,
                icon: Icons.person_outline,
                title: 'Personal Information',
                subtitle: null,
                onTap: onPersonalInfo,
              ),
              _LedgerDivider(),
              _LedgerPrefRow(
                iconBg: AppColors.stemInactive,
                icon: Icons.credit_card_outlined,
                title: 'Payment Methods',
                subtitle: 'UPI ID, Bank Account',
                onTap: () {},
              ),
              _LedgerDivider(),
              _LedgerPrefRow(
                iconBg: AppColors.stemInactive,
                icon: Icons.notifications_none_outlined,
                title: 'Notification Settings',
                subtitle: null,
                onTap: () => context.push(AppRoutes.messages),
              ),
              _LedgerDivider(),
              _LedgerPrefThemeRow(),
              _LedgerDivider(),
              _LedgerPrefRow(
                iconBg: AppColors.stemInactive,
                icon: Icons.help_outline,
                title: 'Help & Support',
                subtitle: null,
                onTap: () {},
              ),
              _LedgerDivider(),
              _LedgerLogoutRow(onLogout: onLogout),
            ],
          ),
        ),
      ],
    );
  }
}

class _LedgerDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 1,
      color: AppColors.borderGreyDark.withOpacity(0.2),
    );
  }
}

class _LedgerPrefRow extends StatelessWidget {
  final Color iconBg;
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  const _LedgerPrefRow({
    required this.iconBg,
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppColors.stemLightText, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.manrope(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.stemLightText,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle!,
                      style: GoogleFonts.manrope(
                        fontSize: 10,
                        fontWeight: FontWeight.w400,
                        color: AppColors.stemMutedText,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.stemMutedText),
          ],
        ),
      ),
    );
  }
}

class _LedgerPrefThemeRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeCubit, ThemeState>(
      builder: (context, state) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.stemInactive,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.color_lens_outlined,
                    color: AppColors.stemLightText, size: 18),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  'App Theme',
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.stemLightText,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: AppColors.stemEmerald.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Switch(
                  value: state.isDarkMode,
                  onChanged: (_) => context.read<ThemeCubit>().toggleTheme(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _LedgerLogoutRow extends StatelessWidget {
  final VoidCallback onLogout;

  const _LedgerLogoutRow({required this.onLogout});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onLogout,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.stemOweColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.logout_outlined,
                  color: AppColors.stemOweColor, size: 18),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                'Logout',
                style: GoogleFonts.manrope(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.stemOweColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
