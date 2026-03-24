import '../../core/constants/app_constants.dart';
import '../database/database_helper.dart';
import '../models/task_group_model.dart';

class TaskGroupRepository {
  TaskGroupRepository({DatabaseHelper? databaseHelper})
      : _databaseHelper = databaseHelper ?? DatabaseHelper.instance;

  final DatabaseHelper _databaseHelper;

  Future<List<TaskGroupModel>> getGroupsByUser(int userId) async {
    final db = await _databaseHelper.database;
    final rows = await db.rawQuery('''
      SELECT
        g.id,
        g.user_id,
        g.name,
        g.description,
        g.created_at,
        g.updated_at,
        COUNT(t.id) AS total_tasks,
        COALESCE(SUM(CASE WHEN t.is_completed = 1 THEN 1 ELSE 0 END), 0) AS completed_tasks
      FROM ${AppConstants.taskGroupsTable} g
      LEFT JOIN ${AppConstants.tasksTable} t ON t.group_id = g.id
      WHERE g.user_id = ?
      GROUP BY g.id
      ORDER BY g.updated_at DESC
    ''', [userId]);

    return rows.map(TaskGroupModel.fromMap).toList();
  }

  Future<TaskGroupModel?> getGroupById(int groupId) async {
    final db = await _databaseHelper.database;
    final rows = await db.rawQuery('''
      SELECT
        g.id,
        g.user_id,
        g.name,
        g.description,
        g.created_at,
        g.updated_at,
        COUNT(t.id) AS total_tasks,
        COALESCE(SUM(CASE WHEN t.is_completed = 1 THEN 1 ELSE 0 END), 0) AS completed_tasks
      FROM ${AppConstants.taskGroupsTable} g
      LEFT JOIN ${AppConstants.tasksTable} t ON t.group_id = g.id
      WHERE g.id = ?
      GROUP BY g.id
      LIMIT 1
    ''', [groupId]);

    if (rows.isEmpty) {
      return null;
    }

    return TaskGroupModel.fromMap(rows.first);
  }

  Future<TaskGroupModel> createGroup({
    required int userId,
    required String name,
    String? description,
  }) async {
    final db = await _databaseHelper.database;
    final now = DateTime.now();
    final group = TaskGroupModel(
      userId: userId,
      name: name.trim(),
      description: description?.trim().isEmpty ?? true ? null : description?.trim(),
      createdAt: now,
      updatedAt: now,
    );

    final id = await db.insert(
      AppConstants.taskGroupsTable,
      group.toMap()..remove('id'),
    );

    return group.copyWith(id: id);
  }

  Future<void> updateGroup(TaskGroupModel group) async {
    final db = await _databaseHelper.database;
    await db.update(
      AppConstants.taskGroupsTable,
      group.copyWith(updatedAt: DateTime.now()).toMap()..remove('id'),
      where: 'id = ?',
      whereArgs: [group.id],
    );
  }

  Future<void> deleteGroup(int groupId) async {
    final db = await _databaseHelper.database;
    await db.delete(
      AppConstants.taskGroupsTable,
      where: 'id = ?',
      whereArgs: [groupId],
    );
  }
}