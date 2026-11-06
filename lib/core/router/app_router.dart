import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/auth_providers.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/chat/domain/conversation_summary.dart';
import '../../features/chat/presentation/chat_list_screen.dart';
import '../../features/chat/presentation/conversation_screen.dart';
import '../../features/chat/presentation/create_group_screen.dart';
import '../../features/chat/presentation/group_info_screen.dart';
import '../../features/contacts/presentation/contacts_screen.dart';
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

final appRouterProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(authStateProvider);
  final access = switch (auth) {
    AsyncLoading() => AppAccess.loading,
    AsyncError() => AppAccess.unauthenticated,
    AsyncData(value: final user) when user == null => AppAccess.unauthenticated,
    AsyncData() => AppAccess.authenticated,
  };
  return createAppRouter(access);
});

GoRouter createAppRouter(AppAccess access) => GoRouter(
  initialLocation: RoutePaths.chats,
  redirect: (context, state) => redirectFor(access, state.uri.path),
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
          builder: (_, _) => const FeatureScreen(title: 'Calls'),
        ),
        GoRoute(
          path: RoutePaths.settings,
          builder: (_, _) => const FeatureScreen(title: 'Settings'),
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
