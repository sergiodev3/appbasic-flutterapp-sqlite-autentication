class AppConstants {
  const AppConstants._();

  static const String databaseName = 'checklist_demo.db';
  static const int databaseVersion = 1;

  static const String usersTable = 'users';
  static const String taskGroupsTable = 'task_groups';
  static const String tasksTable = 'tasks';

  static const String sessionUserIdKey = 'session_user_id';

  static const Duration defaultAnimationDuration = Duration(milliseconds: 350);
}
