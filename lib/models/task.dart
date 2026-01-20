import 'package:uuid/uuid.dart';

class Task {
  final String id;
  String title;
  String description;
  DateTime date;
  bool isCompleted;

  Task({
    String? id,
    required this.title,
    this.description = '',
    required this.date,
    this.isCompleted = false,
  }) : id = id ?? const Uuid().v4();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'date': date.toIso8601String(),
      'isCompleted': isCompleted,
    };
  }

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'],
      title: json['title'],
      description: json['description'] ?? '',
      date: DateTime.parse(json['date']),
      isCompleted: json['isCompleted'] ?? false,
    );
  }

  Task copyWith({
    String? title,
    String? description,
    DateTime? date,
    bool? isCompleted,
  }) {
    return Task(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      date: date ?? this.date,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}
