import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_fonts.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../../../domain/auth_repository.dart';
import '../../data/datasources/notification_remote_datasource.dart';
import '../../../../core/widgets/error_state_with_action.dart';
import 'widgets/payment_widgets.dart';

/// Shows a UPI QR code for direct payment. Payer scans with GPay/PhonePe etc.
/// Also shows list of members who owe money with select/deselect and notify.
class RequestPaymentQrPage extends StatefulWidget {
  final double amount;
  final String currency;
  final String? groupName;
  final String? groupId;
  final List<Map<String, dynamic>> membersWhoOwe;

  const RequestPaymentQrPage({
    super.key,
    required this.amount,
    required this.currency,
    this.groupName,
    this.groupId,
    this.membersWhoOwe = const [],
  });

  @override
  State<RequestPaymentQrPage> createState() => _RequestPaymentQrPageState();
}

class _MemberOwe {
  final String userId;
  final double amount;
  String name;
  bool selected;

  _MemberOwe({required this.userId, required this.amount})
      : name = 'User',
        selected = true;
}

class _RequestPaymentQrPageState extends State<RequestPaymentQrPage> {
  String? _upiId;
  String? _userName;
  bool _isLoading = true;
  String? _error;
  List<_MemberOwe> _members = [];
  bool _isSendingNotification = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      setState(() {
        _error = 'Please login first';
        _isLoading = false;
      });
      return;
    }

    try {
      final upiId = await di.sl<AuthRepository>().getUpiId(uid);
      final userName = FirebaseAuth.instance.currentUser?.displayName ??
          FirebaseAuth.instance.currentUser?.email ??
          'User';

      final members = <_MemberOwe>[];
      for (final m in widget.membersWhoOwe) {
        final userId = m['userId'] as String?;
        final amount = (m['amount'] as num?)?.toDouble() ?? 0.0;
        if (userId != null && userId.isNotEmpty && amount > 0) {
          members.add(_MemberOwe(userId: userId, amount: amount));
        }
      }

      for (final m in members) {
        try {
          final doc = await FirebaseFirestore.instance
              .collection('users')
              .doc(m.userId)
              .get();
          final data = doc.data();
          m.name = data?['name'] ??
              data?['displayName'] ??
              data?['email'] ??
              m.userId.length > 8
                  ? '${m.userId.substring(0, 8)}...'
                  : m.userId;
        } catch (_) {}
      }

      if (mounted) {
        setState(() {
          _upiId = upiId;
          _userName = userName;
          _members = members;
          _isLoading = false;
          if (upiId == null || upiId.trim().isEmpty) {
            _error = 'Add your UPI ID in profile to receive payments';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _sendNotification() async {
    final selected = _members.where((m) => m.selected).map((m) => m.userId).toList();
    if (selected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Select at least one member to notify'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    if (widget.groupId == null || widget.groupName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Group info missing'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isSendingNotification = true);
    try {
      final upiUri = _buildUpiUri();
      await di.sl<NotificationRemoteDataSource>().sendPaymentReminderNotifications(
        senderId: FirebaseAuth.instance.currentUser!.uid,
        senderName: _userName ?? 'Someone',
        groupId: widget.groupId!,
        groupName: widget.groupName!,
        targetUserIds: selected,
        currency: widget.currency,
        totalAmount: widget.amount,
        upiUri: upiUri.isNotEmpty ? upiUri : null,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Notification sent to ${selected.length} person(s)'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSendingNotification = false);
      }
    }
  }

  String _buildUpiUri() {
    if (_upiId == null || _upiId!.trim().isEmpty) return '';
    final pa = Uri.encodeComponent(_upiId!.trim());
    final pn = Uri.encodeComponent(_userName ?? 'User');
    final am = widget.amount.toStringAsFixed(2);
    final cu = widget.currency == 'PKR' ? 'PKR' : 'INR';
    final tn = widget.groupName != null
        ? Uri.encodeComponent('Settlement: ${widget.groupName}')
        : Uri.encodeComponent('Payment');
    return 'upi://pay?pa=$pa&pn=$pn&am=$am&cu=$cu&tn=$tn';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.backgroundWhite,
      appBar: AppBar(
        title: const Text('Pay via QR'),
        backgroundColor: isDark ? AppColors.darkCard : AppColors.backgroundWhite,
      ),
      body: SafeArea(
        child: _buildBody(isDark),
      ),
    );
  }

  Widget _buildBody(bool isDark) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return ErrorStateWithAction(
        message: _error!,
        actionLabel: 'Go to Profile',
        onAction: () => Navigator.pop(context),
      );
    }

    final uri = _buildUpiUri();
    if (uri.isEmpty) {
      return const Center(child: Text('Invalid UPI ID'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.padding24),
      child: Column(
        children: [
          const SizedBox(height: 24),
          Text(
            'Scan to pay',
            style: TextStyle(
              fontSize: AppFonts.fontSize18,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.textWhite : AppColors.textBlack,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${widget.currency} ${widget.amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: AppFonts.fontSize24,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryGreen,
            ),
          ),
          const SizedBox(height: 32),
          QrCard(data: uri),
          const SizedBox(height: 24),
          Text(
            _upiId ?? '',
            style: TextStyle(
              fontSize: AppFonts.fontSize14,
              color: AppColors.textGrey,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Open GPay, PhonePe, or any UPI app and scan this QR',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: AppFonts.fontSize14,
              color: AppColors.textGrey,
            ),
          ),
          if (_members.isNotEmpty) ...[
            const SizedBox(height: 32),
            Divider(color: AppColors.textGrey.withOpacity(0.3)),
            const SizedBox(height: 16),
            Text(
              'Members who owe you',
              style: TextStyle(
                fontSize: AppFonts.fontSize16,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.textWhite : AppColors.textBlack,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Select members to send payment reminder',
              style: TextStyle(
                fontSize: AppFonts.fontSize12,
                color: AppColors.textGrey,
              ),
            ),
            const SizedBox(height: 12),
            ..._members.map((m) => _buildMemberTile(m, isDark)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: CheckboxListTile(
                    value: _members.every((m) => m.selected),
                    tristate: true,
                    onChanged: (v) {
                      setState(() {
                        final sel = v != false;
                        for (final m in _members) m.selected = sel;
                      });
                    },
                    title: Text(
                      _members.every((m) => m.selected)
                          ? 'Deselect all'
                          : 'Select all',
                      style: TextStyle(
                        fontSize: AppFonts.fontSize14,
                        color: isDark ? AppColors.textWhite : AppColors.textBlack,
                      ),
                    ),
                    controlAffinity: ListTileControlAffinity.leading,
                    activeColor: AppColors.primaryGreen,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isSendingNotification ? null : _sendNotification,
                icon: _isSendingNotification
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.notifications_active_outlined, size: 20),
                label: Text(
                  _isSendingNotification
                      ? 'Sending...'
                      : 'Notify selected (${_members.where((m) => m.selected).length})',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  foregroundColor: AppColors.textWhite,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMemberTile(_MemberOwe m, bool isDark) {
    return CheckboxListTile(
      value: m.selected,
      onChanged: (v) {
        setState(() => m.selected = v ?? false);
      },
      title: Text(
        m.name,
        style: TextStyle(
          fontSize: AppFonts.fontSize14,
          fontWeight: FontWeight.w500,
          color: isDark ? AppColors.textWhite : AppColors.textBlack,
        ),
      ),
      subtitle: Text(
        '${widget.currency} ${m.amount.toStringAsFixed(2)}',
        style: TextStyle(
          fontSize: AppFonts.fontSize12,
          color: AppColors.primaryGreen,
          fontWeight: FontWeight.w600,
        ),
      ),
      controlAffinity: ListTileControlAffinity.leading,
      activeColor: AppColors.primaryGreen,
    );
  }
}
