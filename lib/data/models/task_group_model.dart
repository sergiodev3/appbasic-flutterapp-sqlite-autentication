class TaskGroupModel {
  const TaskGroupModel({
    this.id,
    required this.userId,
    required this.name,
    this.description,
    required this.createdAt,
    required this.updatedAt,
    this.totalTasks = 0,
    this.completedTasks = 0,
  });

  final int? id;
  final int userId;
  final String name;
  final String? description;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int totalTasks;
  final int completedTasks;

  double get progress => totalTasks == 0 ? 0 : completedTasks / totalTasks;

  TaskGroupModel copyWith({
    int? id,
    int? userId,
    String? name,
    String? description,
    bool clearDescription = false,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? totalTasks,
    int? completedTasks,
  }) {
    return TaskGroupModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      description: clearDescription ? null : (description ?? this.description),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      totalTasks: totalTasks ?? this.totalTasks,
      completedTasks: completedTasks ?? this.completedTasks,
    );
  }

  factory TaskGroupModel.fromMap(Map<String, Object?> map) {
    return TaskGroupModel(
      id: map['id'] as int?,
      userId: map['user_id'] as int,
      name: map['name'] as String,
      description: map['description'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      totalTasks: (map['total_tasks'] as int?) ?? 0,
      completedTasks: (map['completed_tasks'] as int?) ?? 0,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'description': description,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}