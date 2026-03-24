import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/task_group_model.dart';
import '../../data/models/task_model.dart';
import '../../data/repositories/task_group_repository.dart';
import '../../data/repositories/task_repository.dart';
import 'task_group_viewmodel.dart';

final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  return TaskRepository();
});

final taskViewModelProvider =
    StateNotifierProvider.family<TaskViewModel, TaskState, int>((ref, groupId) {
  return TaskViewModel(
    taskRepository: ref.read(taskRepositoryProvider),
    taskGroupRepository: ref.read(taskGroupRepositoryProvider),
    onRefreshGroups: (userId) => ref.read(taskGroupViewModelProvider.notifier).loadGroups(userId),
    groupId: groupId,
  )..initialize();
});

class TaskState {
  const TaskState({
    required this.status,
    this.group,
    this.tasks = const [],
    this.errorMessage,
  });

  factory TaskState.initial() => const TaskState(status: LoadStatus.initial);

  final LoadStatus status;
  final TaskGroupModel? group;
  final List<TaskModel> tasks;
  final String? errorMessage;

  TaskState copyWith({
    LoadStatus? status,
    TaskGroupModel? group,
    bool clearGroup = false,
    List<TaskModel>? tasks,
    String? errorMessage,
    bool clearError = false,
  }) {
    return TaskState(
      status: status ?? this.status,
      group: clearGroup ? null : (group ?? this.group),
      tasks: tasks ?? this.tasks,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class TaskViewModel extends StateNotifier<TaskState> {
  TaskViewModel({
    required TaskRepository taskRepository,
    required TaskGroupRepository taskGroupRepository,
    required Future<void> Function(int userId) onRefreshGroups,
    required int groupId,
  })  : _taskRepository = taskRepository,
        _taskGroupRepository = taskGroupRepository,
        _onRefreshGroups = onRefreshGroups,
        _groupId = groupId,
        super(TaskState.initial());

  final TaskRepository _taskRepository;
  final TaskGroupRepository _taskGroupRepository;
  final Future<void> Function(int userId) _onRefreshGroups;
  final int _groupId;

  Future<void> initialize() async {
    state = state.copyWith(status: LoadStatus.loading, clearError: true);

    try {
      final group = await _taskGroupRepository.getGroupById(_groupId);
      if (group == null) {
        state = state.copyWith(
          status: LoadStatus.error,
          errorMessage: 'El checklist ya no existe',
          clearGroup: true,
        );
        return;
      }

      final tasks = await _taskRepository.getTasksByGroup(_groupId);
      state = state.copyWith(status: LoadStatus.loaded, group: group, tasks: tasks);
    } catch (_) {
      state = state.copyWith(
        status: LoadStatus.error,
        errorMessage: 'No fue posible cargar las tareas',
      );
    }
  }

  Future<void> addTask(String title) async {
    await _taskRepository.createTask(groupId: _groupId, title: title);
    await _refresh();
  }

  Future<void> updateTask(TaskModel task, {String? title, bool? isCompleted}) async {
    await _taskRepository.updateTask(
      task.copyWith(
        title: title?.trim(),
        isCompleted: isCompleted,
      ),
    );
    await _refresh();
  }

  Future<void> deleteTask(int taskId) async {
    await _taskRepository.deleteTask(taskId);
    await _refresh();
  }

  Future<void> _refresh() async {
    await initialize();
    final userId = state.group?.userId;
    if (userId != null) {
      await _onRefreshGroups(userId);
    }
  }
}