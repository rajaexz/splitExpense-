import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../../core/constants/app_colors.dart';
import '../../../../../../data/models/group_model.dart';

/// STEM design: Members card with balance per member, "View all" button.
class StemMembersCard extends StatefulWidget {
  final GroupModel group;
  final String currentUserId;
  final Map<String, double> balances;
  final String currency;

  const StemMembersCard({
    super.key,
    required this.group,
    required this.currentUserId,
    required this.balances,
    required this.currency,
  });

  @override
  State<StemMembersCard> createState() => _StemMembersCardState();
}

class _StemMembersCardState extends State<StemMembersCard> {
  bool _expanded = false;

  String _displayName(String userId) {
    if (userId == widget.currentUserId) return 'You';
    return userId.length > 8 ? '${userId.substring(0, 8)}...' : userId;
  }

  @override
  Widget build(BuildContext context) {
    final entries = widget.group.members.entries.toList();
    final overflowCount = entries.length > 2 ? entries.length - 2 : 0;

    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: AppColors.stemCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFF404944).withValues(alpha: 0.05),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Members (${widget.group.memberCount})',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.stemLightText,
                ),
              ),
              GestureDetector(
                onTap: () => setState(() => _expanded = !_expanded),
                child: Text(
                  'View all',
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.stemEmerald,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          ...List.generate(
            _expanded ? entries.length : entries.length.clamp(0, 2),
            (i) {
              if (i >= entries.length) return const SizedBox.shrink();
              final e = entries[i];
              final member = e.value;
              final balance = widget.balances[e.key] ?? 0;
              final isCurrentUser = e.key == widget.currentUserId;

              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: AppColors.stemSurface,
                          child: Text(
                            _displayName(e.key).substring(0, 1).toUpperCase(),
                            style: GoogleFonts.manrope(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.stemLightText,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _displayName(e.key),
                              style: GoogleFonts.manrope(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.stemLightText,
                              ),
                            ),
                            Text(
                              member.role.toUpperCase(),
                              style: GoogleFonts.manrope(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: isCurrentUser
                                    ? AppColors.stemEmerald
                                    : AppColors.stemMutedText,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Text(
                      '${balance >= 0 ? '+' : ''}${widget.currency}${balance.abs().toStringAsFixed(0)}',
                      style: GoogleFonts.manrope(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: balance >= 0
                            ? AppColors.stemEmerald
                            : AppColors.stemOweColor,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          if (overflowCount > 0 && !_expanded && entries.length > 2) ...[
            const SizedBox(height: 8),
            _OverflowAvatars(
              entries: entries,
              startIndex: 2,
              displayName: _displayName,
            ),
          ],
        ],
      ),
    );
  }
}

class _OverflowAvatars extends StatelessWidget {
  final List<MapEntry<String, GroupMember>> entries;
  final int startIndex;
  final String Function(String) displayName;

  const _OverflowAvatars({
    required this.entries,
    required this.startIndex,
    required this.displayName,
  });

  @override
  Widget build(BuildContext context) {
    final rest = entries.length - startIndex;
    final showPlusN = rest > 2;
    final plusN = rest > 2 ? rest - 2 : 0;

    return Row(
      children: [
        if (rest > 0)
          _AvatarChip(
            label: displayName(entries[startIndex].key),
            color: AppColors.stemInactive,
          ),
        if (rest > 1)
          Transform.translate(
            offset: const Offset(-8, 0),
            child: _AvatarChip(
              label: showPlusN ? '+$plusN' : displayName(entries[startIndex + 1].key),
              color: showPlusN
                  ? AppColors.stemEmerald.withValues(alpha: 0.2)
                  : AppColors.stemInactive,
              isPlus: showPlusN,
            ),
          ),
      ],
    );
  }
}

class _AvatarChip extends StatelessWidget {
  final String label;
  final Color color;
  final bool isPlus;

  const _AvatarChip({
    required this.label,
    required this.color,
    this.isPlus = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: color,
        border: Border.all(color: AppColors.stemBackground, width: 2),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        isPlus ? label : label.substring(0, 1).toUpperCase(),
        style: GoogleFonts.manrope(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: isPlus ? AppColors.stemEmerald : AppColors.stemLightText,
        ),
      ),
    );
  }
}
