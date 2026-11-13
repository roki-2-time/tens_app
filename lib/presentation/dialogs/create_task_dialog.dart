import 'package:flutter/material.dart';
import 'package:drift/drift.dart' as drift;
import '../../data/database/app_database.dart';
import '../../data/repositories/project_repository.dart';

void showCreateTaskDialog(BuildContext context, AppDatabase database, ProjectRepository projectRepo) {
  final titleController = TextEditingController();
  int? selectedProjectId;

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Новая задача'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: titleController,
            decoration: const InputDecoration(labelText: 'Название задачи'),
          ),
          const SizedBox(height: 12),
          StreamBuilder<List<Project>>(
            stream: projectRepo.watchProjects(),
            builder: (context, snapshot) {
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Text('Сначала создайте проект!');
              }
              final projects = snapshot.data!;
              return DropdownButtonFormField<int>(
                decoration: const InputDecoration(labelText: 'Проект'),
                items: projects.map((p) => DropdownMenuItem(
                  value: p.id,
                  child: Text(p.name),
                )).toList(),
                onChanged: (val) => selectedProjectId = val,
              );
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Отмена'),
        ),
        ElevatedButton(
          onPressed: () async {
            if (titleController.text.isNotEmpty && selectedProjectId != null) {
              await database.into(database.tasks).insert(
                TasksCompanion.insert(
                  title: titleController.text,
                  projectId: selectedProjectId!,
                  status: const drift.Value('todo'),
                  priority: const drift.Value('medium'),
                  createdAt: DateTime.now(),
                  updatedAt: DateTime.now(),
                ),
              );
              if (context.mounted) Navigator.pop(context);
            }
          },
          child: const Text('Создать'),
        ),
      ],
    ),
  );
}