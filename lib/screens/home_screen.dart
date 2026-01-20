import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/todo_provider.dart';
import '../widgets/date_selector.dart';
import '../widgets/task_item.dart';
import '../models/task.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final todoProvider = Provider.of<TodoProvider>(context);

    void _showAddEditTaskDialog(BuildContext context, {Task? task}) {
      final titleController = TextEditingController(text: task?.title ?? '');
      final descriptionController =
          TextEditingController(text: task?.description ?? '');

      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text(task == null ? 'Add Task' : 'Edit Task'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Title'),
                  autofocus: true,
                ),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(labelText: 'Description'),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (titleController.text.isNotEmpty) {
                    if (task == null) {
                      Provider.of<TodoProvider>(context, listen: false)
                          .addTask(
                        titleController.text,
                        descriptionController.text,
                      );
                    } else {
                      Provider.of<TodoProvider>(context, listen: false)
                          .updateTask(
                        task.copyWith(
                          title: titleController.text,
                          description: descriptionController.text,
                        ),
                      );
                    }
                    Navigator.pop(context);
                  }
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const DateSelector(),
            Expanded(
              child: todoProvider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : todoProvider.tasks.isEmpty
                      ? const Center(
                          child: Text(
                            'No tasks for this day',
                            style: TextStyle(fontSize: 18, color: Colors.grey),
                          ),
                        )
                      : ListView.builder(
                          itemCount: todoProvider.tasks.length,
                          padding: const EdgeInsets.only(bottom: 80),
                          itemBuilder: (context, index) {
                            final task = todoProvider.tasks[index];
                            return TaskItem(
                              task: task,
                              onEdit: () => _showAddEditTaskDialog(context, task: task),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blue,
        onPressed: () => _showAddEditTaskDialog(context),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
