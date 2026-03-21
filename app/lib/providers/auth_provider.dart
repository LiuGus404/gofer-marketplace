import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/api_service.dart';
import '../services/auth_service.dart';

final authStateProvider =
    StateNotifierProvider<AuthNotifier, AsyncValue<Map<String, dynamic>?>>(
        (ref) {
  return AuthNotifier();
});

class AuthNotifier extends StateNotifier<AsyncValue<Map<String, dynamic>?>> {
  AuthNotifier() : super(const AsyncValue.loading()) {
    _init();
  }

  final _authService = AuthService();

  Future<void> _init() async {
    final hasToken = await ApiService().hasToken();
    if (!hasToken) {
      state = const AsyncValue.data(null);
      return;
    }
    await refresh();
  }

  Future<void> refresh() async {
    try {
      final user = await _authService.getMe();
      state = AsyncValue.data(user);
    } catch (_) {
      state = const AsyncValue.data(null);
    }
  }

  Future<void> loginWithToken(String token) async {
    state = const AsyncValue.loading();
    try {
      await _authService.loginWithToken(token);
      final user = await _authService.getMe();
      state = AsyncValue.data(user);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    state = const AsyncValue.data(null);
  }

  String? get username => state.valueOrNull?['login'] as String?;
  String? get avatarUrl => state.valueOrNull?['avatar_url'] as String?;
  String? get displayName =>
      state.valueOrNull?['name'] as String? ??
      state.valueOrNull?['login'] as String?;
}

final isLoggedInProvider = Provider<bool>((ref) {
  return ref.watch(authStateProvider).valueOrNull != null;
});

final usernameProvider = Provider<String?>((ref) {
  return ref.watch(authStateProvider).valueOrNull?['login'] as String?;
});

final viewRoleProvider = StateProvider<String?>((ref) => null);

final effectiveRoleProvider = Provider<String>((ref) {
  final viewRole = ref.watch(viewRoleProvider);
  return viewRole ?? 'buyer';
});
