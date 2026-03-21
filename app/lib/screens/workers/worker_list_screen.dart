import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../services/worker_service.dart';

class WorkerListScreen extends StatefulWidget {
  const WorkerListScreen({super.key});

  @override
  State<WorkerListScreen> createState() => _WorkerListScreenState();
}

class _WorkerListScreenState extends State<WorkerListScreen> {
  final _workerService = WorkerService();
  List<Map<String, dynamic>> _workers = [];
  bool _loading = true;
  String? _selectedCapability;

  final _capabilities = [
    'research',
    'code',
    'writing',
    'design',
    'automation',
    'data-analysis',
  ];

  @override
  void initState() {
    super.initState();
    _loadWorkers();
  }

  Future<void> _loadWorkers() async {
    setState(() => _loading = true);
    try {
      final workers = await _workerService.listWorkers(
        capability: _selectedCapability,
      );
      setState(() {
        _workers = workers;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          RefreshIndicator(
            color: AppColors.coral,
            onRefresh: _loadWorkers,
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: _buildHero(context)),
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 48,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      children: [
                        _FilterChip(
                          label: 'All',
                          selected: _selectedCapability == null,
                          onTap: () {
                            setState(() => _selectedCapability = null);
                            _loadWorkers();
                          },
                        ),
                        ..._capabilities.map((cap) => _FilterChip(
                              label: cap,
                              selected: _selectedCapability == cap,
                              onTap: () {
                                setState(() => _selectedCapability = cap);
                                _loadWorkers();
                              },
                            )),
                      ],
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 16)),
                if (_loading)
                  const SliverFillRemaining(
                    child: Center(
                        child: CircularProgressIndicator(
                            color: AppColors.coral)),
                  )
                else if (_workers.isEmpty)
                  SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.smart_toy_outlined,
                              size: 56, color: AppColors.textMuted),
                          const SizedBox(height: 16),
                          Text(
                            'No AI workers registered yet',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final w = _workers[index];
                          final caps = (w['capabilities'] as List?)
                                  ?.cast<String>() ??
                              [];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              leading: CircleAvatar(
                                child: Text(
                                  (w['github_username'] as String? ?? '?')[0]
                                      .toUpperCase(),
                                ),
                              ),
                              title: Text(
                                  '@${w['github_username'] ?? 'unknown'}'),
                              subtitle: Text(
                                '${w['worker_type'] ?? ''} · ${caps.take(3).join(', ')}',
                              ),
                              trailing: w['rate'] != null
                                  ? Text(w['rate'],
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold))
                                  : null,
                              onTap: () => context.push(
                                  '/workers/${w['github_username']}'),
                            ),
                          );
                        },
                        childCount: _workers.length,
                      ),
                    ),
                  ),
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            right: 16,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.settings_outlined,
                    color: Colors.white, size: 22),
                onPressed: () => context.push('/settings'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHero(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 60, 20, 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF8B5E52), Color(0xFF6B4C3B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.brownDark.withOpacity(0.25),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.coral.withOpacity(0.25),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'AI Workers',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.coralMuted,
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Find AI Workers\nFor Any Tasks',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'AI agents and humans ready for any task',
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withOpacity(0.65),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.coral : AppColors.cardBg,
          borderRadius: BorderRadius.circular(20),
          boxShadow: selected
              ? [
                  BoxShadow(
                      color: AppColors.coral.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2))
                ]
              : [],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
