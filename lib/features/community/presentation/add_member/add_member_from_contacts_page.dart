import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:contacts_service_plus/contacts_service_plus.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_fonts.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../../../core/utils/phone_validator.dart';
import '../../../../application/group/group_cubit.dart';
import '../../../../data/models/group_model.dart';
import 'selected_member_model.dart';
import 'widgets/action_tile.dart';
import 'widgets/contact_select_tile.dart';

class AddMemberFromContactsPage extends StatefulWidget {
  final String? groupId;
  final String? groupName;

  const AddMemberFromContactsPage({
    super.key,
    this.groupId,
    this.groupName,
  });

  @override
  State<AddMemberFromContactsPage> createState() =>
      _AddMemberFromContactsPageState();
}

class _AddMemberFromContactsPageState extends State<AddMemberFromContactsPage> {
  final _searchController = TextEditingController();
  List<Contact> _contacts = [];
  final Set<SelectedMember> _selected = {};
  bool _isLoading = false;
  bool _isGranted = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _checkPermission();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _checkPermission() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    final status = await Permission.contacts.status;
    setState(() {
      _isGranted = status.isGranted;
      _isLoading = false;
    });
    if (_isGranted) _fetchContacts();
  }

  Future<void> _requestPermission() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    final status = await Permission.contacts.request();
    setState(() {
      _isGranted = status.isGranted;
      _isLoading = false;
    });
    if (_isGranted) {
      _fetchContacts();
    } else {
      setState(() {
        _errorMessage = status.isPermanentlyDenied
            ? 'Contacts permission was permanently denied. Please enable it in Settings.'
            : 'Contacts permission was denied.';
      });
    }
  }

  Future<void> _fetchContacts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final contacts = await ContactsService.getContacts(withThumbnails: false);
      setState(() {
        _contacts = contacts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load contacts: $e';
        _isLoading = false;
      });
    }
  }

  SelectedMember? _contactToMember(Contact c) {
    final phones = c.phones;
    if (phones == null || phones.isEmpty) return null;
    final phone = phones.first.value ?? '';
    if (phone.trim().isEmpty) return null;
    final name = c.displayName ?? c.givenName ?? c.familyName ?? 'Unknown';
    return SelectedMember(
      name: name,
      phone: phone.trim().startsWith('+') ? phone.trim() : '+91$phone',
      email: c.emails?.isNotEmpty == true ? c.emails!.first.value : null,
    );
  }

  void _toggleContact(Contact c) {
    final m = _contactToMember(c);
    if (m == null) return;
    final error = PhoneValidator.validatePhone(m.phone);
    if (error != null) {
      _showPhoneErrorDialog(error);
      return;
    }
    setState(() {
      if (_selected.any((s) => s.phone == m.phone)) {
        _selected.removeWhere((s) => s.phone == m.phone);
      } else {
        _selected.add(m);
      }
    });
  }

  bool _isSelected(Contact c) {
    final m = _contactToMember(c);
    if (m == null) return false;
    return _selected.any((s) => s.phone == m.phone);
  }

  void _removeSelected(SelectedMember m) {
    setState(() => _selected.remove(m));
  }

  Future<void> _addSomeoneNew() async {
    final added = await context.push<SelectedMember>(
      AppRoutes.addSomeoneNew,
      extra: null,
    );
    if (added != null && mounted) {
      setState(() => _selected.add(added));
    }
  }

  void _goToReview() {
    if (_selected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select at least one contact')),
      );
      return;
    }
    for (final m in _selected) {
      final error = PhoneValidator.validatePhone(m.phone);
      if (error != null) {
        _showPhoneErrorDialog(error);
        return;
      }
    }

    if (widget.groupId != null) {
      _navigateToReview(widget.groupId, widget.groupName);
      return;
    }

    _showGroupChoiceSheet();
  }

  void _navigateToReview(String? groupId, String? groupName) {
    context.push(
      AppRoutes.addMemberReview,
      extra: {
        'members': _selected.toList(),
        'groupId': groupId,
        'groupName': groupName,
      },
    );
  }

  void _showPhoneErrorDialog(String message) {
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

  void _showGroupChoiceSheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      backgroundColor: isDark ? AppColors.darkCard : AppColors.backgroundWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.padding16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Add members to',
                style: TextStyle(
                  fontSize: AppFonts.fontSize18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.textWhite : AppColors.textBlack,
                ),
              ),
              const SizedBox(height: AppDimensions.margin16),
              ActionTile(
                icon: Icons.group,
                label: 'Existing group',
                subtitle: 'Add selected contacts to an existing group',
                isDark: isDark,
                onTap: () {
                  Navigator.pop(ctx);
                  _showExistingGroupPicker(ctx);
                },
              ),
              ActionTile(
                icon: Icons.add_circle_outline,
                label: 'New group',
                subtitle: 'Create a new group and add these members',
                isDark: isDark,
                onTap: () {
                  Navigator.pop(ctx);
                  _createNewGroupAndAddMembers();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showExistingGroupPicker(BuildContext sheetContext) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      backgroundColor: isDark ? AppColors.darkCard : AppColors.backgroundWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => BlocProvider(
        create: (_) => di.sl<GroupCubit>(),
        child: Builder(
          builder: (innerCtx) => SafeArea(
            child: StreamBuilder<List<GroupModel>>(
              stream: innerCtx.read<GroupCubit>().getUserGroupsStream(),
              builder: (context, snapshot) {
                final groups = snapshot.data ?? [];
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (groups.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(AppDimensions.padding16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'No groups yet',
                          style: TextStyle(
                            fontSize: AppFonts.fontSize18,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? AppColors.textWhite
                                : AppColors.textBlack,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Create a new group first',
                          style: TextStyle(color: AppColors.textGrey),
                        ),
                      ],
                    ),
                  );
                }
                return Padding(
                  padding: const EdgeInsets.all(AppDimensions.padding16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Select group',
                        style: TextStyle(
                          fontSize: AppFonts.fontSize18,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? AppColors.textWhite
                              : AppColors.textBlack,
                        ),
                      ),
                      const SizedBox(height: AppDimensions.margin16),
                      ...groups.map((g) => ListTile(
                            leading: Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: isDark
                                    ? AppColors.darkSurface
                                    : AppColors.backgroundGrey,
                                borderRadius:
                                    BorderRadius.circular(AppDimensions.radius12),
                              ),
                              child: const Icon(Icons.group),
                            ),
                            title: Text(g.name),
                            onTap: () {
                              Navigator.pop(innerCtx);
                              _navigateToReview(g.id, g.name);
                            },
                          )),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _createNewGroupAndAddMembers() async {
    final result =
        await context.push<Map<String, dynamic>>(AppRoutes.createGroup);
    if (result != null && mounted) {
      final groupId = result['groupId'] as String?;
      final groupName = result['groupName'] as String?;
      if (groupId != null) {
        _navigateToReview(groupId, groupName ?? 'Group');
      }
    }
  }

  List<Contact> get _filteredContacts {
    final q = _searchController.text.trim().toLowerCase();
    if (q.isEmpty) return _contacts;
    return _contacts.where((c) {
      final name =
          (c.displayName ?? c.givenName ?? c.familyName ?? '').toLowerCase();
      final phones = c.phones?.map((p) => p.value ?? '').join(' ') ?? '';
      final emails = c.emails?.map((e) => e.value ?? '').join(' ') ?? '';
      return name.contains(q) ||
          phones.toLowerCase().contains(q) ||
          emails.toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Text(
          widget.groupId != null
              ? 'Add to ${widget.groupName ?? "Group"}'
              : 'Add friends',
        ),
        backgroundColor: isDark ? AppColors.darkCard : AppColors.backgroundWhite,
      ),
      body: SafeArea(
        child: _buildBody(isDark),
      ),
    );
  }

  Widget _buildBody(bool isDark) {
    if (_isLoading && _contacts.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (!_isGranted) {
      return _buildPermissionRequest(isDark);
    }

    if (_errorMessage != null) {
      return _buildError(isDark);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.all(AppDimensions.padding16),
          child: TextField(
            controller: _searchController,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Enter name, email, or phone',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: isDark ? AppColors.darkCard : AppColors.backgroundGrey,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radius12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        if (_selected.isNotEmpty) _buildSelectedChips(isDark),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.padding16,
            ),
            children: [
              ActionTile(
                icon: Icons.person_add,
                label: 'Add someone new',
                isDark: isDark,
                onTap: _addSomeoneNew,
              ),
              const SizedBox(height: AppDimensions.margin16),
              Text(
                'From your contacts',
                style: TextStyle(
                  fontSize: AppFonts.fontSize14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textGrey,
                ),
              ),
              const SizedBox(height: AppDimensions.margin8),
              ..._filteredContacts.map((c) => ContactSelectTile(
                    contact: c,
                    isSelected: _isSelected(c),
                    isDark: isDark,
                    onTap: () => _toggleContact(c),
                  )),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(AppDimensions.padding16),
          child: ElevatedButton(
            onPressed: _goToReview,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGreen,
              foregroundColor: AppColors.textWhite,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radius12),
              ),
            ),
            child: const Text('Next'),
          ),
        ),
      ],
    );
  }

  Widget _buildSelectedChips(bool isDark) {
    return SizedBox(
      height: 90,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppDimensions.padding16),
        children: _selected.map((m) {
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor:
                          isDark ? AppColors.darkCard : AppColors.backgroundGrey,
                      child: const Icon(
                        Icons.mail_outline,
                        color: AppColors.textGrey,
                      ),
                    ),
                    Positioned(
                      top: -4,
                      right: -4,
                      child: GestureDetector(
                        onTap: () => _removeSelected(m),
                        child: const CircleAvatar(
                          radius: 10,
                          backgroundColor: AppColors.error,
                          child: Icon(
                            Icons.close,
                            size: 14,
                            color: AppColors.textWhite,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                SizedBox(
                  width: 56,
                  child: Text(
                    m.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: AppFonts.fontSize12,
                      color: isDark ? AppColors.textWhite : AppColors.textBlack,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPermissionRequest(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.contacts_outlined,
                size: 64, color: AppColors.primaryGreen),
            const SizedBox(height: 24),
            Text(
              'Access Your Contacts',
              style: TextStyle(
                fontSize: AppFonts.fontSize20,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.textWhite : AppColors.textBlack,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'We need permission to access your contacts to add friends.',
              style: const TextStyle(fontSize: 14, color: AppColors.textGrey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isLoading ? null : _requestPermission,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                foregroundColor: AppColors.textWhite,
              ),
              child: const Text('Allow Access'),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () async {
                await openAppSettings();
                _checkPermission();
              },
              child: const Text('Open Settings'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: AppColors.error),
            const SizedBox(height: 16),
            Text(_errorMessage!, textAlign: TextAlign.center),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _fetchContacts,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
