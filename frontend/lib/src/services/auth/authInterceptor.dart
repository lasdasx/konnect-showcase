import 'package:dio/dio.dart';

import 'authService.dart';
import '../api_service.dart';

class AuthInterceptor extends Interceptor {
  final AuthService authService;
  bool _isRefreshing = false;

  AuthInterceptor(this.authService);

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (options.path.contains('/auth/refresh') ||
        options.path.contains('/auth/login') ||
        options.path.contains('/auth/register')) {
      handler.next(options);
      return;
    }

    final token = await authService.accessToken;
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401 && !_isRefreshing) {
      _isRefreshing = true;

      final refreshed = await authService.refreshAccessToken();
      _isRefreshing = false;

      if (refreshed) {
        final token = await authService.accessToken;
        err.requestOptions.headers['Authorization'] = 'Bearer $token';

        handler.resolve(await ApiClient.dio.fetch(err.requestOptions));
        return;
      } else {
        await authService.logout();
      }
    }

    handler.next(err);
  }
}
