import 'package:dio/dio.dart';
import '../app/constants.dart';

class GitHubOAuth {
  final _dio = Dio(BaseOptions(
    headers: {'Accept': 'application/json'},
  ));

  /// Step 1: Request a device code from GitHub.
  /// Returns {device_code, user_code, verification_uri, expires_in, interval}
  Future<Map<String, dynamic>> requestDeviceCode() async {
    final response = await _dio.post(
      'https://github.com/login/device/code',
      data: {
        'client_id': AppConstants.githubClientId,
        'scope': 'repo',
      },
    );
    return response.data;
  }

  /// Step 2: Poll GitHub until the user authorizes.
  /// Returns the access_token or throws on timeout/denial.
  Future<String> pollForToken({
    required String deviceCode,
    required int interval,
    required int expiresIn,
  }) async {
    final deadline = DateTime.now().add(Duration(seconds: expiresIn));

    while (DateTime.now().isBefore(deadline)) {
      await Future.delayed(Duration(seconds: interval + 1));

      try {
        final response = await _dio.post(
          'https://github.com/login/oauth/access_token',
          data: {
            'client_id': AppConstants.githubClientId,
            'device_code': deviceCode,
            'grant_type': 'urn:ietf:params:oauth:grant-type:device_code',
          },
        );

        final data = response.data as Map<String, dynamic>;

        if (data.containsKey('access_token')) {
          return data['access_token'] as String;
        }

        final error = data['error'] as String?;
        if (error == 'authorization_pending') {
          continue;
        } else if (error == 'slow_down') {
          await Future.delayed(const Duration(seconds: 5));
          continue;
        } else if (error == 'expired_token') {
          throw Exception('Authorization expired. Please try again.');
        } else if (error == 'access_denied') {
          throw Exception('Authorization denied by user.');
        }
      } catch (e) {
        if (e is Exception) rethrow;
      }
    }

    throw Exception('Authorization timed out.');
  }
}
