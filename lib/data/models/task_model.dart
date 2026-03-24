class TaskModel {
  const TaskModel({
    this.id,
    required this.groupId,
    required this.title,
    required this.isCompleted,
    required this.position,
    required this.createdAt,
    required this.updatedAt,
  });

  final int? id;
  final int groupId;
  final String title;
  final bool isCompleted;
  final int position;
  final DateTime createdAt;
  final DateTime updatedAt;

  TaskModel copyWith({
    int? id,
    int? groupId,
    String? title,
    bool? isCompleted,
    int? position,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TaskModel(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      title: title ?? this.title,
      isCompleted: isCompleted ?? this.isCompleted,
      position: position ?? this.position,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory TaskModel.fromMap(Map<String, Object?> map) {
    return TaskModel(
      id: map['id'] as int?,
      groupId: map['group_id'] as int,
      title: map['title'] as String,
      isCompleted: (map['is_completed'] as int) == 1,
      position: map['position'] as int,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'group_id': groupId,
      'title': title,
      'is_completed': isCompleted ? 1 : 0,
      'position': position,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}