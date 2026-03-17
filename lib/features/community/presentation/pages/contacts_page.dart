import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:contacts_service_plus/contacts_service_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_fonts.dart';

class ContactsPage extends StatefulWidget {
  const ContactsPage({Key? key}) : super(key: key);

  @override
  State<ContactsPage> createState() => _ContactsPageState();
}

class _ContactsPageState extends State<ContactsPage> {
  bool _isGranted = false;
  List<Contact> _contacts = [];
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _checkPermission();
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

    if (_isGranted) {
      _fetchContacts();
    }
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
    } else if (status.isDenied) {
      setState(() {
        _errorMessage = 'Contacts permission was denied. You can enable it in Settings.';
      });
    } else if (status.isPermanentlyDenied) {
      setState(() {
        _errorMessage = 'Contacts permission was permanently denied. Please enable it in Settings.';
      });
    }
  }

  Future<void> _fetchContacts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final contacts = await ContactsService.getContacts(
        withThumbnails: false,
      );
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

  void _showContactOptions(BuildContext context, Contact contact) {
    final phones = contact.phones ?? [];
    if (phones.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No phone number for ${contact.displayName ?? 'this contact'}'),
        ),
      );
      return;
    }

    final name = contact.displayName ?? contact.givenName ?? contact.familyName ?? 'Unknown';
    final inviteText = 'Hey $name! Join me on JobCrak - the job search app. Download now and find your dream job!';

    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? AppColors.darkCard
          : AppColors.backgroundWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Text(
                  name,
                  style: TextStyle(
                    fontSize: AppFonts.fontSize18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(ctx).brightness == Brightness.dark
                        ? AppColors.textWhite
                        : AppColors.textBlack,
                  ),
                ),
              ),
              _InviteOption(
                icon: Icons.share_outlined,
                label: 'Invite (Share)',
                onTap: () async {
                  Navigator.pop(ctx);
                  await Share.share(inviteText);
                },
              ),
              _InviteOption(
                icon: Icons.chat_bubble_outline,
                label: 'WhatsApp',
                onTap: () async {
                  Navigator.pop(ctx);
                  final phone = _normalizePhone(phones.first.value ?? '');
                  final uri = Uri.parse('https://wa.me/$phone?text=${Uri.encodeComponent(inviteText)}');
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  } else {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Could not open WhatsApp')),
                      );
                    }
                  }
                },
              ),
              _InviteOption(
                icon: Icons.sms_outlined,
                label: 'Message (SMS)',
                onTap: () async {
                  Navigator.pop(ctx);
                  final phone = _normalizePhone(phones.first.value ?? '');
                  final uri = Uri.parse('sms:$phone?body=${Uri.encodeComponent(inviteText)}');
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  } else {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Could not open Messages')),
                      );
                    }
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _normalizePhone(String phone) {
    return phone.replaceAll(RegExp(r'[\s\-\(\)\+]'), '');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.backgroundWhite,
      appBar: AppBar(
        title: const Text('My Contact List'),
      ),
      body: SafeArea(
        child: _buildBody(isDark, theme),
      ),
    );
  }

  Widget _buildBody(bool isDark, ThemeData theme) {
    if (_isLoading && _contacts.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (!_isGranted) {
      return _buildPermissionRequest(isDark);
    }

    if (_errorMessage != null) {
      return _buildErrorState(isDark);
    }

    if (_contacts.isEmpty) {
      return _buildEmptyState(isDark);
    }

    return RefreshIndicator(
      onRefresh: _fetchContacts,
      child: ListView.builder(
        padding: const EdgeInsets.all(AppDimensions.padding16),
        itemCount: _contacts.length,
        itemBuilder: (context, index) {
          final contact = _contacts[index];
          return _ContactTile(
            contact: contact,
            isDark: isDark,
            onTap: () => _showContactOptions(context, contact),
          );
        },
      ),
    );
  }

  Widget _buildPermissionRequest(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.padding24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.primaryGreen.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.contacts_outlined,
                size: 64,
                color: AppColors.primaryGreen,
              ),
            ),
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
            const Text(
              'We need permission to access your contacts so you can view your contact list and add members to groups.',
              style: TextStyle(
                fontSize: AppFonts.fontSize14,
                color: AppColors.textGrey,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _requestPermission,
              icon: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check_circle_outline),
              label: Text(_isLoading ? 'Requesting...' : 'Allow Access'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                foregroundColor: AppColors.textWhite,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              ),
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

  Widget _buildErrorState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: AppColors.error),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textGrey),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _fetchContacts,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                foregroundColor: AppColors.textWhite,
              ),
              child: const Text('Retry'),
            ),
            const SizedBox(height: 12),
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

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.contacts_outlined,
            size: 64,
            color: AppColors.textGrey,
          ),
          const SizedBox(height: 16),
          Text(
            'No contacts found',
            style: TextStyle(
              fontSize: AppFonts.fontSize18,
              color: AppColors.textGrey,
            ),
          ),
        ],
      ),
    );
  }
}

class _InviteOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _InviteOption({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListTile(
      leading: Icon(icon, color: AppColors.primaryGreen),
      title: Text(
        label,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          color: isDark ? AppColors.textWhite : AppColors.textBlack,
        ),
      ),
      onTap: onTap,
    );
  }
}

class _ContactTile extends StatelessWidget {
  final Contact contact;
  final bool isDark;
  final VoidCallback onTap;

  const _ContactTile({
    required this.contact,
    required this.isDark,
    required this.onTap,
  });

  String _getPhoneNumbers(Contact c) {
    final phones = c.phones;
    if (phones == null || phones.isEmpty) return 'No number';
    return phones.map((p) => p.value ?? '').where((v) => v.isNotEmpty).join(', ');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = contact.displayName ?? contact.givenName ?? contact.familyName ?? 'Unknown';
    final initial = name.isNotEmpty ? name[0] : '?';

    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.margin8),
      padding: const EdgeInsets.all(AppDimensions.padding12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.backgroundGrey,
        borderRadius: BorderRadius.circular(AppDimensions.radius12),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: CircleAvatar(
          backgroundColor: AppColors.primaryGreen,
          child: Text(
            initial.toUpperCase(),
            style: const TextStyle(color: AppColors.textWhite),
          ),
        ),
        title: Text(
          name,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          _getPhoneNumbers(contact),
          style: theme.textTheme.bodySmall?.copyWith(
            color: AppColors.textGrey,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        onTap: onTap,
      ),
    );
  }
}
