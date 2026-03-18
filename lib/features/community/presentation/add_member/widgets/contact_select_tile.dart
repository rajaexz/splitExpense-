import 'package:contacts_service_plus/contacts_service_plus.dart';
import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';

class ContactSelectTile extends StatelessWidget {
  final Contact contact;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  const ContactSelectTile({
    super.key,
    required this.contact,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final name =
        contact.displayName ?? contact.givenName ?? contact.familyName ?? 'Unknown';
    final phone = contact.phones?.isNotEmpty == true
        ? (contact.phones!.first.value ?? '')
        : '';

    return ListTile(
      leading: const Icon(Icons.phone, color: AppColors.textGrey),
      title: Text(
        name,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          color: isDark ? AppColors.textWhite : AppColors.textBlack,
        ),
      ),
      subtitle: Text(
        phone,
        style: const TextStyle(fontSize: 12, color: AppColors.textGrey),
      ),
      trailing: Icon(
        isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
        color: isSelected ? AppColors.primaryGreen : AppColors.textGrey,
      ),
      onTap: onTap,
    );
  }
}
