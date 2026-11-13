import 'package:flutter/material.dart';
import '../../data/database/app_database.dart';
import '../../data/repositories/task_repository.dart';

class TasksTab extends StatelessWidget {
  final TaskRepository taskRepo;

  const TasksTab({super.key, required this.taskRepo});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Task>>(
      stream: taskRepo.watchActiveTasks(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final tasks = snapshot.data!;

        if (tasks.isEmpty) {
          return const Center(child: Text('Список задач пуст. Нажмите "+" чтобы добавить.'));
        }

        return ListView.builder(
          itemCount: tasks.length,
          itemBuilder: (context, index) {
            final t = tasks[index];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: ListTile(
                leading: const Icon(Icons.task_alt, color: Colors.indigo),
                title: Text(t.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text('Приоритет: ${t.priority}'),
                    const SizedBox(height: 6),
                    DropdownButton<String>(
                      value: t.status,
                      isDense: true,
                      items: const [
                        DropdownMenuItem(value: 'todo', child: Text('К выполнению (todo)')),
                        DropdownMenuItem(value: 'inProgress', child: Text('В процессе (inProgress)')),
                        DropdownMenuItem(value: 'done', child: Text('Готово (done)')),
                      ],
                      onChanged: (newStatus) {
                        if (newStatus != null) {
                          taskRepo.updateTaskStatus(t.id, newStatus);
                        }
                      },
                    ),
                  ],
                ),
                isThreeLine: true,
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => taskRepo.softDeleteTask(t.id),
                ),
              ),
            );
          },
        );
      },
    );
  }
}