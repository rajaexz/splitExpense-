import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../data/models/group_model.dart';
import '../split_type.dart';

class EquallyTab extends StatelessWidget {
  final List<MapEntry<String, GroupMember>> members;
  final Set<String> selectedParticipants;
  final bool isDark;
  final ValueChanged<String> onToggleParticipant;

  const EquallyTab({
    Key? key,
    required this.members,
    required this.selectedParticipants,
    required this.isDark,
    required this.onToggleParticipant,
  }) : super(key: key);

  String _displayName(String uid) {
    return uid == (FirebaseAuth.instance.currentUser?.uid ?? '') ? 'you' : uid;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          SplitType.equally.title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.textWhite : AppColors.textBlack,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          SplitType.equally.description,
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textGrey,
          ),
        ),
        const SizedBox(height: 24),
        ...members.map((e) {
          final uid = e.key;
          final selected = selectedParticipants.contains(uid);
          return ListTile(
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(
              backgroundColor: AppColors.primaryGreen.withValues(alpha: 0.3),
              child: Text(
                _displayName(uid).substring(0, 1).toUpperCase(),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              ),
            ),
            title: Text(
              _displayName(uid),
              style: TextStyle(
                color: isDark ? AppColors.textWhite : AppColors.textBlack,
              ),
            ),
            trailing: Checkbox(
              value: selected,
              onChanged: (_) => onToggleParticipant(uid),
              activeColor: AppColors.primaryGreen,
            ),
          );
        }),
      ],
    );
  }
}
