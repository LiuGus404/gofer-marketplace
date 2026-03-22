import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../app/constants.dart';

class ChatService {
  static bool get isConfigured =>
      AppConstants.supabaseUrl.isNotEmpty &&
      AppConstants.supabaseAnonKey.isNotEmpty;

  SupabaseClient get _client => Supabase.instance.client;

  /// Send a message in a task chat room.
  Future<void> sendMessage({
    required int taskNumber,
    required String senderUsername,
    required String senderAvatar,
    required String message,
  }) async {
    await _client.from('chat_messages').insert({
      'task_number': taskNumber,
      'sender_username': senderUsername,
      'sender_avatar': senderAvatar,
      'message': message,
    });
  }

  /// Get all messages for a task.
  Future<List<Map<String, dynamic>>> getMessages(int taskNumber) async {
    final response = await _client
        .from('chat_messages')
        .select()
        .eq('task_number', taskNumber)
        .order('created_at', ascending: true);
    return List<Map<String, dynamic>>.from(response);
  }

  /// Subscribe to real-time messages for a task.
  StreamSubscription<List<Map<String, dynamic>>> subscribe({
    required int taskNumber,
    required void Function(List<Map<String, dynamic>> messages) onMessages,
  }) {
    return _client
        .from('chat_messages')
        .stream(primaryKey: ['id'])
        .eq('task_number', taskNumber)
        .order('created_at', ascending: true)
        .listen(onMessages);
  }
}
