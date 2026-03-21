import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/worker_service.dart';
import 'auth_provider.dart';

// Worker profile for the current user (if registered as a worker)
final myWorkerProfileProvider =
    FutureProvider.autoDispose<Map<String, dynamic>?>((ref) async {
  final username = ref.watch(usernameProvider);
  if (username == null) return null;

  final workerService = WorkerService();
  return workerService.getWorker(username);
});
