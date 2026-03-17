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
              Text(
                '1. Select photos to share',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.textWhite : AppColors.textBlack,
                ),
              ),
              const SizedBox(height: AppDimensions.margin8),
              GestureDetector(
                onTap: _pickImages,
                child: Container(
                  height: 120,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCard : AppColors.backgroundGrey,
                    borderRadius: BorderRadius.circular(AppDimensions.radius12),
                    border: Border.all(
                      color: AppColors.primaryGreen,
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: _selectedImages.isEmpty
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.photo_library, size: 48, color: AppColors.primaryGreen),
                            const SizedBox(height: 8),
                            Text(
                              'Tap to select photos',
                              style: TextStyle(
                                fontSize: AppFonts.fontSize14,
                                color: AppColors.textGrey,
                              ),
                            ),
                          ],
                        )
                      : GridView.builder(
                          padding: const EdgeInsets.all(8),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 4,
                            crossAxisSpacing: 4,
                            mainAxisSpacing: 4,
                            childAspectRatio: 1,
                          ),
                          itemCount: _selectedImages.length,
                          itemBuilder: (context, i) {
                            return Stack(
                              fit: StackFit.expand,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.file(_selectedImages[i], fit: BoxFit.cover),
                                ),
                                Positioned(
                                  top: 4,
                                  right: 4,
                                  child: GestureDetector(
                                    onTap: () => _removeImage(i),
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(
                                        color: AppColors.error,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.close, size: 16, color: Colors.white),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                ),
              ),
              if (_selectedImages.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    '${_selectedImages.length} photo(s) selected',
                    style: TextStyle(fontSize: AppFonts.fontSize12, color: AppColors.textGrey),
                  ),
                ),
              const SizedBox(height: AppDimensions.margin24),
              Text(
                '2. Select friends who can access',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.textWhite : AppColors.textBlack,
                ),
              ),
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
