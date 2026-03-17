import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../data/models/group_model.dart';
import '../split_type.dart';

class ByPercentageTab extends StatelessWidget {
  final List<MapEntry<String, GroupMember>> members;
  final Set<String> selectedParticipants;
  final Map<String, double> amounts;
  final Map<String, TextEditingController> controllers;
  final String currencySymbol;
  final bool isDark;
  final ValueChanged<String> onAmountChanged;

  const ByPercentageTab({
    Key? key,
    required this.members,
    required this.selectedParticipants,
    required this.amounts,
    required this.controllers,
    required this.currencySymbol,
    required this.isDark,
    required this.onAmountChanged,
  }) : super(key: key);

  String _displayName(String uid) {
    return uid == (FirebaseAuth.instance.currentUser?.uid ?? '') ? 'you' : uid;
  }

  @override
  Widget build(BuildContext context) {
    final list = members.where((e) => selectedParticipants.contains(e.key)).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          SplitType.byPercentage.title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.textWhite : AppColors.textBlack,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          SplitType.byPercentage.description,
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textGrey,
          ),
        ),
        const SizedBox(height: 24),
        ...list.map((e) => _buildParticipantRow(e.key)),
      ],
    );
  }

  Widget _buildParticipantRow(String uid) {
    final controller = controllers[uid]!;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.primaryGreen.withValues(alpha: 0.3),
            child: Text(
              _displayName(uid).substring(0, 1).toUpperCase(),
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _displayName(uid),
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: isDark ? AppColors.textWhite : AppColors.textBlack,
                  ),
                ),
                Text(
                  '$currencySymbol${(amounts[uid] ?? 0).toStringAsFixed(2)}',
                  style: TextStyle(fontSize: 12, color: AppColors.textGrey),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 100,
            child: TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              onChanged: (v) => onAmountChanged(uid),
              decoration: InputDecoration(
                hintText: '0.00',
                suffixText: '%',
                isDense: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
