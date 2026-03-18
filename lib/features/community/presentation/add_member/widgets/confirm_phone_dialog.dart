import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_dimensions.dart';

class ConfirmPhoneDialog extends StatefulWidget {
  final String countryCode;
  final String initialPhone;
  final void Function(String) onConfirm;
  final VoidCallback onCancel;

  const ConfirmPhoneDialog({
    super.key,
    required this.countryCode,
    required this.initialPhone,
    required this.onConfirm,
    required this.onCancel,
  });

  @override
  State<ConfirmPhoneDialog> createState() => _ConfirmPhoneDialogState();
}

class _ConfirmPhoneDialogState extends State<ConfirmPhoneDialog> {
  late TextEditingController _phoneController;

  @override
  void initState() {
    super.initState();
    _phoneController = TextEditingController(text: widget.initialPhone);
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AlertDialog(
      title: const Text('Confirm phone number'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : AppColors.backgroundGrey,
                  borderRadius:
                      BorderRadius.circular(AppDimensions.radius12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('🇮🇳 ', style: TextStyle(fontSize: 20)),
                    Text(
                      widget.countryCode,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.textWhite : AppColors.textBlack,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    hintText: 'Phone number',
                    border: UnderlineInputBorder(
                      borderSide: BorderSide(color: AppColors.primaryGreen),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(
                        color: AppColors.primaryGreen,
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: widget.onCancel,
          child: Text(
            'Cancel',
            style: TextStyle(color: AppColors.primaryGreen),
          ),
        ),
        TextButton(
          onPressed: () {
            final phone = _phoneController.text.trim();
            final full = phone.startsWith('+')
                ? phone
                : '${widget.countryCode}$phone';
            widget.onConfirm(full);
          },
          child: Text(
            'Continue',
            style: TextStyle(color: AppColors.primaryGreen),
          ),
        ),
      ],
    );
  }
}
