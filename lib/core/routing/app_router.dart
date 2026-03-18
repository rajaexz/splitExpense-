import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../features/onboarding/presentation/pages/splash_screen.dart';
import '../../../features/onboarding/presentation/pages/onboarding_page.dart';
import '../../features/community/presentation/auth/login_page.dart';
import '../../features/community/presentation/auth/register_page.dart';
import '../../application/auth/auth_cubit.dart';
import '../../../features/community/presentation/home/home_page.dart';
import '../../../features/community/presentation/create_group/create_group_page.dart';
import '../../../features/community/presentation/location_search/location_search_page.dart';
import '../../../features/community/presentation/group_detail/group_detail_page.dart';
import '../../../features/community/presentation/add_expense/add_expense_page.dart';
import '../../../features/community/presentation/add_member/add_member_by_email_page.dart';
import '../../../features/community/presentation/chat/chat_page.dart';
import '../../../features/community/presentation/notifications/notifications_page.dart';
import '../../../features/community/presentation/chat/chats_list_page.dart';
import '../../../features/community/presentation/contacts/contacts_page.dart';
import '../../../features/community/presentation/add_member/add_member_from_contacts_page.dart';
import '../../../features/community/presentation/add_member/add_member_review_page.dart';
import '../../../features/community/presentation/add_member/add_someone_new_page.dart';
import '../../../features/community/presentation/add_member/selected_member_model.dart';
import '../../features/community/presentation/share_gallery/share_gallery_page.dart';
import '../../features/community/presentation/share_gallery/shared_with_me_page.dart';
import '../../features/community/presentation/share_gallery/gallery_viewer_page.dart';
import '../../features/community/presentation/auth/profile_page.dart';
import '../../features/community/presentation/auth/user_profile_page.dart';
import '../../features/community/presentation/auth/edit_profile_page.dart';
import '../../features/community/presentation/auth/settings_page.dart';
import '../../../features/community/presentation/group_history/group_history_page.dart';
import '../../../features/community/presentation/payment/request_payment_qr_page.dart';
import '../../data/models/user_model.dart';
import '../../application/group/group_cubit.dart';
import '../../application/message/message_cubit.dart';
import '../../application/addExpense/expense_cubit.dart';
import '../../application/sheredGallery/shared_gallery_cubit.dart';
import '../../data/models/group_model.dart';
import '../../data/models/expense_model.dart';
import '../constants/app_routes.dart';
import '../di/injection_container.dart' as di;

