import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../../../core/constants/app_colors.dart';
import '../../../../../../core/constants/app_dimensions.dart';
import '../../../../../../core/constants/app_fonts.dart';
import '../../../../../../core/di/injection_container.dart' as di;
import '../../../../../../domain/auth_repository.dart';
import '../../../../../../data/models/group_model.dart';
import '../../payment/widgets/qr_card.dart';

class SettleUpSheet extends StatefulWidget {
  final String groupId;
  final GroupModel group;
  final List<Map<String, dynamic>> membersWhoOwe; // { userId, amount }

  const SettleUpSheet({
    super.key,
    required this.groupId,
    required this.group,
    required this.membersWhoOwe,
  });

  static Future<void> show({
    required BuildContext context,
    required String groupId,
    required GroupModel group,
    required List<Map<String, dynamic>> membersWhoOwe,
  }) {
    if (membersWhoOwe.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nothing to settle.')),
      );
      return Future.value();
    }

    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: false,
      backgroundColor: AppColors.stemBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SettleUpSheet(
          groupId: groupId,
          group: group,
          membersWhoOwe: membersWhoOwe,
        );
      },
    );
  }

  @override
  State<SettleUpSheet> createState() => _SettleUpSheetState();
}

class _SettleUpSheetState extends State<SettleUpSheet> {
  PaymentMethod _selectedMethod = PaymentMethod.upiQr;
  bool _isGeneratingQr = false;
  bool _isConfirming = false;
  bool _hasGeneratedQr = false;

  late final double _totalOutstanding;
  late final int _splitCount;

  @override
  void initState() {
    super.initState();
    _totalOutstanding = widget.membersWhoOwe.fold<double>(
      0,
      (sum, e) => sum + ((e['amount'] as num?)?.toDouble() ?? 0.0),
    );
    _splitCount = widget.membersWhoOwe.length;
  }

  String _currencyCode() {
    switch (widget.group.currency) {
      case 'PKR':
        return 'PKR';
      case 'USD':
        return 'USD';
      case 'INR':
      default:
        return 'INR';
    }
  }

  String _currencySymbol() {
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

  Future<String> _resolveUserName(String userId) async {
    try {
      final doc =
          await FirebaseFirestore.instance.collection('users').doc(userId).get();
      final data = doc.data();
      return (data?['name'] ?? data?['displayName'] ?? data?['email'] ?? userId);
    } catch (_) {
      return userId;
    }
  }

  Future<String?> _resolveUserUpiId(String userId) async {
    try {
      return await di.sl<AuthRepository>().getUpiId(userId);
    } catch (_) {
      return null;
    }
  }

  Future<String> _buildUpiUri({
    required String receiverUpi,
    required String receiverName,
    required double amount,
  }) async {
    final pa = Uri.encodeComponent(receiverUpi.trim());
    final pn = Uri.encodeComponent(receiverName.trim());
    final am = amount.toStringAsFixed(2);
    final cu = _currencyCode();
    final tn = Uri.encodeComponent('Settlement: ${widget.group.name}');
    return 'upi://pay?pa=$pa&pn=$pn&am=$am&cu=$cu&tn=$tn';
  }

  Future<void> _onGenerateQr() async {
    if (_isGeneratingQr) return;
    setState(() => _isGeneratingQr = true);
    setState(() => _hasGeneratedQr = false);

    try {
      if (_selectedMethod != PaymentMethod.upiQr) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('This payment method is not implemented yet.')),
        );
        return;
      }

      final targets = <_SettleTarget>[];
      for (final m in widget.membersWhoOwe) {
        final userId = m['userId'] as String?;
        final amount = (m['amount'] as num?)?.toDouble() ?? 0.0;
        if (userId == null || userId.isEmpty || amount <= 0) continue;

        final name = await _resolveUserName(userId);
        final upiId = await _resolveUserUpiId(userId);
        if (upiId == null || upiId.trim().isEmpty) continue;

        targets.add(_SettleTarget(
          userId: userId,
          name: name,
          amount: amount,
          receiverUpiId: upiId,
        ));
      }

