import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_fonts.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../application/group/group_cubit.dart';

class AddMemberPage extends StatefulWidget {
  final String groupId;

  const AddMemberPage({
    Key? key,
    required this.groupId,
  }) : super(key: key);

  @override
  State<AddMemberPage> createState() => _AddMemberPageState();
}

enum _AddBy { email, phone, userId }

class _AddMemberPageState extends State<AddMemberPage> {
  final _inputController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  _AddBy _addBy = _AddBy.email;

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  void _addMember() {
    if (!_formKey.currentState!.validate()) return;

    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login first')),
      );
      return;
    }

    final input = _inputController.text.trim();
    context.read<GroupCubit>().addMemberByEmailOrPhone(widget.groupId, input);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.backgroundWhite,
      appBar: AppBar(
        title: const Text('Add Member'),
        backgroundColor: isDark ? AppColors.darkCard : AppColors.backgroundWhite,
      ),
      body: SafeArea(
        child: BlocListener<GroupCubit, GroupState>(
        listener: (context, state) {
          if (state is FriendAdded) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Member added successfully!')),
            );
            Navigator.of(context).pop();
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
                const SizedBox(height: AppDimensions.margin24),
                Icon(
                  Icons.person_add,
                  size: 64,
                  color: AppColors.primaryGreen,
                ),
                const SizedBox(height: AppDimensions.margin16),
                Text(
                  'Add Friend to Group',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppDimensions.margin8),
                Text(
                  'Add by email, phone, or user ID',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.textGrey,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppDimensions.margin24),
                Row(
                  children: [
                    _AddByChip(
                      label: 'Email',
                      isSelected: _addBy == _AddBy.email,
                      onTap: () => setState(() => _addBy = _AddBy.email),
                    ),
                    const SizedBox(width: 8),
                    _AddByChip(
                      label: 'Phone',
                      isSelected: _addBy == _AddBy.phone,
                      onTap: () => setState(() => _addBy = _AddBy.phone),
                    ),
                    const SizedBox(width: 8),
                    _AddByChip(
                      label: 'User ID',
                      isSelected: _addBy == _AddBy.userId,
                      onTap: () => setState(() => _addBy = _AddBy.userId),
                    ),
                  ],
                ),
                const SizedBox(height: AppDimensions.margin16),
                AppTextField(
                  label: _addBy == _AddBy.email
                      ? 'Email'
                      : _addBy == _AddBy.phone
                          ? 'Phone (with country code)'
                          : 'User ID',
                  hint: _addBy == _AddBy.email
                      ? 'friend@example.com'
                      : _addBy == _AddBy.phone
                          ? '+91 98765 43210'
                          : 'Enter user ID',
                  controller: _inputController,
                  keyboardType: _addBy == _AddBy.email
                      ? TextInputType.emailAddress
                      : _addBy == _AddBy.phone
                          ? TextInputType.phone
                          : TextInputType.text,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter ${_addBy == _AddBy.email ? "email" : _addBy == _AddBy.phone ? "phone" : "user ID"}';
                    }
                    if (_addBy == _AddBy.email && !value.contains('@')) {
                      return 'Enter a valid email';
                    }
                    if (_addBy == _AddBy.phone &&
                        value.replaceAll(RegExp(r'[\s\-]'), '').length < 10) {
                      return 'Enter a valid phone number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppDimensions.margin32),
                BlocBuilder<GroupCubit, GroupState>(
                  builder: (context, state) {
                    return AppButton(
                      text: 'Add Member',
                      onPressed: state is GroupLoading ? null : _addMember,
                      isLoading: state is GroupLoading,
                    );
                  },
                ),
                const SizedBox(height: AppDimensions.margin16),
                Container(
                  padding: const EdgeInsets.all(AppDimensions.padding12),
                  decoration: BoxDecoration(
                    color: AppColors.primaryGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppDimensions.radius12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: AppColors.primaryGreen),
                      const SizedBox(width: AppDimensions.margin8),
                      Expanded(
                        child: Text(
                          'Note: The user must have an account. Add by email, phone (+91/+92), or user ID from their profile.',
                          style: TextStyle(
                            fontSize: AppFonts.fontSize12,
                            color: isDark ? AppColors.textWhite : AppColors.textBlack,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        ),
      ),
    );
  }
}

class _AddByChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _AddByChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primaryGreen.withOpacity(0.15)
                : AppColors.backgroundGrey,
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
              fontSize: AppFonts.fontSize14,
            ),
          ),
        ),
      ),
    );
  }
}
