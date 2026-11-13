import 'package:flutter/material.dart';
import '../../data/repositories/project_repository.dart';

void showCreateProjectDialog(BuildContext context, ProjectRepository projectRepo) {
  final nameController = TextEditingController();
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Новый проект'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
        controller: nameController,
        decoration: InputDecoration(labelText: 'Название проекта'),
      ),
           TextField(
        controller: nameController,
        decoration: InputDecoration(labelText: 'Исполнитель'),
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
            if (nameController.text.isNotEmpty) {
              await projectRepo.createProject(name: nameController.text);
              if (context.mounted) Navigator.pop(context);
            }
          },
          child: const Text('Создать'),
        ),

      ],
    ),
  );
}