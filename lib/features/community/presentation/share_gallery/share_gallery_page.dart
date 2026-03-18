import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_fonts.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/di/injection_container.dart' as di;
import 'widgets/share_gallery_widgets.dart';
import '../../data/datasources/group_remote_datasource.dart';
import '../../../../application/sheredGallery/shared_gallery_cubit.dart';

class ShareGalleryPage extends StatefulWidget {
  const ShareGalleryPage({Key? key}) : super(key: key);

  @override
  State<ShareGalleryPage> createState() => _ShareGalleryPageState();
}

class _ShareGalleryPageState extends State<ShareGalleryPage> {
  final _friendController = TextEditingController();
  final List<File> _selectedImages = [];
  final List<_FriendItem> _friends = [];
  bool _isAddingFriend = false;

  @override
  void dispose() {
    _friendController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final images = await picker.pickMultiImage();
    if (images.isEmpty) return;
    setState(() {
      for (final x in images) {
        _selectedImages.add(File(x.path));
      }
    });
  }

  Future<void> _addFriend() async {
    final input = _friendController.text.trim();
    if (input.isEmpty) return;

    setState(() => _isAddingFriend = true);
    try {
      final userId = await di.sl<GroupRemoteDataSource>().findUserIdByEmailOrPhone(input);
      if (userId == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('User not found: $input. They must have an account.')),
          );
        }
        return;
      }
      final currentUserId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == currentUserId) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cannot share with yourself')),
          );
        }
        return;
      }
      if (_friends.any((f) => f.userId == userId)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Already added')),
          );
        }
        return;
      }
      setState(() {
        _friends.add(_FriendItem(userId: userId, display: input));
        _friendController.clear();
      });
    } finally {
      if (mounted) setState(() => _isAddingFriend = false);
    }
  }

  void _removeFriend(_FriendItem f) {
    setState(() => _friends.remove(f));
  }

  void _removeImage(int index) {
    setState(() => _selectedImages.removeAt(index));
  }

  void _share() {
    if (_selectedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select at least one image')),
      );
      return;
    }
    if (_friends.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one friend')),
      );
      return;
    }
    context.read<SharedGalleryCubit>().shareGallery(
          imageFiles: _selectedImages,
          sharedWithUserIds: _friends.map((f) => f.userId).toList(),
        );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.backgroundWhite,
      appBar: AppBar(
        title: const Text('Share Gallery'),
        backgroundColor: isDark ? AppColors.darkCard : AppColors.backgroundWhite,
      ),
      body: SafeArea(
        child: BlocListener<SharedGalleryCubit, SharedGalleryState>(
        listener: (context, state) {
          if (state is SharedGalleryShared) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Gallery shared successfully!')),
            );
            context.pop();
          } else if (state is SharedGalleryError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimensions.padding16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SectionTitle(text: '1. Select photos to share', isDark: isDark),
              const SizedBox(height: AppDimensions.margin8),
              PhotoPickerArea(
                selectedImages: _selectedImages,
                onTap: _pickImages,
                onRemoveImage: _removeImage,
              ),
              const SizedBox(height: AppDimensions.margin24),
              SectionTitle(text: '2. Select friends who can access', isDark: isDark),
              const SizedBox(height: AppDimensions.margin8),
              Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      hint: 'Email or phone',
                      controller: _friendController,
                      keyboardType: TextInputType.emailAddress,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _isAddingFriend ? null : _addFriend,
                    icon: _isAddingFriend
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.add),
                    style: IconButton.styleFrom(backgroundColor: AppColors.primaryGreen),
                  ),
                ],
              ),
              if (_friends.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _friends.map((f) {
                    return Chip(
                      label: Text(f.display),
                      deleteIcon: const Icon(Icons.close, size: 18),
                      onDeleted: () => _removeFriend(f),
                      backgroundColor: AppColors.primaryGreen.withOpacity(0.2),
                    );
                  }).toList(),
                ),
              ],
              const SizedBox(height: AppDimensions.margin32),
              BlocBuilder<SharedGalleryCubit, SharedGalleryState>(
                builder: (context, state) {
                  return AppButton(
                    text: 'Share Gallery',
                    onPressed: state is SharedGalleryLoading ? null : _share,
                    isLoading: state is SharedGalleryLoading,
                  );
                },
              ),
            ],
          ),
        ),
        ),
      ),
    );
  }
}

class _FriendItem {
  final String userId;
  final String display;
  _FriendItem({required this.userId, required this.display});
}
