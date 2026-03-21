import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/task_service.dart';
import '../../widgets/task_status_badge.dart';

class TaskDetailScreen extends StatefulWidget {
  final int taskNumber;

  const TaskDetailScreen({super.key, required this.taskNumber});

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  final _taskService = TaskService();
  Map<String, dynamic>? _task;
  List<Map<String, dynamic>> _comments = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadTask();
  }

  Future<void> _loadTask() async {
    try {
      final data = await _taskService.getTask(widget.taskNumber);
      final comments = await _taskService.getTaskComments(widget.taskNumber);
      setState(() {
        _task = data;
        _comments = comments;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _approve() async {
    final rating = await _showRatingDialog();
    if (rating != null) {
      await _taskService.approveTask(widget.taskNumber,
          rating: rating, review: 'Great work!');
      _loadTask();
    }
  }

  Future<int?> _showRatingDialog() async {
    int selected = 5;
    return showDialog<int>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Rate this work'),
          content: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (i) {
              return IconButton(
                icon: Icon(
                  i < selected ? Icons.star : Icons.star_border,
                  color: Colors.amber,
                  size: 32,
                ),
                onPressed: () => setDialogState(() => selected = i + 1),
              );
            }),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, selected),
              child: const Text('Approve'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _reject() async {
    final reason = await _showRejectDialog();
    if (reason != null && reason.isNotEmpty) {
      await _taskService.rejectTask(widget.taskNumber, reason);
      _loadTask();
    }
  }

  Future<String?> _showRejectDialog() async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reject — reason'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Why are you rejecting this result?',
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }

  Future<void> _cancel() async {
    await _taskService.cancelTask(widget.taskNumber);
    _loadTask();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_task == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Task not found')),
      );
    }

    final t = _task!;
    final status = t['status'] as String;

    return Scaffold(
      appBar: AppBar(
        title: Text('#${t['number']}'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: TaskStatusBadge(status: status),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadTask,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(t['title'] ?? '',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _infoRow('Type', t['task_type']),
                      _infoRow('Budget', t['budget']),
                      _infoRow('Urgency', t['urgency']),
                      _infoRow('Posted by', '@${t['poster']}'),
                      _infoRow('Payment', t['contact'] != null && t['contact'].toString().contains('Free')
                          ? 'Free / Open-source'
                          : 'Paid (exchanged privately)'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text('Description',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(t['description'] ?? ''),
                ),
              ),
              if (t['deliverables'] != null) ...[
                const SizedBox(height: 16),
                Text('Expected Deliverables',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(t['deliverables']),
                  ),
                ),
              ],
              if (t['requirements'] != null) ...[
                const SizedBox(height: 16),
                Text('Requirements',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(t['requirements']),
                  ),
                ),
              ],
              if (_comments.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text('Comments (${_comments.length})',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                ..._comments.map((c) => Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('@${c['user']?['login'] ?? ''}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text(c['body'] ?? ''),
                          ],
                        ),
                      ),
                    )),
              ],
              const SizedBox(height: 16),
              // Action buttons based on status
              if (status == 'submitted') ...[
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _approve,
                        icon: const Icon(Icons.check),
                        label: const Text('Approve'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _reject,
                        icon: const Icon(Icons.close),
                        label: const Text('Reject'),
                      ),
                    ),
                  ],
                ),
              ],
              if (status == 'open') ...[
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _cancel,
                    icon: const Icon(Icons.cancel_outlined),
                    label: const Text('Cancel Task'),
                  ),
                ),
              ],
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  onPressed: () {
                    final url = t['url'] as String?;
                    if (url != null) launchUrl(Uri.parse(url));
                  },
                  icon: const Icon(Icons.open_in_new),
                  label: const Text('View on GitHub'),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(String label, dynamic value) {
    if (value == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(label,
                style: const TextStyle(
                    fontWeight: FontWeight.w500, color: Colors.grey)),
          ),
          Expanded(child: Text(value.toString())),
        ],
      ),
    );
  }
}
