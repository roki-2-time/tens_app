import 'package:flutter/material.dart';
import '../../data/database/app_database.dart';
import '../../data/repositories/project_repository.dart';

class ProjectsTab extends StatelessWidget {
  final ProjectRepository projectRepo;

  const ProjectsTab({super.key, required this.projectRepo});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Project>>(
      stream: projectRepo.watchProjects(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final projects = snapshot.data!;

        if (projects.isEmpty) {
          return const Center(child: Text('Нет проектов. Нажмите "+" чтобы создать.'));
        }

        return ListView.builder(
          itemCount: projects.length,
          itemBuilder: (context, index) {
            final p = projects[index];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: ListTile(
                title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(p.description ?? 'Активный проект'),
                trailing: Chip(label: Text(p.status)),
              ),
            );
          },
        );
      },
    );
  }
}