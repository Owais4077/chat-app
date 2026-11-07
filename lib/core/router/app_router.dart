import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/domain/auth_repository.dart';
import '../../features/auth/presentation/auth_providers.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/chat/domain/conversation_summary.dart';
import '../../features/chat/presentation/calls_screen.dart';
import '../../features/chat/presentation/chat_list_screen.dart';
import '../../features/chat/presentation/conversation_screen.dart';
import '../../features/chat/presentation/create_group_screen.dart';
import '../../features/chat/presentation/group_info_screen.dart';
import '../../features/contacts/presentation/contacts_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../shared/widgets/feature_screen.dart';
import 'route_paths.dart';

enum AppAccess { loading, unauthenticated, profileIncomplete, authenticated }

String? redirectFor(AppAccess access, String location) {
  if (access == AppAccess.loading && location != RoutePaths.splash) {
    return RoutePaths.splash;
  }
  final public = {
    RoutePaths.login,
    RoutePaths.register,
    RoutePaths.forgotPassword,
    RoutePaths.verification,
    RoutePaths.profileSetup,
  };
  if (access == AppAccess.unauthenticated && !public.contains(location)) {
    return RoutePaths.login;
  }
  if (access == AppAccess.profileIncomplete &&
      location != RoutePaths.profileSetup) {
    return RoutePaths.profileSetup;
  }
  if (access == AppAccess.authenticated && public.contains(location)) {
    return RoutePaths.chats;
  }
  return null;
}

class AuthRouterNotifier extends ChangeNotifier {
  AuthRouterNotifier(AuthRepository authRepo) {
    _subscription = authRepo.authStateChanges().listen((_) {
      notifyListeners();
    });
  }

  StreamSubscription<dynamic>? _subscription;

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final authRepo = ref.watch(authRepositoryProvider);
  final notifier = AuthRouterNotifier(authRepo);
  ref.onDispose(notifier.dispose);

  final initialAccess = authRepo.currentUser() != null
      ? AppAccess.authenticated
      : AppAccess.unauthenticated;

  return createAppRouter(
    initialAccess,
    authRepo,
    notifier,
  );
});

