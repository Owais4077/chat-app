import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/chat/presentation/chat_list_screen.dart';
import '../../shared/widgets/feature_screen.dart';
import 'route_paths.dart';

enum AppAccess { unauthenticated, profileIncomplete, authenticated }

String? redirectFor(AppAccess access, String location) {
  final public = {RoutePaths.login, RoutePaths.profileSetup};
  if (access == AppAccess.unauthenticated && !public.contains(location)) return RoutePaths.login;
  if (access == AppAccess.profileIncomplete && location != RoutePaths.profileSetup) return RoutePaths.profileSetup;
  if (access == AppAccess.authenticated && public.contains(location)) return RoutePaths.chats;
  return null;
}

final appRouterProvider = Provider<GoRouter>((ref) => createAppRouter(AppAccess.unauthenticated));

GoRouter createAppRouter(AppAccess access) => GoRouter(
  initialLocation: RoutePaths.chats,
  redirect: (context, state) => redirectFor(access, state.uri.path),
  routes: [
    GoRoute(path: RoutePaths.splash, builder: (_, _) => const FeatureScreen(title: 'Relay')),
    GoRoute(path: RoutePaths.onboarding, builder: (_, _) => const FeatureScreen(title: 'Welcome to Relay')),
    GoRoute(path: RoutePaths.login, builder: (_, _) => const FeatureScreen(title: 'Sign in', message: 'Sign in to Relay')),
    GoRoute(path: RoutePaths.register, builder: (_, _) => const FeatureScreen(title: 'Create account')),
    GoRoute(path: RoutePaths.forgotPassword, builder: (_, _) => const FeatureScreen(title: 'Reset password')),
    GoRoute(path: RoutePaths.verification, builder: (_, _) => const FeatureScreen(title: 'Verify email')),
    GoRoute(path: RoutePaths.profileSetup, builder: (_, _) => const FeatureScreen(title: 'Profile setup')),
    GoRoute(path: RoutePaths.profile, builder: (_, _) => const FeatureScreen(title: 'Profile')),
    GoRoute(path: RoutePaths.search, builder: (_, _) => const FeatureScreen(title: 'Search users')),
    GoRoute(path: RoutePaths.newConversation, builder: (_, _) => const FeatureScreen(title: 'New conversation')),
    GoRoute(path: RoutePaths.conversation, builder: (_, _) => const FeatureScreen(title: 'Conversation')),
    GoRoute(path: RoutePaths.notificationSettings, builder: (_, _) => const FeatureScreen(title: 'Notifications')),
    GoRoute(path: RoutePaths.privacySettings, builder: (_, _) => const FeatureScreen(title: 'Privacy')),
    GoRoute(path: RoutePaths.accountSettings, builder: (_, _) => const FeatureScreen(title: 'Account')),
    GoRoute(path: RoutePaths.blockedUsers, builder: (_, _) => const FeatureScreen(title: 'Blocked users')),
    GoRoute(path: RoutePaths.logout, builder: (_, _) => const FeatureScreen(title: 'Log out')),
    ShellRoute(builder: (_, _, child) => MainShell(child: child), routes: [
      GoRoute(path: RoutePaths.chats, builder: (_, _) => const ChatListScreen()),
      GoRoute(path: RoutePaths.contacts, builder: (_, _) => const FeatureScreen(title: 'Contacts')),
      GoRoute(path: RoutePaths.calls, builder: (_, _) => const FeatureScreen(title: 'Calls')),
      GoRoute(path: RoutePaths.settings, builder: (_, _) => const FeatureScreen(title: 'Settings')),
    ]),
  ],
);

class MainShell extends StatelessWidget { const MainShell({super.key, required this.child}); final Widget child; @override Widget build(BuildContext context) { final path = GoRouterState.of(context).uri.path; final destinations = [RoutePaths.chats, RoutePaths.calls, RoutePaths.contacts, RoutePaths.settings]; final index = destinations.indexOf(path).clamp(0, 3); return Scaffold(appBar: AppBar(title: const Text('Relay')), body: child, bottomNavigationBar: NavigationBar(selectedIndex: index, onDestinationSelected: (value) => context.go(destinations[value]), destinations: const [NavigationDestination(icon: Icon(Icons.chat_bubble_outline), label: 'Chats'), NavigationDestination(icon: Icon(Icons.call_outlined), label: 'Calls'), NavigationDestination(icon: Icon(Icons.people_outline), label: 'Contacts'), NavigationDestination(icon: Icon(Icons.settings_outlined), label: 'Settings')])); } }
