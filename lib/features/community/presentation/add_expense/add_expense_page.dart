import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../../../core/services/image_upload_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_fonts.dart';
import '../../../../data/models/expense_model.dart';
import '../../../../data/models/group_model.dart';
import '../../../../application/addExpense/expense_cubit.dart';
import 'split_type.dart';
import 'expense_category.dart';
import 'widgets/adjust_split_sheet.dart';
import 'widgets/category_select_sheet.dart';

class AddExpensePage extends StatefulWidget {
  final String groupId;
  final GroupModel group;
  final ExpenseModel? expense;

  const AddExpensePage({
    Key? key,
    required this.groupId,
    required this.group,
    this.expense,
  }) : super(key: key);

  @override
  State<AddExpensePage> createState() => _AddExpensePageState();
}

class _AddExpensePageState extends State<AddExpensePage> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descController = TextEditingController();
  String _paidBy = '';
  final Set<String> _participants = {};
  SplitType _splitType = SplitType.equally;
  Map<String, double> _customAmounts = {};
  File? _receiptImage;
  String? _imageUrl;
  bool _isUploadingImage = false;
  final _imagePicker = ImagePicker();
  ExpenseCategory? _selectedCategory;
  bool _skipNextDescUpdate = false;

  String get _currencySymbol {
    switch (widget.group.currency) {
      case 'INR':
        return '₹';
      case 'PKR':
        return 'Rs.';
      case 'USD':
        return '\$';
      default:
        return widget.group.currency;
    }
  }

  bool get _isEditMode => widget.expense != null;

  String get _paidByLabel {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    return _paidBy == uid ? 'you' : _paidBy.length > 8 ? '${_paidBy.substring(0, 8)}...' : _paidBy;
  }

  String _displayName(String uid) {
    final currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    return uid == currentUid ? 'you' : uid;
  }

  String get _participantsDisplayText {
    if (_participants.isEmpty) return 'Select people';
    if (_participants.length == widget.group.members.length) {
      return 'All of ${widget.group.name}';
    }
    return _participants.map(_displayName).join(', ');
  }

  bool get _isAllSelected => _participants.length == widget.group.members.length;

  @override
  void initState() {
    super.initState();
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (_isEditMode) {
      final e = widget.expense!;
      _amountController.text = e.amount.toStringAsFixed(2);
      _descController.text = e.description;
      _paidBy = e.paidBy;
      _participants.addAll(e.participants);
      _customAmounts = Map.from(e.customAmounts ?? {});
      _imageUrl = e.imageUrl;
      _updateCategoryFromDescription(e.description);
    } else {
      _paidBy = uid;
      if (uid.isNotEmpty) _participants.addAll(widget.group.members.keys);
    }
    _descController.addListener(_onDescriptionChanged);
  }

  void _onDescriptionChanged() {
    if (_skipNextDescUpdate) {
      _skipNextDescUpdate = false;
      return;
    }
    _updateCategoryFromDescription(_descController.text);
  }

  void _updateCategoryFromDescription(String text) {
    final cat = ExpenseCategories.findFromDescription(text);
    if (mounted && cat != _selectedCategory) {
      setState(() => _selectedCategory = cat);
    }
  }

  void _showCategorySelectSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => CategorySelectSheet(
        isDark: Theme.of(ctx).brightness == Brightness.dark,
        selectedCategory: _selectedCategory,
        onSelect: (cat) {
          _skipNextDescUpdate = true;
          setState(() {
            _selectedCategory = cat;
            _descController.text = cat.name;
            _descController.selection = TextSelection.fromPosition(
              TextPosition(offset: cat.name.length),
            );
          });
        },
      ),
    );
  }

  @override
  void dispose() {
    _descController.removeListener(_onDescriptionChanged);
    _amountController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadReceipt() async {
    try {
      final picked = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );
      if (picked == null || !mounted) return;

      setState(() {
        _receiptImage = File(picked.path);
        _isUploadingImage = true;
      });

      final url = await di.sl<ImageUploadService>().uploadImage(File(picked.path));
      if (mounted) {
        setState(() {
          _imageUrl = url;
          _isUploadingImage = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Receipt uploaded successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploadingImage = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e')),
        );
      }
    }
  }

  void _toggleParticipant(String userId) {
    setState(() {
      if (_participants.contains(userId)) {
        _participants.remove(userId);
      } else {
        _participants.add(userId);
      }
    });
  }

  void _showPaidByPicker() {
    final members = widget.group.members.entries.toList();
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? AppColors.darkCard
          : AppColors.backgroundWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Who paid?',
                style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),
              ...members.map((e) {
                final uid = e.value.userId;
                final isYou = uid == FirebaseAuth.instance.currentUser?.uid;
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.primaryGreen,
                    child: Text(
                      uid.substring(0, 1).toUpperCase(),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  title: Text(isYou ? 'you' : uid),
                  trailing: _paidBy == uid
                      ? const Icon(Icons.check_circle, color: AppColors.primaryGreen)
                      : null,
                  onTap: () {
                    setState(() => _paidBy = uid);
                    Navigator.pop(ctx);
                  },
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  void _showAdjustSplitSheet() {
    final amount = double.tryParse(_amountController.text.trim()) ?? 0;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AdjustSplitSheet(
        amount: amount,
        currencySymbol: _currencySymbol,
        group: widget.group,
        participants: Set.from(_participants),
        splitType: _splitType,
        customAmounts: Map.from(_customAmounts),
        isDark: Theme.of(ctx).brightness == Brightness.dark,
        onSave: (splitType, participants, customAmounts) {
          setState(() {
            _splitType = splitType;
            _participants.clear();
            _participants.addAll(participants);
            _customAmounts = customAmounts;
          });
          Navigator.pop(ctx);
        },
      ),
    );
  }

  void _showParticipantPicker() {
    final members = widget.group.members.entries.toList();
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? AppColors.darkCard
          : AppColors.backgroundWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Split between',
                  style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 16),
                ...members.map((e) {
                  final uid = e.value.userId;
                  final isYou = uid == FirebaseAuth.instance.currentUser?.uid;
                  final selected = _participants.contains(uid);
                  return CheckboxListTile(
                    value: selected,
                    onChanged: (_) {
                      setState(() => _toggleParticipant(uid));
                      setModalState(() {});
                    },
                    title: Text(isYou ? 'you' : uid),
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleSubmit() {
    if (!_formKey.currentState!.validate()) return;
    if (_participants.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select at least one participant')),
      );
      return;
    }

    final amount = double.tryParse(_amountController.text.trim()) ?? 0;
    if (amount <= 0) return;

    final cubit = context.read<ExpenseCubit>();
    if (_isEditMode) {
      final e = widget.expense!;
      cubit.updateExpense(widget.groupId, e.id, e.copyWith(
        amount: amount,
        description: _descController.text.trim(),
        paidBy: _paidBy,
        participants: _participants.toList(),
        customAmounts: _customAmounts.isEmpty ? null : _customAmounts,
        imageUrl: _imageUrl,
      ));
    } else {
      cubit.addExpense(ExpenseModel(
        id: '',
        groupId: widget.groupId,
        amount: amount,
        currency: widget.group.currency,
        description: _descController.text.trim(),
        paidBy: _paidBy,
        participants: _participants.toList(),
        createdBy: FirebaseAuth.instance.currentUser?.uid ?? '',
        createdAt: DateTime.now(),
        customAmounts: _customAmounts.isEmpty ? null : _customAmounts,
        imageUrl: _imageUrl,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return BlocListener<ExpenseCubit, ExpenseState>(
      listener: (context, state) {
        if (state is ExpenseAdded) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Expense added!')),
          );
          context.pop();
        }
        if (state is ExpenseUpdated) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Expense updated!')),
          );
          context.pop();
        }
        if (state is ExpenseError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        }
      },
      child: Scaffold(
        backgroundColor: isDark ? AppColors.darkBackground : AppColors.backgroundWhite,
        appBar: AppBar(
          title: Text(_isEditMode ? 'Edit expense' : 'Add expense'),
          actions: [
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: _handleSubmit,
            ),
          ],
        ),
        body: SafeArea(
          child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimensions.padding20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'With you and:',
                  style: TextStyle(
                    fontSize: AppFonts.fontSize14,
                    color: AppColors.textGrey,
                  ),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: _showParticipantPicker,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurface : AppColors.backgroundGrey,
                      borderRadius: BorderRadius.circular(AppDimensions.radius12),
                      border: Border(
                        bottom: BorderSide(
                          color: isDark ? AppColors.textGrey : AppColors.borderGrey,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _isAllSelected ? Icons.home : Icons.mail_outline,
                          color: _isAllSelected ? AppColors.primaryGreen : AppColors.textGrey,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _participantsDisplayText,
                            style: TextStyle(
                              fontSize: AppFonts.fontSize16,
                              fontWeight: FontWeight.w500,
                              color: isDark ? AppColors.textWhite : AppColors.textBlack,
                            ),
                          ),
                        ),
                        Icon(
                          Icons.keyboard_arrow_down,
                          size: 20,
                          color: AppColors.textGrey,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                Row(
                  children: [
                    GestureDetector(
                      onTap: _showCategorySelectSheet,
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: _selectedCategory?.iconBgColor ??
                              (isDark ? AppColors.darkSurface : AppColors.backgroundGrey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          _selectedCategory?.icon ?? Icons.receipt_long_outlined,
                          size: 24,
                          color: isDark ? AppColors.textWhite : AppColors.textBlack,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _descController,
                        decoration: InputDecoration(
                          hintText: 'Enter a description',
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
                            (v == null || v.trim().isEmpty) ? 'Enter description' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Text(
                      _currencySymbol,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w500,
                        color: isDark ? AppColors.textWhite : AppColors.textBlack,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _amountController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          hintText: '0.00',
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
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Enter amount';
                          final amt = double.tryParse(v);
                          if (amt == null || amt <= 0) return 'Enter valid amount';
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                if (_imageUrl != null || _receiptImage != null) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(AppDimensions.radius12),
                        child: _imageUrl != null
                            ? CachedNetworkImage(
                                imageUrl: _imageUrl!,
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                              )
                            : _receiptImage != null
                                ? Image.file(
                                    _receiptImage!,
                                    width: 80,
                                    height: 80,
                                    fit: BoxFit.cover,
                                  )
                                : const SizedBox.shrink(),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Receipt attached',
                          style: TextStyle(
                            fontSize: AppFonts.fontSize14,
                            color: AppColors.primaryGreen,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: AppColors.error),
                        onPressed: () {
                          setState(() {
                            _receiptImage = null;
                            _imageUrl = null;
                          });
                        },
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 32),
                Row(
                  children: [
                    Text(
                      'Paid by ',
                      style: TextStyle(
                        fontSize: AppFonts.fontSize14,
                        color: AppColors.textGrey,
                      ),
                    ),
                    GestureDetector(
                      onTap: _showPaidByPicker,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkSurface : AppColors.backgroundGrey,
                          borderRadius: BorderRadius.circular(AppDimensions.radius20),
                        ),
                        child: Text(
                          _paidByLabel,
                          style: TextStyle(
                            fontSize: AppFonts.fontSize14,
                            fontWeight: FontWeight.w500,
                            color: isDark ? AppColors.textWhite : AppColors.textBlack,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text(
                      'and split ',
                      style: TextStyle(
                        fontSize: AppFonts.fontSize14,
                        color: AppColors.textGrey,
                      ),
                    ),
                    GestureDetector(
                      onTap: _showAdjustSplitSheet,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkSurface : AppColors.backgroundGrey,
                          borderRadius: BorderRadius.circular(AppDimensions.radius20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _splitType.label,
                              style: TextStyle(
                                fontSize: AppFonts.fontSize14,
                                fontWeight: FontWeight.w500,
                                color: isDark ? AppColors.textWhite : AppColors.textBlack,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.keyboard_arrow_down,
                              size: 20,
                              color: isDark ? AppColors.textGrey : AppColors.textBlack,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 40),
                // Bottom bar: Group name + Calendar, Camera, Note
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.accentOrange.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.group,
                            color: AppColors.accentOrange,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          widget.group.name,
                          style: TextStyle(
                            fontSize: AppFonts.fontSize14,
                            fontWeight: FontWeight.w500,
                            color: isDark ? AppColors.textWhite : AppColors.textBlack,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        _buildBottomIconButton(
                          icon: Icons.calendar_today_outlined,
                          color: const Color(0xFF5AC8FA),
                          onTap: () {
                            // TODO: Add expense date
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Date picker coming soon')),
                            );
                          },
                        ),
                        const SizedBox(width: 12),
                        _buildBottomIconButton(
                          icon: _isUploadingImage
                              ? Icons.hourglass_empty
                              : Icons.camera_alt_outlined,
                          color: const Color(0xFFAF52DE),
                          onTap: _isUploadingImage ? () {} : _pickAndUploadReceipt,
                        ),
                        const SizedBox(width: 12),
                        _buildBottomIconButton(
                          icon: Icons.edit_note,
                          color: AppColors.primaryGreen,
                          onTap: () {
                            // TODO: Add note
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Note coming soon')),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        ),
      ),
    );
  }

  Widget _buildBottomIconButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return IconButton(
      onPressed: onTap,
      icon: Icon(icon, color: color, size: 24),
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
    );
  }
}
