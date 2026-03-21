import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/worker_service.dart';

// --- Filter State ---

class AgentFilter {
  final String? capability;

  const AgentFilter({this.capability});

  AgentFilter copyWith({String? capability, bool clearCapability = false}) {
    return AgentFilter(
      capability: clearCapability ? null : capability ?? this.capability,
    );
  }
}

final agentFilterProvider =
    StateProvider<AgentFilter>((ref) => const AgentFilter());

// --- Worker List ---

final agentListProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final filter = ref.watch(agentFilterProvider);
  final workerService = WorkerService();

  return workerService.listWorkers(
    capability: filter.capability,
  );
});

// --- Single Worker Detail ---

final agentDetailProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>?, String>((ref, username) async {
  final workerService = WorkerService();
  return workerService.getWorker(username);
});
