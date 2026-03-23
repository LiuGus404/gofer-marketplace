import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../services/api_service.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  final _api = ApiService();
  List<Map<String, dynamic>> _workers = [];
  bool _loading = true;
  String _sortBy = 'reputation'; // reputation, tasks, rating

  @override
  void initState() {
    super.initState();
    _loadLeaderboard();
  }

  Future<void> _loadLeaderboard() async {
    setState(() => _loading = true);
    try {
      final response = await _api.dio.get(
        '${_api.repoPath}/contents/stats/leaderboard.json',
      );

      final content = response.data['content'] as String;
      final decoded = Uri.decodeFull(
        String.fromCharCodes(
          Uri.parse('data:,${content.replaceAll('\n', '')}')
              .data!
              .contentAsBytes(),
        ),
      );

      // Parse JSON manually since we can't import dart:convert easily
      // Actually let's use the GitHub raw content
      final rawResponse = await _api.dio.get(
        '${_api.repoPath}/contents/stats/leaderboard.json',
        queryParameters: {'ref': 'main'},
      );

      // Content is base64 encoded
      final base64Content =
          (rawResponse.data['content'] as String).replaceAll('\n', '');
      final bytes = _base64Decode(base64Content);
      final jsonStr = String.fromCharCodes(bytes);

      // Simple JSON parsing for the workers array
      final workers = _parseLeaderboard(jsonStr);
      _sortWorkers(workers);

      setState(() {
        _workers = workers;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  List<int> _base64Decode(String input) {
    const chars =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
    final output = <int>[];
    var buffer = 0;
    var bits = 0;
    for (var i = 0; i < input.length; i++) {
      final c = input[i];
      if (c == '=') break;
      final val = chars.indexOf(c);
      if (val == -1) continue;
      buffer = (buffer << 6) | val;
      bits += 6;
      if (bits >= 8) {
        bits -= 8;
        output.add((buffer >> bits) & 0xFF);
      }
    }
    return output;
  }

  List<Map<String, dynamic>> _parseLeaderboard(String json) {
    // Extract workers array using regex
    final workersMatch =
        RegExp(r'"workers"\s*:\s*\[([\s\S]*?)\]').firstMatch(json);
    if (workersMatch == null) return [];

    final workersStr = workersMatch.group(1) ?? '';
    final workers = <Map<String, dynamic>>[];

    final objectMatches = RegExp(r'\{[^}]+\}').allMatches(workersStr);
    for (final match in objectMatches) {
      final obj = match.group(0) ?? '';
      final worker = <String, dynamic>{};

      final username =
          RegExp(r'"username"\s*:\s*"([^"]*)"').firstMatch(obj);
      final type =
          RegExp(r'"worker_type"\s*:\s*"([^"]*)"').firstMatch(obj);
      final tasks =
          RegExp(r'"tasks_completed"\s*:\s*(\d+)').firstMatch(obj);
      final rating =
          RegExp(r'"avg_rating"\s*:\s*([\d.]+|null)').firstMatch(obj);
      final score =
          RegExp(r'"reputation_score"\s*:\s*(\d+)').firstMatch(obj);

      worker['username'] = username?.group(1) ?? '';
      worker['worker_type'] = type?.group(1) ?? '';
      worker['tasks_completed'] =
          int.tryParse(tasks?.group(1) ?? '0') ?? 0;
      final ratingStr = rating?.group(1);
      worker['avg_rating'] =
          ratingStr != null && ratingStr != 'null'
              ? double.tryParse(ratingStr)
              : null;
      worker['reputation_score'] =
          int.tryParse(score?.group(1) ?? '0') ?? 0;

      if (worker['username'].toString().isNotEmpty) {
        workers.add(worker);
      }
    }

    return workers;
  }

  void _sortWorkers(List<Map<String, dynamic>> workers) {
    workers.sort((a, b) {
      switch (_sortBy) {
        case 'tasks':
          return (b['tasks_completed'] as int)
              .compareTo(a['tasks_completed'] as int);
        case 'rating':
          final aRating = (a['avg_rating'] as double?) ?? 0;
          final bRating = (b['avg_rating'] as double?) ?? 0;
          return bRating.compareTo(aRating);
        default: // reputation
          return (b['reputation_score'] as int)
              .compareTo(a['reputation_score'] as int);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Leaderboard')),
      body: Column(
        children: [
          // Sort toggle
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                _SortChip(
                  label: 'Reputation',
                  icon: Icons.emoji_events,
                  selected: _sortBy == 'reputation',
                  onTap: () {
                    setState(() => _sortBy = 'reputation');
                    _sortWorkers(_workers);
                  },
                ),
                const SizedBox(width: 8),
                _SortChip(
                  label: 'Tasks Done',
                  icon: Icons.task_alt,
                  selected: _sortBy == 'tasks',
                  onTap: () {
                    setState(() => _sortBy = 'tasks');
                    _sortWorkers(_workers);
                  },
                ),
                const SizedBox(width: 8),
                _SortChip(
                  label: 'Rating',
                  icon: Icons.star,
                  selected: _sortBy == 'rating',
                  onTap: () {
                    setState(() => _sortBy = 'rating');
                    _sortWorkers(_workers);
                  },
                ),
              ],
            ),
          ),
          // List
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _workers.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.emoji_events_outlined,
                                size: 56, color: AppColors.textMuted),
                            const SizedBox(height: 16),
                            Text('No workers ranked yet',
                                style: TextStyle(color: AppColors.textMuted)),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadLeaderboard,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          itemCount: _workers.length,
                          itemBuilder: (context, index) {
                            final w = _workers[index];
                            final rank = index + 1;
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                leading: _buildRankBadge(rank),
                                title: Text(
                                  '@${w['username']}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600),
                                ),
                                subtitle: Text(
                                  '${w['worker_type']} · ${w['tasks_completed']} tasks',
                                ),
                                trailing: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    if (w['avg_rating'] != null)
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.star,
                                              size: 14, color: Colors.amber),
                                          const SizedBox(width: 2),
                                          Text('${w['avg_rating']}',
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.w600)),
                                        ],
                                      ),
                                    Text(
                                      '${w['reputation_score']} pts',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textMuted,
                                      ),
                                    ),
                                  ],
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

  Widget _buildRankBadge(int rank) {
    Color color;
    IconData? icon;
    switch (rank) {
      case 1:
        color = Colors.amber;
        icon = Icons.emoji_events;
        break;
      case 2:
        color = Colors.grey.shade400;
        icon = Icons.emoji_events;
        break;
      case 3:
        color = Colors.brown.shade300;
        icon = Icons.emoji_events;
        break;
      default:
        color = AppColors.textMuted;
        icon = null;
    }

    return CircleAvatar(
      radius: 20,
      backgroundColor: color.withOpacity(0.15),
      child: icon != null
          ? Icon(icon, color: color, size: 22)
          : Text(
              '#$rank',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
    );
  }
}

class _SortChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _SortChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.coral : AppColors.cardBg,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 14,
                color: selected ? Colors.white : AppColors.textMuted),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
