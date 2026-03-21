import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/theme.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../services/task_service.dart';
import '../../widgets/task_status_badge.dart';

class TaskDetailScreen extends ConsumerStatefulWidget {
  final int taskNumber;

  const TaskDetailScreen({super.key, required this.taskNumber});

  @override
  ConsumerState<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends ConsumerState<TaskDetailScreen> {
  final _taskService = TaskService();
  final _msgController = TextEditingController();
  final _scrollController = ScrollController();
  Map<String, dynamic>? _task;
  List<Map<String, dynamic>> _comments = [];
  bool _loading = true;
  bool _sending = false;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _loadTask();
  }

  Future<void> _loadTask() async {
    try {
      final data = await _taskService.getTask(widget.taskNumber);
      final comments =
          await _taskService.getTaskComments(widget.taskNumber);
      setState(() {
        _task = data;
        _comments = comments;
        _loading = false;
      });
      _startPolling();
      _scrollToBottom();
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 10), (_) async {
      try {
        final comments =
            await _taskService.getTaskComments(widget.taskNumber);
        if (mounted && comments.length != _comments.length) {
          final task = await _taskService.getTask(widget.taskNumber);
          setState(() {
            _comments = comments;
            _task = task;
          });
          _scrollToBottom();
        }
      } catch (_) {}
    });
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _msgController.text.trim();
    if (text.isEmpty) return;

    final hasToken = await ApiService().hasToken();
    if (!hasToken && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to send messages')),
      );
      return;
    }

    setState(() => _sending = true);
    try {
      await _taskService.commentOnTask(widget.taskNumber, text);
      _msgController.clear();
      await _loadTask();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
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
                onPressed: () =>
                    setDialogState(() => selected = i + 1),
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
    final controller = TextEditingController();
    final reason = await showDialog<String>(
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
    if (reason != null && reason.isNotEmpty) {
      await _taskService.rejectTask(widget.taskNumber, reason);
      _loadTask();
    }
  }

  Future<void> _cancel() async {
    await _taskService.cancelTask(widget.taskNumber);
    _loadTask();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _msgController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final myUsername = ref.watch(usernameProvider);

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
      body: Column(
        children: [
          // Scrollable content
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadTask,
              child: ListView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                children: [
                  // Task info (collapsible)
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
                          _infoRow(
                              'Payment',
                              t['contact'] != null &&
                                      t['contact']
                                          .toString()
                                          .contains('Free')
                                  ? 'Free / Open-source'
                                  : 'Paid (exchanged privately)'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ExpansionTile(
                    title: const Text('Task Details'),
                    initiallyExpanded: _comments.isEmpty,
                    children: [
                      if (t['description'] != null)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Description',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleSmall),
                              const SizedBox(height: 4),
                              Text(t['description']),
                            ],
                          ),
                        ),
                      if (t['deliverables'] != null)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Deliverables',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleSmall),
                              const SizedBox(height: 4),
                              Text(t['deliverables']),
                            ],
                          ),
                        ),
                      if (t['requirements'] != null)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Requirements',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleSmall),
                              const SizedBox(height: 4),
                              Text(t['requirements']),
                            ],
                          ),
                        ),
                    ],
                  ),

                  // Action buttons
                  if (status == 'submitted') ...[
                    const SizedBox(height: 8),
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
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _cancel,
                        icon: const Icon(Icons.cancel_outlined),
                        label: const Text('Cancel Task'),
                      ),
                    ),
                  ],

                  // Divider before chat
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Divider(),
                  ),
                  Text('Chat (${_comments.length})',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),

                  // Chat messages
                  if (_comments.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Center(
                        child: Text(
                          'No messages yet. Start the conversation!',
                          style: TextStyle(color: AppColors.textMuted),
                        ),
                      ),
                    )
                  else
                    ..._comments.map((c) {
                      final isMe =
                          c['user']?['login'] == myUsername;
                      final isBot = (c['body'] ?? '')
                          .toString()
                          .startsWith('**[Gofer Bot]**');
                      final sender =
                          c['user']?['login'] ?? '';
                      final avatar =
                          c['user']?['avatar_url'] as String?;
                      final body = c['body'] ?? '';

                      if (isBot) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            body.toString().replaceAll('**[Gofer Bot]** ', ''),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        );
                      }

                      return Align(
                        alignment: isMe
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          constraints: BoxConstraints(
                            maxWidth:
                                MediaQuery.of(context).size.width * 0.75,
                          ),
                          child: Column(
                            crossAxisAlignment: isMe
                                ? CrossAxisAlignment.end
                                : CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (!isMe && avatar != null)
                                    CircleAvatar(
                                      radius: 12,
                                      backgroundImage:
                                          NetworkImage(avatar),
                                    ),
                                  if (!isMe) const SizedBox(width: 6),
                                  Text(
                                    '@$sender',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textMuted,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  color: isMe
                                      ? AppColors.coral
                                      : AppColors.cardBg,
                                  borderRadius: BorderRadius.only(
                                    topLeft: const Radius.circular(16),
                                    topRight: const Radius.circular(16),
                                    bottomLeft: Radius.circular(
                                        isMe ? 16 : 4),
                                    bottomRight: Radius.circular(
                                        isMe ? 4 : 16),
                                  ),
                                ),
                                child: Text(
                                  body.toString(),
                                  style: TextStyle(
                                    color: isMe
                                        ? Colors.white
                                        : AppColors.textPrimary,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),

                  // View on GitHub link
                  const SizedBox(height: 8),
                  Center(
                    child: TextButton.icon(
                      onPressed: () {
                        final url = t['url'] as String?;
                        if (url != null) launchUrl(Uri.parse(url));
                      },
                      icon: const Icon(Icons.open_in_new, size: 16),
                      label: const Text('View on GitHub',
                          style: TextStyle(fontSize: 12)),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),

          // Chat input bar (sticky at bottom)
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            padding: EdgeInsets.fromLTRB(
              16,
              8,
              8,
              8 + MediaQuery.of(context).padding.bottom,
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _msgController,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: AppColors.cardBg,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      isDense: true,
                    ),
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                    maxLines: null,
                  ),
                ),
                const SizedBox(width: 4),
                Material(
                  color: AppColors.coral,
                  borderRadius: BorderRadius.circular(24),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(24),
                    onTap: _sending ? null : _sendMessage,
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: _sending
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.send,
                              color: Colors.white, size: 20),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
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
