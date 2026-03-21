import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/task_service.dart';

// --- Task List ---

final taskListProvider = StateNotifierProvider<TaskListNotifier,
    AsyncValue<List<Map<String, dynamic>>>>((ref) {
  return TaskListNotifier();
});

class TaskListNotifier
    extends StateNotifier<AsyncValue<List<Map<String, dynamic>>>> {
  TaskListNotifier() : super(const AsyncValue.loading()) {
    load();
  }

  final _taskService = TaskService();

  Future<void> load({String? status, String? type}) async {
    state = const AsyncValue.loading();
    try {
      final tasks = await _taskService.listTasks(status: status, type: type);
      state = AsyncValue.data(tasks);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  void prependTask(Map<String, dynamic> task) {
    final current = state.valueOrNull ?? [];
    state = AsyncValue.data([task, ...current]);
  }

  void updateTask(Map<String, dynamic> updated) {
    final current = state.valueOrNull ?? [];
    state = AsyncValue.data([
      for (final t in current)
        if (t['number'] == updated['number']) updated else t,
    ]);
  }
}

// --- Single Task Detail (polling-based) ---

final taskDetailProvider = StateNotifierProvider.family<TaskDetailNotifier,
    AsyncValue<Map<String, dynamic>?>, int>(
  (ref, taskNumber) => TaskDetailNotifier(taskNumber),
);

class TaskDetailNotifier
    extends StateNotifier<AsyncValue<Map<String, dynamic>?>> {
  TaskDetailNotifier(this.taskNumber) : super(const AsyncValue.loading()) {
    _load();
  }

  final int taskNumber;
  final _taskService = TaskService();
  Timer? _pollTimer;

  Future<void> _load() async {
    try {
      final task = await _taskService.getTask(taskNumber);
      state = AsyncValue.data(task);
      _startPolling();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 15), (_) async {
      try {
        final task = await _taskService.getTask(taskNumber);
        if (mounted) state = AsyncValue.data(task);
      } catch (_) {}
    });
  }

  Future<void> reload() async => _load();

  Future<void> approve({int? rating, String? review}) async {
    await _taskService.approveTask(taskNumber, rating: rating, review: review);
    await _load();
  }

  Future<void> reject(String reason) async {
    await _taskService.rejectTask(taskNumber, reason);
    await _load();
  }

  Future<void> cancel() async {
    await _taskService.cancelTask(taskNumber);
    await _load();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }
}

// --- Task Comments ---

final taskCommentsProvider = FutureProvider.autoDispose
    .family<List<Map<String, dynamic>>, int>((ref, taskNumber) async {
  final taskService = TaskService();
  return taskService.getTaskComments(taskNumber);
});
