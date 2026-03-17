import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_fonts.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../data/models/user_model.dart';
import '../../../../application/auth/auth_cubit.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.backgroundWhite,
      appBar: AppBar(
        title: const Text('My Profile'),
        foregroundColor: isDark ? AppColors.textWhite : AppColors.textBlack,
      ),
      body: BlocConsumer<AuthCubit, AuthState>(
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
  File? _selectedPhoto;
  String? _profilePhone; // From Firestore (when user didn't login with phone)
  final _formKey = GlobalKey<FormState>();
  final _imagePicker = ImagePicker();

  bool get _canEditPhone => widget.user.phoneNumber == null || widget.user.phoneNumber!.isEmpty;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.name ?? '');
    _phoneController = TextEditingController();
    if (_canEditPhone) {
      _loadProfilePhone();
    }
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

  @override
  void didUpdateWidget(covariant _ProfileContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.user != widget.user && !_isEditMode) {
      _nameController.text = widget.user.name ?? '';
      if (_canEditPhone && oldWidget.user.uid == widget.user.uid) {
        _loadProfilePhone();
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
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
    final hasChanges = name != (widget.user.name ?? '') ||
        _selectedPhoto != null ||
        (phone != null && phone != (_profilePhone ?? ''));
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
    );
  }

  void _cancelEdit() {
    setState(() {
      _isEditMode = false;
      _nameController.text = widget.user.name ?? '';
      _phoneController.text = _profilePhone ?? '';
      _selectedPhoto = null;
    });
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
          });
        }
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.padding16),
        child: _isEditMode ? _buildEditForm(initial) : _buildViewMode(user, initial),
      ),
    );
  }

  Widget _buildEditForm(String initial) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          const SizedBox(height: AppDimensions.margin16),
          GestureDetector(
            onTap: _showImageSourcePicker,
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: AppColors.primaryGreen,
                  child: _selectedPhoto != null
                      ? ClipOval(
                          child: Image.file(
                            _selectedPhoto!,
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                          ),
                        )
                      : widget.user.photoUrl != null &&
                              widget.user.photoUrl!.isNotEmpty
                          ? ClipOval(
                              child: CachedNetworkImage(
                                imageUrl: widget.user.photoUrl!,
                                width: 100,
                                height: 100,
                                fit: BoxFit.cover,
                                placeholder: (_, __) =>
                                    const CircularProgressIndicator(),
                                errorWidget: (_, __, ___) => Text(
                                  initial,
                                  style: const TextStyle(
                                    fontSize: AppFonts.fontSize36,
                                    color: AppColors.textWhite,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            )
                          : Text(
                              initial,
                              style: const TextStyle(
                                fontSize: AppFonts.fontSize36,
                                color: AppColors.textWhite,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: AppColors.primaryGreen,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      color: AppColors.textWhite,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap to change photo',
            style: TextStyle(
              fontSize: AppFonts.fontSize12,
              color: AppColors.textGrey,
            ),
          ),
          const SizedBox(height: 24),
          AppTextField(
            label: 'Name',
            controller: _nameController,
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Please enter your name' : null,
          ),
          if (_canEditPhone) ...[
            const SizedBox(height: 16),
            AppTextField(
              label: 'Phone',
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              hint: '+92 300 1234567',
            ),
          ],
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _cancelEdit,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primaryGreen,
                    side: const BorderSide(color: AppColors.primaryGreen),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: AppButton(
                  text: 'Save',
                  onPressed: _handleSave,
                  backgroundColor: AppColors.primaryGreen,
                  textColor: AppColors.textWhite,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildViewMode(UserModel user, String initial) {
    return Column(
      children: [
        const SizedBox(height: AppDimensions.margin16),
        CircleAvatar(
          radius: 50,
          backgroundColor: AppColors.primaryGreen,
          child: user.photoUrl != null && user.photoUrl!.isNotEmpty
              ? ClipOval(
                  child: CachedNetworkImage(
                    imageUrl: user.photoUrl!,
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => const CircularProgressIndicator(),
                    errorWidget: (_, __, ___) => Text(
                      initial,
                      style: const TextStyle(
                        fontSize: AppFonts.fontSize36,
                        color: AppColors.textWhite,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                )
              : Text(
                  initial,
                  style: const TextStyle(
                    fontSize: AppFonts.fontSize36,
                    color: AppColors.textWhite,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
        const SizedBox(height: 12),
        Text(
          user.name ?? 'User',
          style: widget.theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: widget.isDark ? AppColors.textWhite : AppColors.textBlack,
          ),
        ),
        const SizedBox(height: AppDimensions.margin32),
        _ProfileInfoCard(
          isDark: widget.isDark,
          icon: Icons.email_outlined,
          label: 'Email',
          value: user.email.isNotEmpty ? user.email : 'Not set',
        ),
        const SizedBox(height: AppDimensions.margin12),
        _ProfileInfoCard(
          isDark: widget.isDark,
          icon: Icons.phone_outlined,
          label: 'Phone',
          value: user.phoneNumber ?? _profilePhone ?? 'Not set',
        ),
        const SizedBox(height: AppDimensions.margin12),
        _ProfileInfoCard(
          isDark: widget.isDark,
          icon: Icons.badge_outlined,
          label: 'User ID',
          value: user.uid,
          showCopy: true,
          onCopy: () {
            Clipboard.setData(ClipboardData(text: user.uid)).then((_) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                        'User ID copied. Share this to get added to groups.'),
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            });
          },
        ),
        const SizedBox(height: AppDimensions.margin32),
        InkWell(
          onTap: () => context.push(AppRoutes.settings),
          borderRadius: BorderRadius.circular(AppDimensions.radius12),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppDimensions.padding16),
            decoration: BoxDecoration(
              color: widget.isDark ? AppColors.darkCard : AppColors.backgroundGrey,
              borderRadius: BorderRadius.circular(AppDimensions.radius12),
            ),
            child: Row(
              children: [
                Icon(Icons.settings_outlined, color: AppColors.primaryGreen),
                const SizedBox(width: 16),
                Text(
                  'Settings',
                  style: TextStyle(
                    fontSize: AppFonts.fontSize16,
                    fontWeight: FontWeight.w500,
                    color: widget.isDark ? AppColors.textWhite : AppColors.textBlack,
                  ),
                ),
                const Spacer(),
                Icon(Icons.chevron_right, color: AppColors.textGrey),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppDimensions.margin16),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => setState(() => _isEditMode = true),
            icon: const Icon(Icons.edit_outlined, size: 20),
            label: const Text('Edit Profile'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primaryGreen,
              side: const BorderSide(color: AppColors.primaryGreen),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
        const SizedBox(height: AppDimensions.margin16),
        SizedBox(
          width: double.infinity,
          child: AppButton(
            text: 'Log Out',
            onPressed: () => widget.authCubit.logout(),
            backgroundColor: AppColors.error,
            textColor: AppColors.textWhite,
          ),
        ),
      ],
    );
  }
}

class _ProfileInfoCard extends StatelessWidget {
  final bool isDark;
  final IconData icon;
  final String label;
  final String value;
  final bool showCopy;
  final VoidCallback? onCopy;

  const _ProfileInfoCard({
    required this.isDark,
    required this.icon,
    required this.label,
    required this.value,
    this.showCopy = false,
    this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.padding16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.backgroundGrey,
        borderRadius: BorderRadius.circular(AppDimensions.radius12),
        border: Border.all(
          color: isDark ? AppColors.borderGreyDark : AppColors.borderGrey,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: AppColors.primaryGreen,
            size: 24,
          ),
          const SizedBox(width: AppDimensions.margin16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: AppFonts.fontSize12,
                    color: AppColors.textGrey,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: AppFonts.fontSize14,
                    fontWeight: FontWeight.w500,
                    color: isDark ? AppColors.textWhite : AppColors.textBlack,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (showCopy && onCopy != null)
            IconButton(
              icon: const Icon(Icons.copy_outlined, size: 20),
              onPressed: onCopy,
              color: AppColors.primaryGreen,
            ),
        ],
      ),
    );
  }
}
