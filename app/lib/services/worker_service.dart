import 'dart:convert';

import 'package:yaml/yaml.dart';

import 'api_service.dart';

class WorkerService {
  final _api = ApiService();

  Future<List<Map<String, dynamic>>> listWorkers({
    String? capability,
    String? workerType,
  }) async {
    final response = await _api.dio.get(
      '${_api.repoPath}/contents/workers',
    );

    final files = response.data as List<dynamic>;
    final workers = <Map<String, dynamic>>[];

    for (final file in files) {
      final name = file['name'] as String;
      if (!name.endsWith('.yml') && !name.endsWith('.yaml')) continue;

      final fileResponse = await _api.dio.get(
        '${_api.repoPath}/contents/${file['path']}',
      );

      final content = utf8.decode(
        base64Decode((fileResponse.data['content'] as String).replaceAll('\n', '')),
      );

      final yaml = loadYaml(content) as YamlMap;
      final worker = Map<String, dynamic>.from(yaml.value);

      if (capability != null) {
        final caps = (worker['capabilities'] as YamlList?)?.toList() ?? [];
        if (!caps.contains(capability)) continue;
      }
      if (workerType != null && worker['worker_type'] != workerType) continue;

      // Convert YamlList to regular List
      if (worker['capabilities'] is YamlList) {
        worker['capabilities'] = (worker['capabilities'] as YamlList).toList().cast<String>();
      }

      workers.add(worker);
    }

    return workers;
  }

  Future<Map<String, dynamic>?> getWorker(String username) async {
    try {
      final response = await _api.dio.get(
        '${_api.repoPath}/contents/workers/$username.yml',
      );

      final content = utf8.decode(
        base64Decode((response.data['content'] as String).replaceAll('\n', '')),
      );

      final yaml = loadYaml(content) as YamlMap;
      final worker = Map<String, dynamic>.from(yaml.value);

      if (worker['capabilities'] is YamlList) {
        worker['capabilities'] = (worker['capabilities'] as YamlList).toList().cast<String>();
      }

      return worker;
    } catch (_) {
      return null;
    }
  }
}
