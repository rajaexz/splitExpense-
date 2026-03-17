import 'dart:io';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_fonts.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../data/models/group_model.dart';
import '../../../../application/group/group_cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CreateGroupPage extends StatefulWidget {
  const CreateGroupPage({super.key});

  @override
  State<CreateGroupPage> createState() => _CreateGroupPageState();
}

class _CreateGroupPageState extends State<CreateGroupPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  String _currency = 'PKR';
  String _category = 'trip';
  File? _groupImage;
  final _imagePicker = ImagePicker();
  bool _addTripDates = false;
  DateTime? _tripStartDate;
  DateTime? _tripEndDate;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickGroupImage() async {
    try {
      final picked = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );
      if (picked != null && mounted) {
        setState(() => _groupImage = File(picked.path));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick image: $e')),
        );
      }
    }
  }

  Future<String?> _uploadGroupImage() async {
    if (_groupImage == null) return null;
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid ?? 'anon';
      final ref = FirebaseStorage.instance
          .ref()
          .child('group_images')
          .child('${userId}_${DateTime.now().millisecondsSinceEpoch}.jpg');
      await ref.putFile(_groupImage!);
      return await ref.getDownloadURL();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Image upload failed. Group will be created without image.')),
        );
      }
      return null;
    }
  }

  Future<void> _selectDate(bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _tripStartDate ?? DateTime.now() : _tripEndDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null && mounted) {
      setState(() {
        if (isStart) {
          _tripStartDate = picked;
          if (_tripEndDate != null && _tripEndDate!.isBefore(picked)) {
            _tripEndDate = null;
          }
        } else {
          _tripEndDate = picked;
        }
      });
    }
  }

  Future<void> _createGroup() async {
    if (!_formKey.currentState!.validate()) return;

    const location = GeoPoint(0, 0);
    String? imageUrl;
    if (_groupImage != null) {
      imageUrl = await _uploadGroupImage();
      // imageUrl may be null if upload failed - group will still be created
    }

    final group = GroupModel(
      id: '',
      name: _nameController.text.trim(),
      description: '',
      creatorId: '',
      location: location,
      radius: 2000,
      type: 'public',
      currency: _currency,
      memberCount: 0,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      members: {},
      settings: GroupSettings(
        allowLocationSharing: true,
        allowExpenseTracking: true,
      ),
      category: _category,
      imageUrl: imageUrl,
      tripStartDate: _addTripDates ? _tripStartDate : null,
      tripEndDate: _addTripDates ? _tripEndDate : null,
    );

    if (mounted) {
      context.read<GroupCubit>().createGroup(group);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.backgroundWhite,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
        title: const Text('Create a group'),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () => _createGroup(),
            child: const Text('Done'),
          ),
        ],
      ),
      body: SafeArea(
        child: BlocListener<GroupCubit, GroupState>(
          listener: (context, state) {
          if (state is GroupCreated) {
            context.pop(true);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Group created successfully!')),
            );
          } else if (state is GroupError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimensions.padding16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Group name + image
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: _pickGroupImage,
                      child: Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkCard : AppColors.backgroundGrey,
                          borderRadius: BorderRadius.circular(AppDimensions.radius12),
                        ),
                        child: _groupImage != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(AppDimensions.radius12),
                                child: Image.file(_groupImage!, fit: BoxFit.cover),
                              )
                            : Icon(
                                Icons.add_a_photo,
                                color: isDark ? AppColors.textWhite : AppColors.textBlack,
                                size: 28,
                              ),
                      ),
                    ),
                    const SizedBox(width: AppDimensions.margin12),
                    Expanded(
                      child: TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          hintText: 'Group name',
                          border: UnderlineInputBorder(
                            borderSide: BorderSide(
                              color: isDark ? AppColors.textGrey : AppColors.borderGrey,
                            ),
                          ),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(
                              color: isDark ? AppColors.textGrey : AppColors.borderGrey,
                            ),
                          ),
                          focusedBorder: const UnderlineInputBorder(
                            borderSide: BorderSide(color: AppColors.primaryGreen, width: 2),
                          ),
                        ),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Enter group name' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppDimensions.margin24),

                // Type
                Text(
                  'Type',
                  style: TextStyle(
                    fontSize: AppFonts.fontSize14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.textWhite : AppColors.textBlack,
                  ),
                ),
                const SizedBox(height: AppDimensions.margin8),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: 2.2,
                  children: [
                    _buildTypeButton(isDark, 'trip', Icons.flight, 'Trip'),
                    _buildTypeButton(isDark, 'home', Icons.home, 'Home'),
                    _buildTypeButton(isDark, 'couple', Icons.favorite, 'Couple'),
                    _buildTypeButton(isDark, 'other', Icons.list, 'Other'),
                  ],
                ),
                const SizedBox(height: AppDimensions.margin24),

                // Add trip dates
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Add trip dates',
                      style: TextStyle(
                        fontSize: AppFonts.fontSize16,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.textWhite : AppColors.textBlack,
                      ),
                    ),
                    Switch(
                      value: _addTripDates,
                      onChanged: (v) => setState(() {
                        _addTripDates = v;
                        if (v && _tripStartDate == null) _tripStartDate = DateTime.now();
                      }),
                    ),
                  ],
                ),
                Text(
                  'Splitwise will remind friends to join, add expenses, and settle up.',
                  style: TextStyle(
                    fontSize: AppFonts.fontSize12,
                    color: AppColors.textGrey,
                  ),
                ),
                if (_addTripDates) ...[
                  const SizedBox(height: AppDimensions.margin16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildDateField(
                          isDark,
                          'Start',
                          _tripStartDate,
                          () => _selectDate(true),
                        ),
                      ),
                      const SizedBox(width: AppDimensions.margin12),
                      Expanded(
                        child: _buildDateField(
                          isDark,
                          'End',
                          _tripEndDate,
                          () => _selectDate(false),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: AppDimensions.margin24),

                // Currency
                Text(
                  'Expense Currency',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: AppDimensions.margin8),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'PKR', label: Text('PKR')),
                    ButtonSegment(value: 'INR', label: Text('INR')),
                    ButtonSegment(value: 'USD', label: Text('USD')),
                  ],
                  selected: {_currency},
                  onSelectionChanged: (Set<String> s) =>
                      setState(() => _currency = s.first),
                ),
                const SizedBox(height: AppDimensions.margin32),

                // Create Button
                BlocBuilder<GroupCubit, GroupState>(
                  builder: (context, state) {
                    return SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: state is GroupLoading ? null : _createGroup,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryGreen,
                          foregroundColor: AppColors.textWhite,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppDimensions.radius12),
                          ),
                        ),
                        child: state is GroupLoading
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.textWhite,
                                ),
                              )
                            : const Text('Create Group'),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    ),
    );
  }

  Widget _buildTypeButton(bool isDark, String value, IconData icon, String label) {
    final selected = _category == value;
    return OutlinedButton(
      onPressed: () => setState(() => _category = value),
      style: OutlinedButton.styleFrom(
        foregroundColor: isDark ? AppColors.textWhite : AppColors.textBlack,
        side: BorderSide(
          color: selected ? AppColors.primaryGreen : (isDark ? AppColors.textGrey : AppColors.borderGrey),
        ),
        backgroundColor: selected ? AppColors.primaryGreen.withValues(alpha: 0.2) : null,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
    );
  }

  Widget _buildDateField(
    bool isDark,
    String label,
    DateTime? date,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isDark ? AppColors.textGrey : AppColors.borderGrey,
            ),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textGrey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    date != null
                        ? '${date.day}/${date.month}/${date.year}'
                        : (label == 'Start' ? 'Today' : ''),
                    style: TextStyle(
                      fontSize: AppFonts.fontSize14,
                      color: isDark ? AppColors.textWhite : AppColors.textBlack,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.calendar_today, size: 20, color: AppColors.textGrey),
          ],
        ),
      ),
    );
  }
}
