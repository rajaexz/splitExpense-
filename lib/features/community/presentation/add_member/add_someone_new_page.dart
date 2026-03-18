import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../../../core/utils/phone_validator.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../data/datasources/saved_contacts_datasource.dart';
import 'selected_member_model.dart';
import 'widgets/confirm_phone_dialog.dart';

class AddSomeoneNewPage extends StatefulWidget {
  final String? initialName;
  final String? initialPhone;

  const AddSomeoneNewPage({
    super.key,
    this.initialName,
    this.initialPhone,
  });

  @override
  State<AddSomeoneNewPage> createState() => _AddSomeoneNewPageState();
}

class _AddSomeoneNewPageState extends State<AddSomeoneNewPage> {
  final _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String _countryCode = '+91';
  String _initialPhone = '';

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.initialName ?? '';
    if (widget.initialPhone != null) {
      final p = widget.initialPhone!;
      if (p.startsWith('+91')) {
        _countryCode = '+91';
        _initialPhone = p.replaceFirst('+91', '').trim();
      } else if (p.startsWith('+92')) {
        _countryCode = '+92';
        _initialPhone = p.replaceFirst('+92', '').trim();
      } else {
        _initialPhone = p.replaceAll(RegExp(r'[\s\-\(\)]'), '');
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _showConfirmPhoneDialog() {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a name')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => ConfirmPhoneDialog(
        countryCode: _countryCode,
        initialPhone: _initialPhone,
        onConfirm: (finalPhone) async {
          Navigator.pop(ctx);
          final error = PhoneValidator.validatePhone(finalPhone);
          if (error != null) {
            showDialog(
              context: context,
              builder: (errCtx) => AlertDialog(
                title: const Text('Error'),
                content: SingleChildScrollView(
                  child: Text(error),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(errCtx),
                    child: Text(
                      'OK',
                      style: TextStyle(color: AppColors.primaryGreen),
                    ),
                  ),
                ],
              ),
            );
            return;
          }
          final phone = finalPhone.startsWith('+')
              ? finalPhone
              : '$_countryCode$finalPhone';
          final member = SelectedMember(name: name, phone: phone);

          // Save contact to user's saved contacts
          try {
            await di.sl<SavedContactsDataSource>().saveContact(name, phone);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Contact saved')),
              );
            }
          } catch (_) {
            // Non-fatal: contact still added to selection
          }

          if (context.mounted) {
            context.pop(member);
          }
        },
        onCancel: () => Navigator.pop(ctx),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.backgroundWhite,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: const Text('Add friend'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _showConfirmPhoneDialog,
          ),
        ],
        backgroundColor: isDark ? AppColors.darkCard : AppColors.backgroundWhite,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.padding16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: AppDimensions.margin24),
                AppTextField(
                  label: 'Name',
                  hint: 'Enter name',
                  controller: _nameController,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Enter name' : null,
                ),
                const SizedBox(height: AppDimensions.margin24),
                ElevatedButton(
                  onPressed: _showConfirmPhoneDialog,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    foregroundColor: AppColors.textWhite,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppDimensions.radius12),
                    ),
                  ),
                  child: const Text('Next'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
