import 'api_service.dart';

class AuthService {
  final _api = ApiService();

  Future<void> loginWithToken(String token) async {
    await _api.saveToken(token);
  }

  Future<Map<String, dynamic>> getMe() async {
    final response = await _api.dio.get('/user');
    return response.data;
  }

  Future<void> logout() async {
    await _api.clearTokens();
  }
}
