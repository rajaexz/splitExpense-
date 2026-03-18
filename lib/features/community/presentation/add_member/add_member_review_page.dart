import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_fonts.dart';
import '../../../../core/utils/phone_validator.dart';
import '../../../../application/group/group_cubit.dart';
import 'selected_member_model.dart';
import 'widgets/review_tile.dart';

class AddMemberReviewPage extends StatefulWidget {
  final List<SelectedMember> members;
  final String? groupId;
  final String? groupName;

  const AddMemberReviewPage({
    super.key,
    required this.members,
    this.groupId,
    this.groupName,
  });

  @override
  State<AddMemberReviewPage> createState() => _AddMemberReviewPageState();
}

class _AddMemberReviewPageState extends State<AddMemberReviewPage> {
  late List<SelectedMember> _members;

  @override
  void initState() {
    super.initState();
    _members = List.from(widget.members);
  }

  void _remove(int index) {
    setState(() => _members.removeAt(index));
  }

  Future<void> _editMember(int index) async {
    final m = _members[index];
    final edited = await context.push<SelectedMember>(
      AppRoutes.addSomeoneNew,
      extra: {'name': m.name, 'phone': m.phone},
    );
    if (edited != null && mounted) {
      setState(() => _members[index] = edited);
    }
  }

  Future<void> _addFriends() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login first')),
      );
      return;
    }

    if (widget.groupId == null) {
      _showInviteOnlyDialog();
      return;
    }

    for (final m in _members) {
      final error = PhoneValidator.validatePhone(m.phone);
      if (error != null) {
        _showErrorDialog(error);
        return;
      }
    }

    final cubit = context.read<GroupCubit>();
    int added = 0;
    String? lastError;

    for (final m in _members) {
      if (!mounted) return;
      final input = m.email ?? m.phone;
      await cubit.addMemberByEmailOrPhone(widget.groupId!, input);
      final state = cubit.state;
      if (state is GroupError) {
        lastError = state.message;
        if (_isAlreadyInUseError(lastError)) {
          _showErrorDialog(lastError);
          return;
        }
      } else if (state is FriendAdded) {
        added++;
      }
    }

    if (!mounted) return;
    if (added > 0) {
      _showSuccessDialog(added);
    } else if (lastError != null) {
      _showErrorDialog(lastError);
    } else if (_members.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Could not add members. User may not be registered.',
          ),
        ),
      );
    }
  }

  bool _isAlreadyInUseError(String msg) {
    return msg.contains('already belongs') || msg.contains('already in use');
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Error'),
        content: SingleChildScrollView(
          child: Text(message),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('OK', style: TextStyle(color: AppColors.primaryGreen)),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(int count) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🎉', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 16),
            Text(
              'Your friend${count > 1 ? 's have' : ' has'} been added',
              style: const TextStyle(
                fontSize: AppFonts.fontSize18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Send a text message to let them know:',
              style: TextStyle(fontSize: AppFonts.fontSize14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  _sendInviteToAll();
                },
                child: Text(
                  'Send text message',
                  style: TextStyle(
                    color: AppColors.primaryGreen,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ).then((_) {
      if (mounted) context.pop();
    });
  }

  void _showInviteOnlyDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🎉', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 16),
            const Text(
              'Invite your friends',
              style: TextStyle(
                fontSize: AppFonts.fontSize18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Send them an invitation to join JobCrak!',
              style: TextStyle(fontSize: AppFonts.fontSize14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  _sendInviteToAll();
                  if (mounted) context.pop();
                },
                child: Text(
                  'Send text message',
                  style: TextStyle(
                    color: AppColors.primaryGreen,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendInviteToAll() async {
    for (final m in _members) {
      final inviteText =
          'Hey ${m.name}! Join me on JobCrak - the job search app. Download now and find your dream job!';
      final phone = _normalizePhone(m.phone);
      final uri = Uri.parse(
          'sms:$phone?body=${Uri.encodeComponent(inviteText)}');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    }
  }

  String _normalizePhone(String phone) {
    return phone.replaceAll(RegExp(r'[\s\-\(\)\+]'), '');
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
        title: const Text('Review'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _members.isEmpty ? null : _addFriends,
          ),
        ],
        backgroundColor: isDark ? AppColors.darkCard : AppColors.backgroundWhite,
      ),
      body: SafeArea(
        child: BlocListener<GroupCubit, GroupState>(
          listener: (context, state) {
            if (state is GroupError &&
                _isAlreadyInUseError(state.message)) {
              _showErrorDialog(state.message);
            }
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(AppDimensions.padding16),
                  children: [
                    ...List.generate(_members.length, (i) {
                      final m = _members[i];
                      return ReviewTile(
                        member: m,
                        isDark: isDark,
                        onRemove: () => _remove(i),
                        onEdit: () => _editMember(i),
                      );
                    }),
                    const SizedBox(height: AppDimensions.margin24),
                    Text(
                      widget.groupId != null
                          ? "People with phone numbers and emails will be notified that you've added them as a friend. You can start adding expenses right away."
                          : "These people will be notified you've added them as a friend. You can start adding expenses right away.",
                      style: const TextStyle(
                        fontSize: AppFonts.fontSize14,
                        color: AppColors.textGrey,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppDimensions.padding16),
                child: ElevatedButton(
                  onPressed: _members.isEmpty ? null : _addFriends,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    foregroundColor: AppColors.textWhite,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppDimensions.radius12),
                    ),
                  ),
                  child: const Text('Add friends'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
