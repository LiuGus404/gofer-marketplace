import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../services/task_service.dart';

class CreateTaskScreen extends StatefulWidget {
  const CreateTaskScreen({super.key});

  @override
  State<CreateTaskScreen> createState() => _CreateTaskScreenState();
}

class _CreateTaskScreenState extends State<CreateTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _deliverablesController = TextEditingController();
  final _requirementsController = TextEditingController();
  final _taskService = TaskService();

  String _taskType = 'research';
  String _budget = 'Negotiable';
  String _urgency = 'Normal (2-5 days)';
  String _acceptorType = 'Anyone (human or AI)';
  bool _isPaid = true;
  bool _loading = false;

  static const _taskTypes = {
    'research': 'Research',
    'code': 'Code / Programming',
    'writing': 'Writing / Content',
    'design': 'Design',
    'automation': 'Automation',
    'data-analysis': 'Data Analysis',
    'web-scraping': 'Web Scraping',
    'translation': 'Translation / Localization',
    'video': 'Video Editing / Production',
    'audio': 'Audio / Transcription',
    'seo': 'SEO Optimization',
    'testing': 'Testing / QA',
    'data-entry': 'Data Entry / Formatting',
    'api-integration': 'API Integration',
    'chatbot': 'Chatbot / Conversational AI',
    'social-media': 'Social Media',
    'game-dev': 'Game Development',
    'subscription': 'Subscription / Recurring',
    'other': 'Other',
  };

  static const _budgetOptions = [
    '\$0 (volunteer/open-source)',
    '\$1-\$25',
    '\$25-\$100',
    '\$100-\$500',
    '\$500+',
    'Negotiable',
  ];

  static const _urgencyOptions = [
    'No rush (1+ week)',
    'Normal (2-5 days)',
    'Urgent (24-48 hours)',
    'ASAP (< 24 hours)',
  ];

  static const _acceptorOptions = [
    'Anyone (human or AI)',
    'Humans only',
    'AI agents only',
  ];

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      final task = await _taskService.createTask(
        title: _titleController.text.trim(),
        taskType: _taskType,
        budget: _budget,
        urgency: _urgency,
        description: _descriptionController.text.trim(),
        deliverables: _deliverablesController.text.trim(),
        requirements: _requirementsController.text.trim().isEmpty
            ? null
            : _requirementsController.text.trim(),
        acceptorType: _acceptorType,
        contact: _isPaid
            ? 'Paid (details exchanged privately after acceptance)'
            : 'Free / Open-source',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Task #${task['number']} created!'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        context.go('/home/my-tasks');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _deliverablesController.dispose();
    _requirementsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Post a Task')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Task Title',
                    hintText: 'e.g. Build a REST API for user authentication',
                  ),
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Enter a title' : null,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _taskType,
                  decoration: const InputDecoration(labelText: 'Task Type'),
                  items: _taskTypes.entries
                      .map((e) => DropdownMenuItem(
                            value: e.key,
                            child: Text(e.value),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => _taskType = v!),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _budget,
                  decoration:
                      const InputDecoration(labelText: 'Budget Range'),
                  items: _budgetOptions
                      .map((b) => DropdownMenuItem(value: b, child: Text(b)))
                      .toList(),
                  onChanged: (v) => setState(() => _budget = v!),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _urgency,
                  decoration: const InputDecoration(labelText: 'Urgency'),
                  items: _urgencyOptions
                      .map((u) => DropdownMenuItem(value: u, child: Text(u)))
                      .toList(),
                  onChanged: (v) => setState(() => _urgency = v!),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Task Description',
                    hintText: 'Describe what you need done in detail...',
                    alignLabelWithHint: true,
                  ),
                  maxLines: 6,
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Enter a description' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _deliverablesController,
                  decoration: const InputDecoration(
                    labelText: 'Expected Deliverables',
                    hintText: 'What should the completed work look like?',
                    alignLabelWithHint: true,
                  ),
                  maxLines: 3,
                  validator: (v) => v == null || v.isEmpty
                      ? 'Describe expected deliverables'
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _requirementsController,
                  decoration: const InputDecoration(
                    labelText: 'Requirements & Constraints (optional)',
                    hintText: 'e.g. Must use Python 3.11+, output as CSV...',
                    alignLabelWithHint: true,
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _acceptorType,
                  decoration:
                      const InputDecoration(labelText: 'Who can accept?'),
                  items: _acceptorOptions
                      .map((a) => DropdownMenuItem(value: a, child: Text(a)))
                      .toList(),
                  onChanged: (v) => setState(() => _acceptorType = v!),
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Paid task'),
                  subtitle: Text(_isPaid
                      ? 'Payment details exchanged privately after acceptance'
                      : 'Free / open-source contribution'),
                  value: _isPaid,
                  onChanged: (v) => setState(() => _isPaid = v),
                  contentPadding: EdgeInsets.zero,
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _loading ? null : _submit,
                  child: _loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Post Task'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
