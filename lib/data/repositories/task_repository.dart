import '../../core/constants/app_constants.dart';
import 'package:sqflite/sqflite.dart';

import '../database/database_helper.dart';
import '../models/task_model.dart';

class TaskRepository {
  TaskRepository({DatabaseHelper? databaseHelper})
    : _databaseHelper = databaseHelper ?? DatabaseHelper.instance;

  final DatabaseHelper _databaseHelper;

  Future<List<TaskModel>> getTasksByGroup(int groupId) async {
    final db = await _databaseHelper.database;
    final rows = await db.query(
      AppConstants.tasksTable,
      where: 'group_id = ?',
      whereArgs: [groupId],
      orderBy: 'position ASC, id ASC',
    );

    return rows.map(TaskModel.fromMap).toList();
  }

  Future<TaskModel> createTask({
    required int groupId,
    required String title,
  }) async {
    final db = await _databaseHelper.database;
    final maxPosition =
        Sqflite.firstIntValue(
          await db.rawQuery(
            'SELECT MAX(position) FROM ${AppConstants.tasksTable} WHERE group_id = ?',
            [groupId],
          ),
        ) ??
        -1;

    final now = DateTime.now();
    final task = TaskModel(
      groupId: groupId,
      title: title.trim(),
      isCompleted: false,
      position: maxPosition + 1,
      createdAt: now,
      updatedAt: now,
    );

    final id = await db.insert(
      AppConstants.tasksTable,
      task.toMap()..remove('id'),
    );
    return task.copyWith(id: id);
  }

  Future<void> updateTask(TaskModel task) async {
    final db = await _databaseHelper.database;
    await db.update(
      AppConstants.tasksTable,
      task.copyWith(updatedAt: DateTime.now()).toMap()..remove('id'),
      where: 'id = ?',
      whereArgs: [task.id],
    );
  }

  Future<void> deleteTask(int taskId) async {
    final db = await _databaseHelper.database;
    await db.delete(
      AppConstants.tasksTable,
      where: 'id = ?',
      whereArgs: [taskId],
    );
  }
}
