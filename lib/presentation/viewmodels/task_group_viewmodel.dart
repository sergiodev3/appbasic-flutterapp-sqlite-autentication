import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/task_group_model.dart';
import '../../data/repositories/task_group_repository.dart';

final taskGroupRepositoryProvider = Provider<TaskGroupRepository>((ref) {
  return TaskGroupRepository();
});

final taskGroupViewModelProvider =
    StateNotifierProvider<TaskGroupViewModel, TaskGroupState>((ref) {
  return TaskGroupViewModel(ref.read(taskGroupRepositoryProvider));
});

enum LoadStatus { initial, loading, loaded, error }

class TaskGroupState {
  const TaskGroupState({
    required this.status,
    this.groups = const [],
    this.errorMessage,
  });

  factory TaskGroupState.initial() => const TaskGroupState(status: LoadStatus.initial);

  final LoadStatus status;
  final List<TaskGroupModel> groups;
  final String? errorMessage;

  TaskGroupState copyWith({
    LoadStatus? status,
    List<TaskGroupModel>? groups,
    String? errorMessage,
    bool clearError = false,
  }) {
    return TaskGroupState(
      status: status ?? this.status,
      groups: groups ?? this.groups,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class TaskGroupViewModel extends StateNotifier<TaskGroupState> {
  TaskGroupViewModel(this._repository) : super(TaskGroupState.initial());

  final TaskGroupRepository _repository;

  Future<void> loadGroups(int userId) async {
    state = state.copyWith(status: LoadStatus.loading, clearError: true);

    try {
      final groups = await _repository.getGroupsByUser(userId);
      state = state.copyWith(status: LoadStatus.loaded, groups: groups);
    } catch (_) {
      state = state.copyWith(
        status: LoadStatus.error,
        errorMessage: 'No fue posible cargar los checklist',
      );
    }
  }

  Future<void> createGroup({
    required int userId,
    required String name,
    String? description,
  }) async {
    await _repository.createGroup(userId: userId, name: name, description: description);
    await loadGroups(userId);
  }

  Future<void> updateGroup(TaskGroupModel group) async {
    await _repository.updateGroup(group);
    await loadGroups(group.userId);
  }

  Future<void> deleteGroup({required int groupId, required int userId}) async {
    await _repository.deleteGroup(groupId);
    await loadGroups(userId);
  }
}