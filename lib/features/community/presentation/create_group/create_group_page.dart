import 'dart:io';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../data/models/group_model.dart';
import '../../../../application/group/group_cubit.dart';
import 'widgets/create_group_widgets.dart';
import 'widgets/stem_create_group_form.dart';

class CreateGroupPage extends StatefulWidget {
  final String? initialCategory;

  const CreateGroupPage({super.key, this.initialCategory});

  @override
  State<CreateGroupPage> createState() => _CreateGroupPageState();
}

class _CreateGroupPageState extends State<CreateGroupPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _gameAmountController = TextEditingController();
  String _currency = 'INR';
  String _category = 'trip';
  double _radiusKm = 2.5;
  File? _groupImage;
  final _imagePicker = ImagePicker();
  DateTime? _tripStartDate;
  DateTime? _tripEndDate;
  bool get _isGameModeEntry =>
      widget.initialCategory?.trim().toLowerCase() == 'game';

  @override
  void initState() {
    super.initState();
    final c = widget.initialCategory?.trim().toLowerCase();
    if (c != null && c.isNotEmpty) {
      _category = c;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _gameAmountController.dispose();
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
      description: _descController.text.trim(),
      creatorId: '',
      location: location,
      radius: _radiusKm * 1000,
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
      tripStartDate: _tripStartDate,
      tripEndDate: _tripEndDate,
      gamePerPersonAmount: _category == 'game'
          ? double.tryParse(_gameAmountController.text.trim())
          : null,
    );

    if (mounted) {
      context.read<GroupCubit>().createGroup(group);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.stemBackground,
      appBar: AppBar(
        backgroundColor: AppColors.stemBackground,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.stemLightText),
          onPressed: () => context.pop(),
        ),
        title: Text(
          _isGameModeEntry ? 'Create Game Group' : 'Create Group',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: AppColors.stemEmerald,
          ),
        ),
        actions: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.stemFormSurface,
            child: Icon(Icons.person, color: AppColors.stemMutedText, size: 20),
          ),
          const SizedBox(width: 24),
        ],
      ),
      body: SafeArea(
        child: BlocListener<GroupCubit, GroupState>(
          listener: (context, state) {
          if (state is GroupCreated) {
            context.pop({
              'groupId': state.groupId,
              'groupName': _nameController.text.trim(),
            });
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
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 144),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isGameModeEntry ? 'Create a Question Game Group' : 'Start a New Ledger',
                  style: GoogleFonts.poppins(
                    fontSize: 30,
                    fontWeight: FontWeight.w700,
                    color: AppColors.stemLightText,
                    letterSpacing: -0.75,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _isGameModeEntry
                      ? 'Create a dedicated game group. Set per-person game amount,\ninvite members, and start the turn-based question game.'
                      : 'Organize expenses with precision. Set your\nboundaries, invite members, and keep the\nbalance clear.',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: AppColors.stemMutedText,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 40),
                StemFormField(
                  label: 'GROUP NAME',
                  child: TextFormField(
                    controller: _nameController,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: AppColors.stemLightText,
                    ),
                    decoration: InputDecoration(
                      hintText: 'e.g. Summer in Tuscany',
                      hintStyle: GoogleFonts.poppins(
                        fontSize: 16,
                        color: AppColors.stemMutedText.withValues(alpha: 0.3),
                      ),
                      filled: true,
                      fillColor: AppColors.stemFormSurface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: const Color(0xFF404944).withValues(alpha: 0.2),
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 21,
                        vertical: 17,
                      ),
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Enter group name' : null,
                  ),
                ),
                const SizedBox(height: 23),
                StemFormField(
                  label: 'GROUP TYPE',
                  child: Container(
                    height: 58,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      color: AppColors.stemFormSurface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFF404944).withValues(alpha: 0.2),
                      ),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _category,
                        isExpanded: true,
                        dropdownColor: AppColors.stemFormSurface,
                        icon: Icon(
                          _isGameModeEntry
                              ? Icons.lock_outline
                              : Icons.keyboard_arrow_down,
                          color: AppColors.stemMutedText,
                        ),
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: AppColors.stemLightText,
                        ),
                        items: ['trip', 'home', 'food', 'couple', 'game', 'other']
                            .map((c) => DropdownMenuItem(
                                  value: c,
                                  child: Text(c[0].toUpperCase() + c.substring(1)),
                                ))
                            .toList(),
                        onChanged: _isGameModeEntry
                            ? null
                            : (v) => setState(() => _category = v ?? 'trip'),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 23),
                StemFormField(
                  label: 'DEFAULT CURRENCY',
                  child: Container(
                    height: 58,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      color: AppColors.stemFormSurface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFF404944).withValues(alpha: 0.2),
                      ),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _currency,
                        isExpanded: true,
                        dropdownColor: AppColors.stemFormSurface,
                        icon: Icon(Icons.keyboard_arrow_down,
                            color: AppColors.stemMutedText),
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: AppColors.stemLightText,
                        ),
                        items: [
                          DropdownMenuItem(
                              value: 'INR', child: Text('INR (₹)')),
                          DropdownMenuItem(
                              value: 'PKR', child: Text('PKR (Rs)')),
                          DropdownMenuItem(
                              value: 'USD', child: Text('USD (\$)')),
                        ],
                        onChanged: (v) =>
                            setState(() => _currency = v ?? 'INR'),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 23),
                if (_category == 'game') ...[
                  StemFormField(
                    label: 'GAME AMOUNT PER PERSON (REQUIRED)',
                    child: TextFormField(
                      controller: _gameAmountController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: AppColors.stemLightText,
                      ),
                      decoration: InputDecoration(
                        hintText: 'e.g. 100',
                        hintStyle: GoogleFonts.poppins(
                          fontSize: 16,
                          color: AppColors.stemMutedText.withValues(alpha: 0.3),
                        ),
                        filled: true,
                        fillColor: AppColors.stemFormSurface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: const Color(0xFF404944).withValues(alpha: 0.2),
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 21,
                          vertical: 17,
                        ),
                      ),
                      validator: (v) {
                        if (_category != 'game') return null;
                        final n = double.tryParse((v ?? '').trim());
                        if (n == null || n <= 0) {
                          return 'Enter valid game amount';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: 23),
                ],
                StemFormField(
                  label: _category == 'game' ? 'GAME DESCRIPTION' : 'DESCRIPTION',
                  child: TextFormField(
                    controller: _descController,
                    maxLines: 3,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: AppColors.stemLightText,
                    ),
                    decoration: InputDecoration(
                      hintText: _category == 'game'
                          ? 'e.g. Office Friday question challenge'
                          : 'What is this group for?',
                      hintStyle: GoogleFonts.poppins(
                        fontSize: 16,
                        color: AppColors.stemMutedText.withValues(alpha: 0.3),
                      ),
                      filled: true,
                      fillColor: AppColors.stemFormSurface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: const Color(0xFF404944).withValues(alpha: 0.2),
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 21,
                        vertical: 17,
                      ),
                    ),
                  ),
                ),
                if (_category != 'game') ...[
                  const SizedBox(height: 32),
                  Container(
                  padding: const EdgeInsets.all(21),
                  decoration: BoxDecoration(
                    color: AppColors.stemFormSurface,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: const Color(0xFF404944).withValues(alpha: 0.1),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'GEO-FENCE RADIUS',
                            style: GoogleFonts.manrope(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryGreen,
                              letterSpacing: 1.1,
                            ),
                          ),
                          Text(
                            '${_radiusKm.toStringAsFixed(1)}km',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryGreen,
                            ),
                          ),
                        ],
                      ),
                      Slider(
                        value: _radiusKm,
                        min: 0.5,
                        max: 10,
                        divisions: 19,
                        activeColor: AppColors.primaryGreen,
                        onChanged: (v) => setState(() => _radiusKm = v),
                      ),
                      Text(
                        'Automatic expense detection within this radius for\ngroup members.',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: AppColors.stemMutedText
                              .withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'DATES (OPTIONAL)',
                    style: GoogleFonts.manrope(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryGreen,
                      letterSpacing: 1.1,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _StemDateField(
                          label: 'Start Date',
                          date: _tripStartDate,
                          onTap: () => _selectDate(true),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StemDateField(
                          label: 'End Date',
                          date: _tripEndDate,
                          onTap: () => _selectDate(false),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 32),
                BlocBuilder<GroupCubit, GroupState>(
                  builder: (context, state) {
                    return SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: state is GroupLoading ? null : _createGroup,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryGreen,
                          foregroundColor: const Color(0xFF002115),
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: state is GroupLoading
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Color(0xFF002115),
                                ),
                              )
                            : Text(
                                _isGameModeEntry
                                    ? 'Create Game Group'
                                    : 'Create Group',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 32),
                Text(
                  _isGameModeEntry
                      ? 'By creating a game group, you agree to\nthe game terms of service'
                      : 'By creating a group, you agree to the\nledger terms of service',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: AppColors.stemMutedText.withValues(alpha: 0.4),
                    letterSpacing: 2,
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

class _StemDateField extends StatelessWidget {
  final String label;
  final DateTime? date;
  final VoidCallback onTap;

  const _StemDateField({
    required this.label,
    required this.date,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 13),
        decoration: BoxDecoration(
          color: AppColors.stemBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFF404944).withValues(alpha: 0.1),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              date != null
                  ? '${date!.day}/${date!.month}/${date!.year}'
                  : label,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: date != null
                    ? AppColors.stemMutedText
                    : AppColors.stemMutedText.withValues(alpha: 0.6),
              ),
            ),
            Icon(
              Icons.calendar_today_outlined,
              size: 12,
              color: AppColors.stemMutedText,
            ),
          ],
        ),
      ),
    );
  }
}
