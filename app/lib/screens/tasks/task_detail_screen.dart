import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/theme.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../services/chat_service.dart';
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
  final _chatService = ChatService();
  final _msgController = TextEditingController();
  final _scrollController = ScrollController();
  Map<String, dynamic>? _task;
  List<Map<String, dynamic>> _messages = [];
  bool _loading = true;
  bool _sending = false;
  StreamSubscription? _chatSub;
  Timer? _pollTimer;

  bool get _useSupabase => ChatService.isConfigured;

  @override
  void initState() {
    super.initState();
    _loadTask();
  }

  Future<void> _loadTask() async {
    try {
      final data = await _taskService.getTask(widget.taskNumber);
      setState(() {
        _task = data;
        _loading = false;
      });
      _initChat();
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  void _initChat() {
    if (_useSupabase) {
      _chatSub?.cancel();
      _chatSub = _chatService.subscribe(
        taskNumber: widget.taskNumber,
        onMessages: (msgs) {
          if (mounted) {
            setState(() => _messages = msgs);
            _scrollToBottom();
          }
        },
      );
    } else {
      _loadGithubComments();
      _pollTimer?.cancel();
      _pollTimer = Timer.periodic(const Duration(seconds: 10), (_) {
        _loadGithubComments();
      });
    }
  }

  Future<void> _loadGithubComments() async {
    try {
      final comments =
          await _taskService.getTaskComments(widget.taskNumber);
      if (mounted) {
        final converted = comments
            .map((c) => {
                  'sender_username': c['user']?['login'] ?? '',
                  'sender_avatar': c['user']?['avatar_url'],
                  'message': c['body'] ?? '',
                  'created_at': c['created_at'],
                })
            .toList();
        setState(() => _messages = converted);
        _scrollToBottom();
      }
    } catch (_) {}
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

    final user = ref.read(authStateProvider).valueOrNull;
    final username = user?['login'] as String? ?? 'unknown';
    final avatar = user?['avatar_url'] as String? ?? '';

    setState(() => _sending = true);
    try {
      if (_useSupabase) {
        await _chatService.sendMessage(
          taskNumber: widget.taskNumber,
          senderUsername: username,
          senderAvatar: avatar,
          message: text,
        );
      } else {
        await _taskService.commentOnTask(widget.taskNumber, text);
        await _loadGithubComments();
      }
      _msgController.clear();
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
    int selected = 5;
    final rating = await showDialog<int>(
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
    if (rating != null) {
      await _taskService.approveTask(widget.taskNumber,
          rating: rating, review: 'Great work!');
      _loadTask();
    }
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
    _chatSub?.cancel();
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
          Expanded(
            child: ListView(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              children: [
                // Task info
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
                                  t['contact'].toString().contains('Free')
                              ? 'Free / Open-source'
                              : 'Paid (exchanged privately)',
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                ExpansionTile(
                  title: const Text('Task Details'),
                  initiallyExpanded: _messages.isEmpty,
                  children: [
                    if (t['description'] != null)
                      _detailSection('Description', t['description']),
                    if (t['deliverables'] != null)
                      _detailSection('Deliverables', t['deliverables']),
                    if (t['requirements'] != null)
                      _detailSection('Requirements', t['requirements']),
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

                // Chat
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(),
                ),
                Row(
                  children: [
                    Text('Chat (${_messages.length})',
                        style: Theme.of(context).textTheme.titleMedium),
                    if (_useSupabase) ...[
                      const SizedBox(width: 8),
                      Icon(Icons.lock, size: 14, color: Colors.green.shade600),
                      const SizedBox(width: 4),
                      Text('Private',
                          style: TextStyle(
                              fontSize: 11, color: Colors.green.shade600)),
                    ],
                  ],
                ),
                const SizedBox(height: 8),

                if (_messages.isEmpty)
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
                  ..._messages.map((m) {
                    final sender = m['sender_username'] ?? '';
                    final avatar = m['sender_avatar'] as String?;
                    final body = m['message'] ?? '';
                    final isMe = sender == myUsername;
                    final isBot = body.toString().startsWith('**[Gofer Bot]**');

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
                      alignment:
                          isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.75,
                        ),
                        child: Column(
                          crossAxisAlignment: isMe
                              ? CrossAxisAlignment.end
                              : CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (!isMe && avatar != null && avatar.isNotEmpty)
                                  CircleAvatar(
                                    radius: 12,
                                    backgroundImage: NetworkImage(avatar),
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
                                color:
                                    isMe ? AppColors.coral : AppColors.cardBg,
                                borderRadius: BorderRadius.only(
                                  topLeft: const Radius.circular(16),
                                  topRight: const Radius.circular(16),
                                  bottomLeft:
                                      Radius.circular(isMe ? 16 : 4),
                                  bottomRight:
                                      Radius.circular(isMe ? 4 : 16),
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

                // View on GitHub
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

          // Chat input bar
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
                      hintText: _useSupabase
                          ? 'Private message...'
                          : 'Type a message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: AppColors.cardBg,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      isDense: true,
                      prefixIcon: _useSupabase
                          ? Icon(Icons.lock, size: 16,
                              color: Colors.green.shade600)
                          : null,
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

  Widget _detailSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 4),
          Text(content),
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
