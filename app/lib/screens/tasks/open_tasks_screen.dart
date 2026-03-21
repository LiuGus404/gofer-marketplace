import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../services/task_service.dart';
import '../../widgets/task_status_badge.dart';

class OpenTasksScreen extends StatefulWidget {
  const OpenTasksScreen({super.key});

  @override
  State<OpenTasksScreen> createState() => _OpenTasksScreenState();
}

class _OpenTasksScreenState extends State<OpenTasksScreen> {
  final _taskService = TaskService();
  List<Map<String, dynamic>> _tasks = [];
  bool _loading = true;
  String? _selectedType;

  static const _types = [
    'code',
    'research',
    'writing',
    'design',
    'web-scraping',
    'automation',
    'game-dev',
    'translation',
    'video',
  ];

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    setState(() => _loading = true);
    try {
      final tasks = await _taskService.listTasks(
        status: 'open',
        type: _selectedType,
      );
      setState(() {
        _tasks = tasks;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Open Tasks'),
      ),
      body: Column(
        children: [
          // Type filter chips
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _FilterChip(
                  label: 'All',
                  selected: _selectedType == null,
                  onTap: () {
                    setState(() => _selectedType = null);
                    _loadTasks();
                  },
                ),
                ..._types.map((t) => _FilterChip(
                      label: t,
                      selected: _selectedType == t,
                      onTap: () {
                        setState(() => _selectedType = t);
                        _loadTasks();
                      },
                    )),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Task list
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _tasks.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.search_off,
                                size: 56, color: AppColors.textMuted),
                            const SizedBox(height: 16),
                            Text(
                              'No open tasks found',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(color: AppColors.textMuted),
                            ),
                            const SizedBox(height: 8),
                            const Text('Check back later or post a new task'),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadTasks,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _tasks.length,
                          itemBuilder: (context, index) {
                            final task = _tasks[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 10),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () => context
                                    .push('/tasks/${task['number']}'),
                                child: Padding(
                                  padding: const EdgeInsets.all(14),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              task['title'] ?? '',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 15,
                                              ),
                                            ),
                                          ),
                                          TaskStatusBadge(
                                              status:
                                                  task['status'] ?? 'open'),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          if (task['task_type'] != null) ...[
                                            Icon(Icons.label_outline,
                                                size: 14,
                                                color: AppColors.textMuted),
                                            const SizedBox(width: 4),
                                            Text(
                                              task['task_type'],
                                              style: TextStyle(
                                                  fontSize: 12,
                                                  color:
                                                      AppColors.textMuted),
                                            ),
                                            const SizedBox(width: 12),
                                          ],
                                          if (task['budget'] != null) ...[
                                            Icon(
                                                Icons
                                                    .attach_money_outlined,
                                                size: 14,
                                                color: AppColors.textMuted),
                                            Text(
                                              task['budget'],
                                              style: TextStyle(
                                                  fontSize: 12,
                                                  color:
                                                      AppColors.textMuted),
                                            ),
                                            const SizedBox(width: 12),
                                          ],
                                          if (task['urgency'] != null) ...[
                                            Icon(Icons.schedule,
                                                size: 14,
                                                color: AppColors.textMuted),
                                            const SizedBox(width: 4),
                                            Text(
                                              task['urgency'],
                                              style: TextStyle(
                                                  fontSize: 12,
                                                  color:
                                                      AppColors.textMuted),
                                            ),
                                          ],
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          Text(
                                            '@${task['poster'] ?? ''}',
                                            style: TextStyle(
                                                fontSize: 12,
                                                color: AppColors.textMuted),
                                          ),
                                          const Spacer(),
                                          Icon(Icons.chat_bubble_outline,
                                              size: 14,
                                              color: AppColors.textMuted),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${task['comments'] ?? 0}',
                                            style: TextStyle(
                                                fontSize: 12,
                                                color: AppColors.textMuted),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.coral : AppColors.cardBg,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
