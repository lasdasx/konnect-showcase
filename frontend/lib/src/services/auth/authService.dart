import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:konnect/src/services/api_service.dart';
import 'package:dio/dio.dart';

class AuthService {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';

  Future<String?> get accessToken async => _storage.read(key: _accessTokenKey);

  Future<String?> get refreshToken async =>
      _storage.read(key: _refreshTokenKey);

  Future<void> saveTokens(String access, String refresh) async {
    await _storage.write(key: _accessTokenKey, value: access);
    await _storage.write(key: _refreshTokenKey, value: refresh);
  }

  Future<void> deleteTokens() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
  }

  Future<bool> refreshAccessToken() async {
    final refreshToken = await this.refreshToken;
    if (refreshToken == null) return false;

    try {
      final res = await ApiClient.dio.post(
        '/auth/refresh',
        options: Options(
          headers: {'Authorization': 'Bearer $refreshToken'},
          responseType: ResponseType.json,
        ),
      );

      await saveTokens(res.data['access_token'], res.data['refresh_token']);

      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> logout() async {
    await _storage.deleteAll();
  }
}