      if (targets.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('UPI IDs missing for settlement members.')),
        );
        return;
      }

      if (!context.mounted) return;

      if (mounted) setState(() => _hasGeneratedQr = true);
      await showDialog<void>(
        context: context,
        builder: (ctx) {
          return AlertDialog(
            backgroundColor: AppColors.stemBackground,
            title: Text(
              'Payment QR (${targets.length} split)',
              style: GoogleFonts.manrope(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.stemLightText,
              ),
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    for (final t in targets) ...[
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            'Pay ${t.name} (${_currencySymbol()}${t.amount.toStringAsFixed(0)})',
                            style: GoogleFonts.manrope(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.stemMutedText,
                            ),
                          ),
                        ),
                      ),
                      FutureBuilder<String>(
                        future: _buildUpiUri(
                          receiverUpi: t.receiverUpiId,
                          receiverName: t.name,
                          amount: t.amount,
                        ),
                        builder: (context, snap) {
                          if (!snap.hasData) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              child: Center(
                                child: CircularProgressIndicator(),
                              ),
                            );
                          }
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: QrCard(
                              data: snap.data!,
                              size: 220,
                            ),
                          );
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(
                  'Done',
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.stemEmerald,
                  ),
                ),
              ),
            ],
          );
        },
      );
    } finally {
      if (mounted) setState(() => _isGeneratingQr = false);
    }
  }

  Future<List<_SettleTarget>> _buildTargetsForSelectedMethod() async {
    if (_selectedMethod != PaymentMethod.upiQr) return <_SettleTarget>[];

    final targets = <_SettleTarget>[];
    for (final m in widget.membersWhoOwe) {
      final userId = m['userId'] as String?;
      final amount = (m['amount'] as num?)?.toDouble() ?? 0.0;
      if (userId == null || userId.isEmpty || amount <= 0) continue;

      final name = await _resolveUserName(userId);
      final upiId = await _resolveUserUpiId(userId);
      if (upiId == null || upiId.trim().isEmpty) continue;

      targets.add(
        _SettleTarget(
          userId: userId,
          name: name,
          amount: amount,
          receiverUpiId: upiId,
        ),
      );
    }
    return targets;
  }

  void _onConfirmSettlement() {
    if (_isConfirming) return;
    setState(() => _isConfirming = true);

    () async {
      try {
        if (_selectedMethod != PaymentMethod.upiQr) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Only UPI QR settlement is implemented yet.')),
          );
          return;
        }

        if (_selectedMethod == PaymentMethod.upiQr && !_hasGeneratedQr) {
          await _onGenerateQr();
        }

        final userId = FirebaseAuth.instance.currentUser?.uid;
        if (userId == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please login first.')),
          );
          return;
        }

        final targets = await _buildTargetsForSelectedMethod();
        if (targets.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No valid UPI IDs found for settlement members.')),
          );
          return;
        }

        final settlementData = <String, dynamic>{
          'createdBy': userId,
          'createdAt': FieldValue.serverTimestamp(),
          'groupId': widget.groupId,
          'groupName': widget.group.name,
          'currency': widget.group.currency,
          'selectedMethod': 'upi_qr',
          'totalOutstanding': _totalOutstanding,
          'membersWhoOwe': widget.membersWhoOwe,
          'targets': targets.map((t) => {
                'userId': t.userId,
                'name': t.name,
                'amount': t.amount,
                'receiverUpiId': t.receiverUpiId,
              }).toList(),
        };

        await FirebaseFirestore.instance
            .collection('groups')
            .doc(widget.groupId)
            .collection('settlements')
            .add(settlementData);

        if (!context.mounted) return;
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Settlement confirmed and saved.')),
        );
      } catch (e) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to confirm settlement: $e')),
        );
      } finally {
        if (mounted) {
          setState(() => _isConfirming = false);
        }
      }
    }();
  }

  @override
  Widget build(BuildContext context) {
    final outstandingText =
        '${_currencySymbol()}${_totalOutstanding.toStringAsFixed(2)}';

    return SafeArea(
      left: false,
      right: false,
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.92,
        child: Column(
          children: [
            _SheetTopBar(
              groupName: widget.group.name,
              onBack: () => Navigator.pop(context),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 120),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TOTAL OUTSTANDING',
                      style: GoogleFonts.manrope(
                        fontSize: AppFonts.fontSize12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                        color: AppColors.stemMutedText,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${_currencySymbol()}${_totalOutstanding.toStringAsFixed(2)}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 44,
                        fontWeight: FontWeight.w800,
                        color: AppColors.stemLightText,
                        letterSpacing: -1.8,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _InfoPill(
                      icon: Icons.groups_outlined,
                      text: 'Split with $_splitCount group members',
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'BREAKDOWN',
                      style: GoogleFonts.manrope(
                        fontSize: AppFonts.fontSize12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                        color: AppColors.stemMutedText,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _BreakdownList(
                      currencySymbol: _currencySymbol(),
                      membersWhoOwe: widget.membersWhoOwe,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'SELECT PAYMENT METHOD',
                      style: GoogleFonts.manrope(
                        fontSize: AppFonts.fontSize12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                        color: AppColors.stemMutedText,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _PaymentMethodList(
                      selected: _selectedMethod,
                      onChanged: (v) => setState(() => _selectedMethod = v),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        final txt =
                            'Settlement for ${widget.group.name}. Total outstanding: $outstandingText. You owe ${widget.membersWhoOwe.length} member(s).';
                        Share.share(txt);
                      },
                      icon: const Icon(Icons.share_outlined,
                          color: AppColors.stemEmerald),
                      label: Text(
                        'Share Settlement Details',
                        style: GoogleFonts.manrope(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.stemEmerald,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.stemEmerald),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppDimensions.radius16),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _onGenerateQr,
                      icon: const Icon(Icons.qr_code_2_outlined,
                          color: AppColors.stemLightText),
                      label: Text(
                        _isGeneratingQr
                            ? 'Generating...'
                            : 'Generate Payment QR',
                        style: GoogleFonts.manrope(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.stemLightText,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.darkCard,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppDimensions.radius16),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                    onPressed: _isConfirming ? null : _onConfirmSettlement,
                      child: Text(
                      _isConfirming ? 'Confirming...' : 'Confirm Settlement  >>',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF003B29),
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryGreen,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppDimensions.radius16),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettleTarget {
  final String userId;
  final String name;
  final double amount;
  final String receiverUpiId;

  _SettleTarget({
    required this.userId,
    required this.name,
    required this.amount,
    required this.receiverUpiId,
  });
}

enum PaymentMethod { upiQr, bankTransfer, cashManual }

class _SheetTopBar extends StatelessWidget {
  final String groupName;
  final VoidCallback onBack;

  const _SheetTopBar({
    required this.groupName,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.65),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_ios_new,
                color: AppColors.stemLightText),
          ),
          Text(
            'Settle Up',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.stemEmerald,
            ),
          ),
          const Spacer(),
          Text(
            groupName,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.stemMutedText,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoPill({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.darkCard.withOpacity(0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.stemEmerald.withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.stemEmerald),
          const SizedBox(width: 8),
          Text(
            text,
            style: GoogleFonts.manrope(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.stemMutedText,
            ),
          ),
        ],
      ),
    );
  }
}

class _BreakdownList extends StatelessWidget {
  final String currencySymbol;
  final List<Map<String, dynamic>> membersWhoOwe;

  const _BreakdownList({
    required this.currencySymbol,
    required this.membersWhoOwe,
  });

  Future<String> _resolveName(String userId) async {
    try {
      final doc =
          await FirebaseFirestore.instance.collection('users').doc(userId).get();
      final data = doc.data();
      return (data?['name'] ?? data?['displayName'] ?? data?['email'] ?? userId);
    } catch (_) {
      return userId;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (membersWhoOwe.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: membersWhoOwe.map((m) {
        final userId = m['userId'] as String;
        final amount = (m['amount'] as num).toDouble();
        return FutureBuilder<String>(
          future: _resolveName(userId),
          builder: (context, snap) {
            final name = snap.data ?? userId;
            final subtitle = 'YOU OWE';
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.darkCard.withOpacity(0.55),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.borderGreyDark.withValues(alpha: 0.1),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.stemInactive,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.account_balance_wallet_outlined,
                        size: 18, color: AppColors.stemEmerald),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          subtitle,
                          style: GoogleFonts.manrope(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                            color: AppColors.stemMutedText,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          name,
                          style: GoogleFonts.manrope(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.stemLightText,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${currencySymbol}${amount.toStringAsFixed(2)}',
                    style: GoogleFonts.manrope(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.stemOweColor,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      }).toList(),
    );
  }
}

class _PaymentMethodList extends StatelessWidget {
  final PaymentMethod selected;
  final ValueChanged<PaymentMethod> onChanged;

  const _PaymentMethodList({
    required this.selected,
    required this.onChanged,
  });

  Widget _methodTile({
    required PaymentMethod method,
    required IconData icon,
    required String title,
    required String subtitle,
    required bool recommended,
  }) {
    final isSelected = selected == method;

    return InkWell(
      onTap: () => onChanged(method),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.darkCard.withOpacity(isSelected ? 0.7 : 0.45),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? AppColors.stemEmerald.withValues(alpha: 0.6)
                : AppColors.borderGreyDark.withValues(alpha: 0.12),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.stemInactive,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon,
                  size: 22,
                  color: isSelected ? AppColors.stemEmerald : AppColors.stemMutedText),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.manrope(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.stemLightText,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.manrope(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.3,
                      color: AppColors.stemMutedText,
                    ),
                  ),
                ],
              ),
            ),
            if (recommended)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.stemEmerald.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'Recommended',
                  style: GoogleFonts.manrope(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.stemEmerald,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _methodTile(
          method: PaymentMethod.upiQr,
          icon: Icons.qr_code_2_outlined,
          title: 'UPI QR (Recommended)',
          subtitle: 'Instant via PhonePe, GPay',
          recommended: true,
        ),
        _methodTile(
          method: PaymentMethod.bankTransfer,
          icon: Icons.account_balance_outlined,
          title: 'Bank Transfer',
          subtitle: 'NEFT, IMPS or RTGS',
          recommended: false,
        ),
        _methodTile(
          method: PaymentMethod.cashManual,
          icon: Icons.money_outlined,
          title: 'Cash / Manual',
          subtitle: 'Physical cash handover',
          recommended: false,
        ),
      ],
    );
  }
}

