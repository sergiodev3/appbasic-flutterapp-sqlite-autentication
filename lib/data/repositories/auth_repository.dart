import '../database/database_helper.dart';
import '../models/user_model.dart';
import '../../core/constants/app_constants.dart';

class AuthRepository {
  AuthRepository({DatabaseHelper? databaseHelper})
      : _databaseHelper = databaseHelper ?? DatabaseHelper.instance;

  final DatabaseHelper _databaseHelper;

  Future<UserModel?> getUserByEmail(String email) async {
    final db = await _databaseHelper.database;
    final rows = await db.query(
      AppConstants.usersTable,
      where: 'email = ?',
      whereArgs: [email.trim().toLowerCase()],
      limit: 1,
    );

    if (rows.isEmpty) {
      return null;
    }

    return UserModel.fromMap(rows.first);
  }

  Future<UserModel?> getUserById(int id) async {
    final db = await _databaseHelper.database;
    final rows = await db.query(
      AppConstants.usersTable,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (rows.isEmpty) {
      return null;
    }

    return UserModel.fromMap(rows.first);
  }

  Future<UserModel> createUser(UserModel user) async {
    final db = await _databaseHelper.database;
    final id = await db.insert(AppConstants.usersTable, user.toMap()..remove('id'));
    return user.copyWith(id: id);
  }
}