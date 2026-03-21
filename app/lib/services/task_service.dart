import 'api_service.dart';

class TaskService {
  final _api = ApiService();

  Future<Map<String, dynamic>> createTask({
    required String title,
    required String taskType,
    required String budget,
    required String urgency,
    required String description,
    required String deliverables,
    String? requirements,
    String acceptorType = 'Anyone (human or AI)',
    String? contact,
  }) async {
    final body = _buildIssueBody(
      type: taskType,
      budget: budget,
      urgency: urgency,
      description: description,
      deliverables: deliverables,
      requirements: requirements,
      acceptorType: acceptorType,
      contact: contact,
    );

    final response = await _api.dio.post(
      '${_api.repoPath}/issues',
      data: {
        'title': '[TASK] $title',
        'body': body,
        'labels': ['task', 'status:open'],
      },
    );
    return _issueToTask(response.data);
  }

  Future<List<Map<String, dynamic>>> listTasks({
    String? status,
    String? type,
    int limit = 20,
  }) async {
    final labels = ['task'];
    labels.add('status:${status ?? 'open'}');
    if (type != null) labels.add('type:$type');

    final response = await _api.dio.get(
      '${_api.repoPath}/issues',
      queryParameters: {
        'labels': labels.join(','),
        'state': (status == 'completed' || status == 'cancelled') ? 'closed' : 'open',
        'per_page': limit,
        'sort': 'created',
        'direction': 'desc',
      },
    );

    final issues = response.data as List<dynamic>;
    return issues.map((i) => _issueToTask(i)).toList();
  }

  Future<Map<String, dynamic>> getTask(int taskNumber) async {
    final response = await _api.dio.get(
      '${_api.repoPath}/issues/$taskNumber',
    );
    return _issueToTask(response.data);
  }

  Future<List<Map<String, dynamic>>> getTaskComments(int taskNumber) async {
    final response = await _api.dio.get(
      '${_api.repoPath}/issues/$taskNumber/comments',
      queryParameters: {'per_page': 50},
    );
    return (response.data as List<dynamic>).cast<Map<String, dynamic>>();
  }

  Future<void> acceptTask(int taskNumber, {String? message, bool isAI = false}) async {
    final body = '[ACCEPT]${isAI ? ' [AI]' : ''}'
        '${message != null ? '\n\n$message' : ''}';
    await _api.dio.post(
      '${_api.repoPath}/issues/$taskNumber/comments',
      data: {'body': body},
    );
  }

  Future<void> startTask(int taskNumber) async {
    await _api.dio.post(
      '${_api.repoPath}/issues/$taskNumber/comments',
      data: {'body': '[START] Beginning work on this task.'},
    );
  }

  Future<void> submitResult(int taskNumber, String summary, {List<String>? urls}) async {
    var body = '[SUBMIT]\n\n## Result\n\n$summary';
    if (urls != null && urls.isNotEmpty) {
      body += '\n\n## Deliverables\n\n${urls.map((u) => '- $u').join('\n')}';
    }
    await _api.dio.post(
      '${_api.repoPath}/issues/$taskNumber/comments',
      data: {'body': body},
    );
  }

  Future<void> approveTask(int taskNumber, {int? rating, String? review}) async {
    var body = '[APPROVE] Task accepted.';
    if (rating != null) {
      body += '\n\n[RATE: $rating/5]';
      if (review != null) body += ' $review';
    }
    await _api.dio.post(
      '${_api.repoPath}/issues/$taskNumber/comments',
      data: {'body': body},
    );
  }

  Future<void> rejectTask(int taskNumber, String reason) async {
    await _api.dio.post(
      '${_api.repoPath}/issues/$taskNumber/comments',
      data: {'body': '[REJECT]: $reason'},
    );
  }

  Future<void> cancelTask(int taskNumber) async {
    await _api.dio.post(
      '${_api.repoPath}/issues/$taskNumber/comments',
      data: {'body': '[CANCEL] Task cancelled by poster.'},
    );
  }

