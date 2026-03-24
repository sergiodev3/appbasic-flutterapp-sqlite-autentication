import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/validators.dart';
import '../../../data/models/task_group_model.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/task_group_viewmodel.dart';
import 'widgets/empty_home_widget.dart';
import 'widgets/task_group_card.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = ref.read(authViewModelProvider).user?.id;
      if (userId != null) {
        ref.read(taskGroupViewModelProvider.notifier).loadGroups(userId);
      }
    });
  }

  Future<void> _openGroupSheet({TaskGroupModel? group}) async {
    final result = await showModalBottomSheet<_GroupFormResult>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _GroupFormSheet(group: group),
    );

    if (result == null) {
      return;
    }

    final user = ref.read(authViewModelProvider).user;
    if (user?.id == null) {
      return;
    }

    if (group == null) {
      await ref
          .read(taskGroupViewModelProvider.notifier)
          .createGroup(
            userId: user!.id!,
            name: result.name,
            description: result.description,
          );
      return;
    }

    await ref
        .read(taskGroupViewModelProvider.notifier)
        .updateGroup(
          group.copyWith(
            name: result.name,
            description: result.description,
            clearDescription: result.description == null,
          ),
        );
  }

  Future<void> _deleteGroup(TaskGroupModel group) async {
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Eliminar checklist'),
            content: Text('Se eliminará "${group.name}" y todas sus tareas.'),
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
        .read(taskGroupViewModelProvider.notifier)
        .deleteGroup(groupId: group.id!, userId: group.userId);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authViewModelProvider);
    final groupsState = ref.watch(taskGroupViewModelProvider);
    final user = authState.user;

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openGroupSheet,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nuevo checklist'),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            final userId = user?.id;
            if (userId != null) {
              await ref
                  .read(taskGroupViewModelProvider.notifier)
                  .loadGroups(userId);
            }
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 18, 24, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Hola, ${user?.name ?? 'usuario'}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineMedium
                                      ?.copyWith(fontWeight: FontWeight.w800),
                                ),
                                const Gap(6),
                                Text(
                                  'Organiza grupos y marca tareas individuales como completadas.',
                                  style: Theme.of(context).textTheme.bodyLarge
                                      ?.copyWith(color: AppColors.textMuted),
                                ),
                              ],
                            ),
                          ),
                          IconButton.filledTonal(
                            onPressed: () async {
                              await ref
                                  .read(authViewModelProvider.notifier)
                                  .logout();
                              if (context.mounted) {
                                context.go('/');
                              }
                            },
                            icon: const Icon(Icons.logout_rounded),
                          ),
                        ],
                      ),
                      const Gap(20),
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF183153), Color(0xFF1F6FEB)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(28),
                        ),
                        child: Row(
                          children: [
                            const Expanded(child: _SummaryCopy()),
                            Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(22),
                              ),
                              child: const Icon(
                                Icons.checklist_rtl_rounded,
                                color: Colors.white,
                                size: 34,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Gap(18),
                    ],
                  ),
                ),
              ),
              if (groupsState.status == LoadStatus.loading)
                const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (groupsState.groups.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: EmptyHomeWidget(onCreatePressed: _openGroupSheet),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 120),
                  sliver: SliverGrid(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final group = groupsState.groups[index];
                      return TaskGroupCard(
                        group: group,
                        onTap: () => context.go('/home/checklist/${group.id}'),
                        onEdit: () => _openGroupSheet(group: group),
                        onDelete: () => _deleteGroup(group),
                      );
                    }, childCount: groupsState.groups.length),
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 360,
                          mainAxisExtent: 230,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryCopy extends StatelessWidget {
  const _SummaryCopy();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tus listas viven en SQLite',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
        const Gap(8),
        Text(
          'Puedes crear grupos, editar nombres y gestionar tareas individuales con persistencia local.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.white.withValues(alpha: 0.86),
            height: 1.4,
          ),
        ),
      ],
    );
  }
}

class _GroupFormResult {
  const _GroupFormResult({required this.name, this.description});

  final String name;
  final String? description;
}

class _GroupFormSheet extends StatefulWidget {
  const _GroupFormSheet({this.group});

  final TaskGroupModel? group;

  @override
  State<_GroupFormSheet> createState() => _GroupFormSheetState();
}

class _GroupFormSheetState extends State<_GroupFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.group?.name ?? '');
    _descriptionController = TextEditingController(
      text: widget.group?.description ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    Navigator.of(context).pop(
      _GroupFormResult(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, bottomInset + 16),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.group == null ? 'Nuevo checklist' : 'Editar checklist',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Gap(8),
                Text(
                  'Agrupa tareas relacionadas para mantenerlas bajo el mismo checklist.',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
                ),
                const Gap(22),
                TextFormField(
                  controller: _nameController,
                  validator: (value) => Validators.shortText(
                    value,
                    label: 'El nombre del checklist',
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Nombre del checklist',
                  ),
                ),
                const Gap(16),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Descripción opcional',
                    hintText:
                        'Ej. pendientes del trabajo o compras de la semana',
                  ),
                ),
                const Gap(24),
                FilledButton.icon(
                  onPressed: _submit,
                  icon: const Icon(Icons.save_rounded),
                  label: Text(
                    widget.group == null
                        ? 'Crear checklist'
                        : 'Guardar cambios',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
