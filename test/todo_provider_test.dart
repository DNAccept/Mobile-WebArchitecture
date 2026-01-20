import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:todo_app/providers/todo_provider.dart';
import 'package:todo_app/models/task.dart';

void main() {
  group('TodoProvider', () {
    test('add task adds a task to the list', () async {
      SharedPreferences.setMockInitialValues({});
      final provider = TodoProvider();
      
      // Wait for load (though mock is synchronous usually, provider is async load)
      // Since _loadTasks is called in constructor and is async, we might need to wait a bit
      // But for testing, we should probably await something.
      // However, TodoProvider starts loading immediately.
      // We can just add a task and see.
      
      provider.addTask('Test Task', 'Description');
      
      expect(provider.tasks.length, 1);
      expect(provider.tasks.first.title, 'Test Task');
      expect(provider.tasks.first.date.day, DateTime.now().day);
    });

    test('toggle task status updates the task', () {
      SharedPreferences.setMockInitialValues({});
      final provider = TodoProvider();
      provider.addTask('Test Task', 'Description');
      
      final task = provider.tasks.first;
      provider.toggleTaskStatus(task);
      
      expect(provider.tasks.first.isCompleted, true);
    });

    test('delete task removes it from the list', () {
      SharedPreferences.setMockInitialValues({});
      final provider = TodoProvider();
      provider.addTask('Test Task', 'Description');
      
      final task = provider.tasks.first;
      provider.deleteTask(task.id);
      
      expect(provider.tasks.isEmpty, true);
    });
    
     test('filter by date works', () {
      SharedPreferences.setMockInitialValues({});
      final provider = TodoProvider();
      provider.addTask('Today Task', 'Description');
      
      // Change date
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      provider.setDate(tomorrow);
      
      expect(provider.tasks.isEmpty, true);
      
      provider.addTask('Tomorrow Task', 'Description');
      expect(provider.tasks.length, 1);
      expect(provider.tasks.first.title, 'Tomorrow Task');
    });
  });
}
