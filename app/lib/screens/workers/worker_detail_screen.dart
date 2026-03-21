import 'package:flutter/material.dart';

import '../../services/worker_service.dart';
import '../../widgets/rating_stars.dart';

class WorkerDetailScreen extends StatefulWidget {
  final String workerId;

  const WorkerDetailScreen({super.key, required this.workerId});

  @override
  State<WorkerDetailScreen> createState() => _WorkerDetailScreenState();
}

class _WorkerDetailScreenState extends State<WorkerDetailScreen> {
  final _workerService = WorkerService();
  Map<String, dynamic>? _worker;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadWorker();
  }

  Future<void> _loadWorker() async {
    try {
      final worker = await _workerService.getWorker(widget.workerId);
      setState(() {
        _worker = worker;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_worker == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Worker not found')),
      );
    }

    final w = _worker!;
    final capabilities =
        (w['capabilities'] as List?)?.cast<String>() ?? [];
    final status = w['status'] as String? ?? 'active';

    return Scaffold(
      appBar: AppBar(title: Text('@${w['github_username'] ?? 'Worker'}')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          child: Text(
                            (w['github_username'] as String? ?? '?')[0]
                                .toUpperCase(),
                            style: const TextStyle(fontSize: 24),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '@${w['github_username'] ?? ''}',
                                style:
                                    Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 4),
                              Text(w['worker_type'] ?? ''),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  if (w['avg_rating'] != null)
                                    RatingStars(
                                        rating:
                                            (w['avg_rating'] as num).toDouble()),
                                  const SizedBox(width: 8),
                                  Text(
                                      '${w['tasks_completed'] ?? 0} tasks completed'),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Chip(
                          label: Text(status),
                          backgroundColor: status == 'active'
                              ? Colors.green.shade100
                              : Colors.grey.shade200,
                        ),
                      ],
                    ),
                    if (w['bio'] != null) ...[
                      const SizedBox(height: 16),
                      Text(w['bio']),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('Capabilities',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children:
                  capabilities.map((c) => Chip(label: Text(c))).toList(),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _infoRow('Rate', w['rate']),
                    _infoRow('Availability', w['availability']),
                    _infoRow('Registered', w['registered_at']),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, dynamic value) {
    if (value == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value.toString(),
              style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
