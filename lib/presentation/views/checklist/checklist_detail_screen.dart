import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/models/task_model.dart';
import '../../viewmodels/task_group_viewmodel.dart';
import '../../viewmodels/task_viewmodel.dart';
import 'widgets/task_form_dialog.dart';
import 'widgets/task_item_widget.dart';

class ChecklistDetailScreen extends ConsumerWidget {
  const ChecklistDetailScreen({super.key, required this.groupId});

  final int groupId;

  Future<void> _showTaskForm(
    BuildContext context,
    WidgetRef ref, {
    TaskModel? task,
  }) async {
    final title = await showDialog<String>(
      context: context,
      builder: (context) => TaskFormDialog(initialValue: task?.title),
    );

    if (title == null || title.isEmpty) {
      return;
    }

    final notifier = ref.read(taskViewModelProvider(groupId).notifier);
    if (task == null) {
      await notifier.addTask(title);
      return;
    }

    await notifier.updateTask(task, title: title);
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    TaskModel task,
  ) async {
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Eliminar tarea'),
            content: Text('Se eliminará "${task.title}" del checklist.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Eliminar'),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmed) {
      return;
    }

    await ref
        .read(taskViewModelProvider(groupId).notifier)
        .deleteTask(task.id!);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(taskViewModelProvider(groupId));
    final group = state.group;

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showTaskForm(context, ref),
        icon: const Icon(Icons.add_task_rounded),
        label: const Text('Agregar tarea'),
      ),
      appBar: AppBar(title: Text(group?.name ?? 'Checklist')),
      body: SafeArea(
        child: Builder(
          builder: (context) {
            if (state.status == LoadStatus.loading ||
                state.status == LoadStatus.initial) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state.status == LoadStatus.error) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    state.errorMessage ??
                        'No fue posible cargar este checklist',
                  ),
                ),
              );
            }

            return ListView(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 120),
              children: [
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        group?.name ?? 'Checklist',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const Gap(8),
                      Text(
                        group?.description?.isNotEmpty == true
                            ? group!.description!
                            : 'Agrega tareas y desliza cada fila para editar o eliminar.',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                      const Gap(20),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          _StatusBadge(label: '${state.tasks.length} tareas'),
                          _StatusBadge(
                            label:
                                '${state.tasks.where((task) => task.isCompleted).length} completadas',
                            highlight: true,
                          ),
                        ],
                      ),
                    ],
                  ),
                ).animate().fadeIn(duration: 280.ms).slideY(begin: 0.06, end: 0),
                const Gap(20),
                if (state.tasks.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: AppColors.paper,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.inbox_rounded,
                          size: 48,
                          color: AppColors.textMuted,
                        ),
                        const Gap(14),
                        Text(
                          'Aún no hay tareas en este checklist',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w800),
                          textAlign: TextAlign.center,
                        ),
                        const Gap(8),
                        Text(
                          'Empieza agregando la primera tarea desde el botón inferior.',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: AppColors.textMuted),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                else
                  ...state.tasks.indexed.map(
                    (entry) =>
                        TaskItemWidget(
                          key: ValueKey(entry.$2.id),
                          task: entry.$2,
                          onChanged: (value) => ref
                              .read(taskViewModelProvider(groupId).notifier)
                              .updateTask(entry.$2, isCompleted: value),
                          onEdit: () =>
                              _showTaskForm(context, ref, task: entry.$2),
                          onDelete: () =>
                              _confirmDelete(context, ref, entry.$2),
                        ).animate().fadeIn(
                          delay: Duration(milliseconds: 60 * entry.$1),
                        ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label, this.highlight = false});

  final String label;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: highlight
            ? AppColors.mint.withValues(alpha: 0.14)
            : AppColors.paper,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        label,
        style: Theme.of(
          context,
        ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }
}
