import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/task.dart';
import '../providers/todo_provider.dart';

class TaskItem extends StatelessWidget {
  final Task task;
  final VoidCallback? onEdit;

  const TaskItem({super.key, required this.task, this.onEdit});

  @override
  Widget build(BuildContext context) {
    final todoProvider = Provider.of<TodoProvider>(context, listen: false);

    return Dismissible(
      key: Key(task.id),
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      direction: DismissDirection.endToStart,
      onDismissed: (direction) {
        todoProvider.deleteTask(task.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${task.title} deleted')),
        );
      },
      child: Card(
        color: task.isCompleted ? Colors.green[100] : Colors.white,
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: ListTile(
          leading: Checkbox(
            value: task.isCompleted,
            activeColor: Colors.green[800],
            onChanged: (value) {
              todoProvider.toggleTaskStatus(task);
            },
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(5),
            ),
          ),
          title: Text(
            task.title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              decoration: task.isCompleted ? TextDecoration.lineThrough : null,
              color: task.isCompleted ? Colors.grey[700] : Colors.black87,
            ),
          ),
          subtitle: task.description.isNotEmpty
              ? Text(
                  task.description,
                  style: TextStyle(
                    color: task.isCompleted ? Colors.grey[600] : Colors.black54,
                  ),
                )
              : null,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.blue),
                onPressed: onEdit,
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () {
                  todoProvider.deleteTask(task.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${task.title} deleted')),
                  );
                },
              ),
            ],
          ),
          onTap: onEdit,
        ),
      ),
    );
  }
}