GoRouter createAppRouter(
  AppAccess access, [
  AuthRepository? authRepo,
  Listenable? refreshListenable,
]) =>
    GoRouter(
      initialLocation: RoutePaths.chats,
      refreshListenable: refreshListenable,
      redirect: (context, state) {
        final effectiveAccess = (authRepo?.currentUser() != null)
            ? AppAccess.authenticated
            : access;
        return redirectFor(effectiveAccess, state.uri.path);
      },
  routes: [
    GoRoute(
      path: RoutePaths.splash,
      builder: (_, _) => const FeatureScreen(title: 'Relay'),
    ),
    GoRoute(
      path: RoutePaths.onboarding,
      builder: (_, _) => const FeatureScreen(title: 'Welcome to Relay'),
    ),
    GoRoute(path: RoutePaths.login, builder: (_, _) => const LoginScreen()),
    GoRoute(
      path: RoutePaths.register,
      builder: (_, _) => const RegisterScreen(),
    ),
    GoRoute(
      path: RoutePaths.forgotPassword,
      builder: (_, _) => const FeatureScreen(title: 'Reset password'),
    ),
    GoRoute(
      path: RoutePaths.verification,
      builder: (_, _) => const FeatureScreen(title: 'Verify email'),
    ),
    GoRoute(
      path: RoutePaths.profileSetup,
      builder: (_, _) => const FeatureScreen(title: 'Profile setup'),
    ),
    GoRoute(
      path: RoutePaths.profile,
      builder: (_, _) => const FeatureScreen(title: 'Profile'),
    ),
    GoRoute(
      path: RoutePaths.search,
      builder: (_, _) => const FeatureScreen(title: 'Search users'),
    ),
    GoRoute(
      path: RoutePaths.newConversation,
      builder: (_, _) => const FeatureScreen(title: 'New conversation'),
    ),
    GoRoute(
      path: RoutePaths.newGroup,
      builder: (_, _) => const CreateGroupScreen(),
    ),
    GoRoute(
      path: RoutePaths.groupInfo,
      builder: (_, state) {
        final conversationId = state.pathParameters['conversationId'] ?? '';
        final extra = state.extra as Map<String, dynamic>?;
        final title = extra?['title'] as String? ?? 'Group info';
        final role =
            extra?['myRole'] as GroupMemberRole? ?? GroupMemberRole.member;
        return GroupInfoScreen(
          conversationId: conversationId,
          title: title,
          myRole: role,
        );
      },
    ),
    GoRoute(
      path: RoutePaths.conversationDetail,
      builder: (_, state) {
        final conversationId = state.pathParameters['conversationId'] ?? '';
        final extra = state.extra as Map<String, dynamic>?;
        final title = extra?['title'] as String?;
        final isGroup = extra?['isGroup'] as bool? ?? false;
        final myRole =
            extra?['myRole'] as GroupMemberRole? ?? GroupMemberRole.member;
        return ConversationScreen(
          conversationId: conversationId,
          title: title,
          isGroup: isGroup,
          myRole: myRole,
        );
      },
    ),
    GoRoute(
      path: RoutePaths.conversation,
      builder: (_, _) => const FeatureScreen(title: 'Conversation'),
    ),
    GoRoute(
      path: RoutePaths.notificationSettings,
      builder: (_, _) => const FeatureScreen(title: 'Notifications'),
    ),
    GoRoute(
      path: RoutePaths.privacySettings,
      builder: (_, _) => const FeatureScreen(title: 'Privacy'),
    ),
    GoRoute(
      path: RoutePaths.accountSettings,
      builder: (_, _) => const FeatureScreen(title: 'Account'),
    ),
    GoRoute(
      path: RoutePaths.blockedUsers,
      builder: (_, _) => const FeatureScreen(title: 'Blocked users'),
    ),
    GoRoute(
      path: RoutePaths.logout,
      builder: (_, _) => const FeatureScreen(title: 'Log out'),
    ),
    ShellRoute(
      builder: (_, _, child) => MainShell(child: child),
      routes: [
        GoRoute(
          path: RoutePaths.chats,
          builder: (_, _) => const ChatListScreen(),
        ),
        GoRoute(
          path: RoutePaths.contacts,
          builder: (_, _) => const ContactsScreen(),
        ),
        GoRoute(
          path: RoutePaths.calls,
          builder: (_, _) => const CallsScreen(),
        ),
        GoRoute(
          path: RoutePaths.settings,
          builder: (_, _) => const SettingsScreen(),
        ),
      ],
    ),
  ],
);

class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final path = GoRouterState.of(context).uri.path;
    final destinations = [
      RoutePaths.chats,
      RoutePaths.calls,
      RoutePaths.contacts,
      RoutePaths.settings,
    ];
    final index = destinations.indexOf(path).clamp(0, 3);
    final isWide = MediaQuery.sizeOf(context).width >= 700;

    if (isWide) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: index,
              onDestinationSelected: (value) => context.go(destinations[value]),
              labelType: NavigationRailLabelType.selected,
              leading: const Padding(
                padding: EdgeInsets.only(top: 8.0, bottom: 16.0),
                child: CircleAvatar(
                  backgroundColor: Color(0xFF00A884),
                  radius: 18,
                  child: Icon(Icons.chat, color: Colors.white, size: 20),
                ),
              ),
              destinations: const [
                NavigationRailDestination(
                  icon: Icon(Icons.chat_bubble_outline),
                  selectedIcon: Icon(Icons.chat_bubble, color: Color(0xFF00A884)),
                  label: Text('Chats'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.call_outlined),
                  selectedIcon: Icon(Icons.call, color: Color(0xFF00A884)),
                  label: Text('Calls'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.people_outline),
                  selectedIcon: Icon(Icons.people, color: Color(0xFF00A884)),
                  label: Text('Contacts'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.settings_outlined),
                  selectedIcon: Icon(Icons.settings, color: Color(0xFF00A884)),
                  label: Text('Settings'),
                ),
              ],
            ),
            const VerticalDivider(thickness: 1, width: 1),
            Expanded(child: child),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Relay')),
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (value) => context.go(destinations[value]),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline),
            label: 'Chats',
          ),
          NavigationDestination(
            icon: Icon(Icons.call_outlined),
            label: 'Calls',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            label: 'Contacts',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
