abstract final class RoutePaths {
  static const login = '/login';
  static const splash = '/splash';
  static const onboarding = '/onboarding';
  static const register = '/register';
  static const forgotPassword = '/forgot-password';
  static const verification = '/verification';
  static const profileSetup = '/profile/setup';
  static const profile = '/profile';
  static const chats = '/chats';
  static const contacts = '/contacts';
  static const calls = '/calls';
  static const settings = '/settings';
  static const search = '/search';
  static const newConversation = '/new-conversation';
  static const newGroup = '/groups/new';
  static const conversation = '/conversation';
  static const conversationDetail = '/conversation/:conversationId';
  static const groupInfo = '/conversation/:conversationId/group-info';
  static const notificationSettings = '/settings/notifications';
  static const privacySettings = '/settings/privacy';
  static const accountSettings = '/settings/account';
  static const blockedUsers = '/settings/blocked-users';
  static const logout = '/logout';

  static String conversationWithId(String conversationId) =>
      '/conversation/$conversationId';

  static String groupInfoPath(String conversationId) =>
      '/conversation/$conversationId/group-info';
}
