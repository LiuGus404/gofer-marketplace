import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/auth_provider.dart';
import '../../services/task_service.dart';
import '../../widgets/task_status_badge.dart';

class TaskListScreen extends ConsumerStatefulWidget {
  const TaskListScreen({super.key});

  @override
  ConsumerState<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends ConsumerState<TaskListScreen> {
  final _taskService = TaskService();
  List<Map<String, dynamic>> _tasks = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    setState(() => _loading = true);
    try {
      final username = ref.read(usernameProvider);
      if (username != null) {
        final tasks = await _taskService.myPostedTasks(username);
        setState(() {
          _tasks = tasks;
          _loading = false;
        });
      } else {
        setState(() => _loading = false);
      }
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Tasks')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _tasks.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.task_outlined,
                          size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Text('No tasks yet'),
                      const SizedBox(height: 8),
                      FilledButton(
                        onPressed: () => context.push('/tasks/create'),
                        child: const Text('Post Your First Task'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadTasks,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _tasks.length,
                    itemBuilder: (context, index) {
                      final task = _tasks[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          title: Text(task['title'] ?? ''),
                          subtitle: Text(
                            '${task['task_type'] ?? ''} · ${task['budget'] ?? ''}',
                          ),
                          trailing: TaskStatusBadge(
                              status: task['status'] ?? 'open'),
                          onTap: () =>
                              context.push('/tasks/${task['number']}'),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