  Future<void> commentOnTask(int taskNumber, String message) async {
    await _api.dio.post(
      '${_api.repoPath}/issues/$taskNumber/comments',
      data: {'body': message},
    );
  }

  Future<List<Map<String, dynamic>>> myPostedTasks(String username) async {
    final response = await _api.dio.get(
      '${_api.repoPath}/issues',
      queryParameters: {
        'labels': 'task',
        'creator': username,
        'state': 'all',
        'per_page': 30,
        'sort': 'updated',
        'direction': 'desc',
      },
    );
    final issues = response.data as List<dynamic>;
    return issues.map((i) => _issueToTask(i)).toList();
  }

  // --- Helpers ---

  Map<String, dynamic> _issueToTask(Map<String, dynamic> issue) {
    final labels = (issue['labels'] as List<dynamic>? ?? [])
        .map((l) => l is String ? l : (l['name'] as String? ?? ''))
        .toList();

    final body = issue['body'] as String? ?? '';
    final parsed = _parseIssueBody(body);

    String status = 'open';
    for (final label in labels) {
      if (label.startsWith('status:')) {
        status = label.replaceFirst('status:', '');
        break;
      }
    }

    String? taskType;
    for (final label in labels) {
      if (label.startsWith('type:')) {
        taskType = label.replaceFirst('type:', '');
        break;
      }
    }

    String? budget;
    for (final label in labels) {
      if (label.startsWith('budget:')) {
        budget = label.replaceFirst('budget:', '');
        break;
      }
    }

    return {
      'number': issue['number'],
      'title': (issue['title'] as String? ?? '').replaceFirst(RegExp(r'^\[TASK\]\s*'), ''),
      'status': status,
      'task_type': taskType ?? parsed['type'],
      'budget': budget ?? parsed['budget'],
      'urgency': parsed['urgency'],
      'description': parsed['description'],
      'deliverables': parsed['deliverables'],
      'requirements': parsed['requirements'],
      'acceptor_type': parsed['acceptor_type'],
      'contact': parsed['contact'],
      'poster': issue['user']?['login'] ?? 'unknown',
      'poster_avatar': issue['user']?['avatar_url'],
      'comments': issue['comments'] ?? 0,
      'created_at': issue['created_at'],
      'updated_at': issue['updated_at'],
      'url': issue['html_url'],
      'labels': labels,
    };
  }

  Map<String, String?> _parseIssueBody(String body) {
    final sections = <String, String>{};
    final parts = body.split(RegExp(r'^### ', multiLine: true));

    for (final part in parts) {
      if (part.trim().isEmpty) continue;
      final newlineIdx = part.indexOf('\n');
      if (newlineIdx == -1) continue;
      final heading = part.substring(0, newlineIdx).trim();
      final content = part.substring(newlineIdx + 1).trim();
      if (content != '_No response_') {
        sections[heading] = content;
      }
    }

    return {
      'type': sections['Task Type']?.toLowerCase(),
      'budget': sections['Budget Range'],
      'urgency': sections['Urgency'],
      'description': sections['Task Description'],
      'deliverables': sections['Expected Deliverables'],
      'requirements': sections['Requirements & Constraints'],
      'acceptor_type': sections['Who can accept this?'],
      'contact': sections['Payment/Contact Method'],
    };
  }

  String _buildIssueBody({
    required String type,
    required String budget,
    required String urgency,
    required String description,
    required String deliverables,
    String? requirements,
    required String acceptorType,
    String? contact,
  }) {
    return [
      '### Task Type\n\n$type',
      '### Budget Range\n\n$budget',
      '### Urgency\n\n$urgency',
      '### Task Description\n\n$description',
      '### Expected Deliverables\n\n$deliverables',
      '### Requirements & Constraints\n\n${requirements ?? '_No response_'}',
      '### Who can accept this?\n\n$acceptorType',
      '### Payment/Contact Method\n\n${contact ?? '_No response_'}',
    ].join('\n\n');
  }
}
