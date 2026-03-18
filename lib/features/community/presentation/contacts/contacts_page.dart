import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_routes.dart';
import 'widgets/contacts_widgets.dart';

/// Friends/Contacts page - Splitwise-style empty state by default.
/// Friends and group mates will show here as user uses the app.
class ContactsPage extends StatelessWidget {
  const ContactsPage({Key? key}) : super(key: key);

  String _getUserName() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return '';
    return user.displayName?.trim().isNotEmpty == true
        ? user.displayName!
        : user.email?.split('@').first ?? 'there';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final userName = _getUserName();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Friends'),
        foregroundColor: isDark ? AppColors.textWhite : AppColors.textBlack,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Search will be available when you have friends')),
              );
            },
            tooltip: 'Search',
          ),
          IconButton(
            icon: const Icon(Icons.person_add_outlined),
            onPressed: () => context.push(AppRoutes.addMemberFromContacts),
            tooltip: 'Add friend',
          ),
        ],
      ),
      body: SafeArea(
        child: EmptyContactsState(isDark: isDark, userName: userName),
      ),
    );
  }
}