class AppRouter {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  static final GoRouter router = GoRouter(
    navigatorKey: navigatorKey,
    initialLocation: AppRoutes.splash,
    routes: [
      // Splash Screen
      GoRoute(
        path: AppRoutes.splash,
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      
      // Onboarding
      GoRoute(
        path: AppRoutes.onboarding,
        name: 'onboarding',
        builder: (context, state) => const OnboardingPage(),
      ),
      
      // Authentication
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        builder: (context, state) {
          if (di.sl.isRegistered<AuthCubit>()) {
            return BlocProvider(
              create: (context) => di.sl<AuthCubit>(),
              child: const LoginPage(),
            );
          } else {
            // If AuthCubit is not registered (Firebase not initialized)
            return Scaffold(
              appBar: AppBar(title: const Text('Login')),
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    const Text(
                      'Firebase not initialized',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        'Please configure Firebase before using authentication features.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Go Back'),
                    ),
                  ],
                ),
              ),
            );
          }
        },
      ),
      
      GoRoute(
        path: AppRoutes.register,
        name: 'register',
        builder: (context, state) {
          if (di.sl.isRegistered<AuthCubit>()) {
            return BlocProvider(
              create: (context) => di.sl<AuthCubit>(),
              child: const RegisterPage(),
            );
          } else {
            // If AuthCubit is not registered (Firebase not initialized)
            return Scaffold(
              appBar: AppBar(title: const Text('Register')),
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    const Text(
                      'Firebase not initialized',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        'Please configure Firebase before using authentication features.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Go Back'),
                    ),
                  ],
                ),
              ),
            );
          }
        },
      ),
      
      // Home
      GoRoute(
        path: AppRoutes.home,
        name: 'home',
        builder: (context, state) {
          return MultiBlocProvider(
            providers: [
              BlocProvider(create: (context) => di.sl<GroupCubit>()),
              BlocProvider(create: (context) => di.sl<ExpenseCubit>()),
            ],
            child: const HomePage(),
          );
        },
      ),
      
      // Location Search
      GoRoute(
        path: AppRoutes.locationSearch,
        name: 'location-search',
        builder: (context, state) => const LocationSearchPage(),
      ),
      
      // Create Group
      GoRoute(
        path: AppRoutes.createGroup,
        name: 'create-group',
        builder: (context, state) {
          return BlocProvider(
            create: (context) => di.sl<GroupCubit>(),
            child: const CreateGroupPage(),
          );
        },
      ),
      
      // Group Detail
      GoRoute(
        path: '${AppRoutes.groupDetail}/:id',
        name: 'group-detail',
        builder: (context, state) {
          final groupId = state.pathParameters['id']!;
          return MultiBlocProvider(
            providers: [
              BlocProvider(create: (context) => di.sl<GroupCubit>()),
              BlocProvider(create: (context) => di.sl<ExpenseCubit>()),
            ],
            child: GroupDetailPage(groupId: groupId),
          );
        },
      ),
      
      // Notifications
      GoRoute(
        path: AppRoutes.messages,
        name: 'notifications',
        builder: (context, state) => const NotificationsPage(),
      ),

      // Chats List (Message tab - tap group to open chat)
      GoRoute(
        path: AppRoutes.chats,
        name: 'chats',
        builder: (context, state) {
          return BlocProvider(
            create: (context) => di.sl<GroupCubit>(),
            child: const ChatsListPage(),
          );
        },
      ),
      
      // Contacts
      GoRoute(
        path: AppRoutes.contacts,
        name: 'contacts',
        builder: (context, state) => const ContactsPage(),
      ),

      // Add Member from Contacts
      GoRoute(
        path: AppRoutes.addMemberFromContacts,
        name: 'add-member-from-contacts',
        builder: (context, state) {
          final args = state.extra as Map<String, dynamic>?;
          return AddMemberFromContactsPage(
            groupId: args?['groupId'] as String?,
            groupName: args?['groupName'] as String?,
          );
        },
      ),

      // Add Member Review
      GoRoute(
        path: AppRoutes.addMemberReview,
        name: 'add-member-review',
        builder: (context, state) {
          final args = state.extra as Map<String, dynamic>;
          return BlocProvider(
            create: (context) => di.sl<GroupCubit>(),
            child: AddMemberReviewPage(
              members: (args['members'] as List).cast<SelectedMember>(),
              groupId: args['groupId'] as String?,
              groupName: args['groupName'] as String?,
            ),
          );
        },
      ),

      // Add Someone New
      GoRoute(
        path: AppRoutes.addSomeoneNew,
        name: 'add-someone-new',
        builder: (context, state) {
          final args = state.extra as Map<String, dynamic>?;
          return AddSomeoneNewPage(
            initialName: args?['name'] as String?,
            initialPhone: args?['phone'] as String?,
          );
        },
      ),

      // Request Payment QR
      GoRoute(
        path: AppRoutes.requestPaymentQr,
        name: 'request-payment-qr',
        builder: (context, state) {
          final args = state.extra as Map<String, dynamic>;
          final membersRaw = args['membersWhoOwe'] as List?;
          final membersWhoOwe = membersRaw != null
              ? (membersRaw)
                  .map((e) => e as Map<String, dynamic>)
                  .toList()
              : <Map<String, dynamic>>[];
          return RequestPaymentQrPage(
            amount: (args['amount'] as num).toDouble(),
            currency: args['currency'] as String? ?? 'INR',
            groupName: args['groupName'] as String?,
            groupId: args['groupId'] as String?,
            membersWhoOwe: membersWhoOwe,
          );
        },
      ),

      // Shared Gallery
      GoRoute(
        path: AppRoutes.shareGallery,
        name: 'share-gallery',
        builder: (context, state) {
          return BlocProvider(
            create: (context) => di.sl<SharedGalleryCubit>(),
            child: const ShareGalleryPage(),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.sharedWithMe,
        name: 'shared-with-me',
        builder: (context, state) => const SharedWithMePage(),
      ),
      GoRoute(
        path: '${AppRoutes.galleryViewer}/:id',
        name: 'gallery-viewer',
        builder: (context, state) {
          final shareId = state.pathParameters['id']!;
          return GalleryViewerPage(shareId: shareId);
        },
      ),

      // Profile
      GoRoute(
        path: AppRoutes.profile,
        name: 'profile',
        builder: (context, state) {
          return BlocProvider(
            create: (context) => di.sl<AuthCubit>(),
            child: const ProfilePage(),
          );
        },
      ),

      // User Profile (other user's profile)
      GoRoute(
        path: '${AppRoutes.userProfile}/:id',
        name: 'user-profile',
        builder: (context, state) {
          final userId = state.pathParameters['id']!;
          return UserProfilePage(userId: userId);
        },
      ),

      // Settings
      GoRoute(
        path: AppRoutes.settings,
        name: 'settings',
        builder: (context, state) => const SettingsPage(),
      ),

      // Group History
      GoRoute(
        path: AppRoutes.groupHistory,
        name: 'group-history',
        builder: (context, state) {
          return BlocProvider(
            create: (context) => di.sl<GroupCubit>(),
            child: const GroupHistoryPage(),
          );
        },
      ),

      // Edit Profile
      GoRoute(
        path: AppRoutes.editProfile,
        name: 'edit-profile',
        builder: (context, state) {
          final user = state.extra as UserModel;
          return BlocProvider(
            create: (context) => di.sl<AuthCubit>(),
            child: EditProfilePage(user: user),
          );
        },
      ),
      
      // Add Member (by email/phone)
      GoRoute(
        path: '${AppRoutes.addMember}/:id',
        name: 'add-member',
        builder: (context, state) {
          final groupId = state.pathParameters['id']!;
          return BlocProvider(
            create: (context) => di.sl<GroupCubit>(),
            child: AddMemberByEmailPage(groupId: groupId),
          );
        },
      ),

      // Add / Edit Expense
      GoRoute(
        path: AppRoutes.addExpense,
        name: 'add-expense',
        builder: (context, state) {
          final args = state.extra as Map<String, dynamic>;
          final groupId = args['groupId'] as String;
          final group = args['group'] as GroupModel;
          final expense = args['expense'] as ExpenseModel?;
          return BlocProvider(
            create: (context) => di.sl<ExpenseCubit>(),
            child: AddExpensePage(groupId: groupId, group: group, expense: expense),
          );
        },
      ),
      
      // Chat Page
      GoRoute(
        path: '${AppRoutes.chat}/:id',
        name: 'chat',
        builder: (context, state) {
          final groupId = state.pathParameters['id']!;
          final groupName = state.uri.queryParameters['name'] ?? 'Chat';
          return BlocProvider(
            create: (context) => di.sl<MessageCubit>(),
            child: ChatPage(groupId: groupId, groupName: groupName),
          );
        },
      ),
    ],
    // Error handling
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Error: ${state.error}'),
      ),
    ),
  );
}

