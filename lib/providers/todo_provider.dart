import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/task.dart';

class TodoProvider with ChangeNotifier {
  List<Task> _tasks = [];
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = true;

  TodoProvider() {
    _loadTasks();
  }

  List<Task> get tasks {
    return _tasks.where((task) {
      return task.date.year == _selectedDate.year &&
          task.date.month == _selectedDate.month &&
          task.date.day == _selectedDate.day;
    }).toList();
  }

  List<Task> get allTasks => _tasks;
  bool get isLoading => _isLoading;
  DateTime get selectedDate => _selectedDate;

  void setDate(DateTime date) {
    _selectedDate = date;
    notifyListeners();
  }

  Future<void> _loadTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final tasksString = prefs.getString('tasks');
    if (tasksString != null) {
      final List<dynamic> tasksJson = json.decode(tasksString);
      _tasks = tasksJson.map((json) => Task.fromJson(json)).toList();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> _saveTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final tasksJson = _tasks.map((task) => task.toJson()).toList();
    await prefs.setString('tasks', json.encode(tasksJson));
  }

  void addTask(String title, String description) {
    final newTask = Task(
      title: title,
      description: description,
      date: _selectedDate,
    );
    _tasks.add(newTask);
    _saveTasks();
    notifyListeners();
  }

  void updateTask(Task task) {
    final index = _tasks.indexWhere((t) => t.id == task.id);
    if (index != -1) {
      _tasks[index] = task;
      _saveTasks();
      notifyListeners();
    }
  }

  void deleteTask(String id) {
    _tasks.removeWhere((task) => task.id == id);
    _saveTasks();
    notifyListeners();
  }

  void toggleTaskStatus(Task task) {
    final index = _tasks.indexWhere((t) => t.id == task.id);
    if (index != -1) {
      _tasks[index] = task.copyWith(isCompleted: !task.isCompleted);
      _saveTasks();
      notifyListeners();
    }
  }

  /// Returns 0 if no tasks
  /// Returns 1 if has uncompleted tasks
  /// Returns 2 if all tasks are completed
  int getTaskStatusForDate(DateTime date) {
    final tasksForDate = _tasks.where((task) {
      return task.date.year == date.year &&
          task.date.month == date.month &&
          task.date.day == date.day;
    }).toList();

    if (tasksForDate.isEmpty) return 0;
    if (tasksForDate.any((t) => !t.isCompleted)) return 1;
    return 2;
  }

  /// Returns count of tasks for a date (for the arrow counter? User said "number of tasks out of view")
  /// User said "number of tasks out of view". This could mean sum of tasks on ALL days out of view?
  /// OR number of days with tasks?
  /// "add a white arrow with the number of tasks out of view behind the arrow"
  /// "Clicking the arrow should locate to the nearest out of view task date"
  /// Likely means: Count of tasks that are currently not visible.
  int getTaskCountForDate(DateTime date) {
     return _tasks.where((task) {
      return task.date.year == date.year &&
          task.date.month == date.month &&
          task.date.day == date.day;
    }).length;
  }
}
