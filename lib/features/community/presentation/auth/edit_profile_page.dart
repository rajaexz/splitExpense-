import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_fonts.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/di/injection_container.dart' as di;
import 'widgets/auth_widgets.dart';
import '../../../../data/models/user_model.dart';
import '../../../../domain/auth_repository.dart';
import '../../../../application/auth/auth_cubit.dart';

class EditProfilePage extends StatefulWidget {
  final UserModel user;

  const EditProfilePage({super.key, required this.user});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  late TextEditingController _nameController;
  late TextEditingController _upiController;
  File? _selectedPhoto;
  String _initialUpiId = '';
  final _formKey = GlobalKey<FormState>();
  final _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.name ?? '');
    _upiController = TextEditingController();
    _loadUpiId();
  }

  Future<void> _loadUpiId() async {
    final upiId = await di.sl<AuthRepository>().getUpiId(widget.user.uid);
    if (mounted) {
      _initialUpiId = upiId ?? '';
      _upiController.text = _initialUpiId;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
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
    final upiId = _upiController.text.trim();
    final hasChanges = name != (widget.user.name ?? '') ||
        _selectedPhoto != null ||
        upiId != _initialUpiId;
    if (!hasChanges) {
      context.pop();
      return;
    }

    context.read<AuthCubit>().updateProfile(
          name: name.isEmpty ? null : name,
          photoFile: _selectedPhoto,
          upiId: upiId.isEmpty ? null : upiId,
        );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final displayName = widget.user.name ?? 'User';
    final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : '?';

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.backgroundWhite,
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: isDark ? AppColors.darkCard : AppColors.backgroundWhite,
        foregroundColor: isDark ? AppColors.textWhite : AppColors.textBlack,
        actions: [
          TextButton(
            onPressed: () => _handleSave(),
            child: const Text('Save'),
          ),
        ],
      ),
      body: BlocConsumer<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          } else if (state is AuthSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Profile updated successfully')),
            );
            context.pop();
          }
        },
        builder: (context, state) {
          final isLoading = state is AuthLoading;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppDimensions.padding16),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  const SizedBox(height: 24),
                  ProfileAvatarPicker(
                    photoUrl: widget.user.photoUrl,
                    localFile: _selectedPhoto,
                    initial: initial,
                    radius: 60,
                    showCameraOverlay: !isLoading,
                    onTap: isLoading ? null : _showImageSourcePicker,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap to change photo',
                    style: TextStyle(
                      fontSize: AppFonts.fontSize12,
                      color: AppColors.textGrey,
                    ),
                  ),
                  const SizedBox(height: 32),
                  AppTextField(
                    label: 'Name',
                    controller: _nameController,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter your name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    label: 'UPI ID',
                    hint: 'yourname@paytm or yourname@okaxis',
                    controller: _upiController,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'For receiving payments via QR. Others can scan and pay you directly.',
                    style: TextStyle(
                      fontSize: AppFonts.fontSize12,
                      color: AppColors.textGrey,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Read-only info
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppDimensions.padding16),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkCard : AppColors.backgroundGrey,
                      borderRadius:
                          BorderRadius.circular(AppDimensions.radius12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Email',
                          style: TextStyle(
                            fontSize: AppFonts.fontSize12,
                            color: AppColors.textGrey,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.user.email.isNotEmpty
                              ? widget.user.email
                              : 'Not set',
                          style: TextStyle(
                            fontSize: AppFonts.fontSize14,
                            color: isDark ? AppColors.textWhite : AppColors.textBlack,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Email and phone can only be changed by re-registering.',
                          style: TextStyle(
                            fontSize: AppFonts.fontSize12,
                            color: AppColors.textGrey,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: AppButton(
                      text: 'Save Changes',
                      onPressed: isLoading ? null : _handleSave,
                      isLoading: isLoading,
                      backgroundColor: AppColors.primaryGreen,
                      textColor: AppColors.textWhite,
                    ),
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
