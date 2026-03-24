import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/password_helper.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/auth_repository.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError(
    'SharedPreferences must be overridden in main.dart',
  ),
);

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

final authViewModelProvider = StateNotifierProvider<AuthViewModel, AuthState>((
  ref,
) {
  return AuthViewModel(
    authRepository: ref.read(authRepositoryProvider),
    sharedPreferences: ref.read(sharedPreferencesProvider),
  );
});

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthState {
  const AuthState({required this.status, this.user, this.errorMessage});

  factory AuthState.initial() => const AuthState(status: AuthStatus.initial);

  final AuthStatus status;
  final UserModel? user;
  final String? errorMessage;

  bool get isBusy => status == AuthStatus.loading;

  AuthState copyWith({
    AuthStatus? status,
    UserModel? user,
    bool clearUser = false,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: clearUser ? null : (user ?? this.user),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class AuthViewModel extends StateNotifier<AuthState> {
  AuthViewModel({
    required AuthRepository authRepository,
    required SharedPreferences sharedPreferences,
  }) : _authRepository = authRepository,
       _sharedPreferences = sharedPreferences,
       super(AuthState.initial()) {
    _restoreSession();
  }

  final AuthRepository _authRepository;
  final SharedPreferences _sharedPreferences;

  Future<void> _restoreSession() async {
    state = state.copyWith(status: AuthStatus.loading, clearError: true);

    try {
      final userId = _sharedPreferences.getInt(AppConstants.sessionUserIdKey);

      if (userId == null) {
        state = state.copyWith(
          status: AuthStatus.unauthenticated,
          clearUser: true,
        );
        return;
      }

      final user = await _authRepository.getUserById(userId);
      if (user == null) {
        await _sharedPreferences.remove(AppConstants.sessionUserIdKey);
        state = state.copyWith(
          status: AuthStatus.unauthenticated,
          clearUser: true,
        );
        return;
      }

      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: user,
        clearError: true,
      );
    } catch (_) {
      state = state.copyWith(
        status: AuthStatus.error,
        clearUser: true,
        errorMessage: 'No fue posible abrir la base de datos local',
      );
    }
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
  }) async {
    state = state.copyWith(status: AuthStatus.loading, clearError: true);

    try {
      final normalizedEmail = email.trim().toLowerCase();
      final existingUser = await _authRepository.getUserByEmail(
        normalizedEmail,
      );
      if (existingUser != null) {
        state = state.copyWith(
          status: AuthStatus.error,
          errorMessage: 'Ya existe una cuenta con este correo',
        );
        return false;
      }

      final salt = PasswordHelper.generateSalt();
      final user = await _authRepository.createUser(
        UserModel(
          name: name.trim(),
          email: normalizedEmail,
          passwordHash: PasswordHelper.hashPassword(
            password: password,
            salt: salt,
          ),
          salt: salt,
          createdAt: DateTime.now(),
        ),
      );

      await _sharedPreferences.setInt(AppConstants.sessionUserIdKey, user.id!);
      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: user,
        clearError: true,
      );
      return true;
    } catch (_) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'No fue posible registrar el usuario en la base local',
      );
      return false;
    }
  }

  Future<bool> login({required String email, required String password}) async {
    state = state.copyWith(status: AuthStatus.loading, clearError: true);

    try {
      final user = await _authRepository.getUserByEmail(
        email.trim().toLowerCase(),
      );
      if (user == null) {
        state = state.copyWith(
          status: AuthStatus.error,
          errorMessage: 'No encontramos una cuenta con este correo',
        );
        return false;
      }

      final passwordHash = PasswordHelper.hashPassword(
        password: password,
        salt: user.salt,
      );
      if (passwordHash != user.passwordHash) {
        state = state.copyWith(
          status: AuthStatus.error,
          errorMessage: 'La contraseña no es correcta',
        );
        return false;
      }

      await _sharedPreferences.setInt(AppConstants.sessionUserIdKey, user.id!);
      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: user,
        clearError: true,
      );
      return true;
    } catch (_) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'No fue posible acceder a la base de datos local',
      );
      return false;
    }
  }

  Future<void> logout() async {
    await _sharedPreferences.remove(AppConstants.sessionUserIdKey);
    state = state.copyWith(
      status: AuthStatus.unauthenticated,
      clearUser: true,
      clearError: true,
    );
  }

  void clearTransientError() {
    if (state.status == AuthStatus.error) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        clearError: true,
      );
    }
  }
}
