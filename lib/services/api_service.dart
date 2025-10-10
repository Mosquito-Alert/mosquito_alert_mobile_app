import 'package:dio/dio.dart';
import 'package:mosquito_alert/mosquito_alert.dart';
import 'package:mosquito_alert_app/app_config.dart';
import 'package:mosquito_alert_app/providers/auth_provider.dart';

class ApiService {
  final AuthProvider authProvider;
  late final MosquitoAlert _client;

  ApiService._({required this.authProvider, baseUrl}) {
    final BaseOptions options = BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(milliseconds: 5000),
      receiveTimeout: const Duration(
          milliseconds:
              10000), // A lower receiveTimeout causes a timeout on the notifications endpoint
    );
    final Dio _dio = Dio(options);

    // Add custom JWT auth interceptor
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Add access token to all requests
        final accessToken = authProvider.accessToken;
        if (accessToken != null && accessToken.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $accessToken';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        // Handle 401 unauthorized errors by attempting token refresh
        if (error.response?.statusCode == 401) {
          final refreshToken = authProvider.refreshToken;
          if (refreshToken != null && refreshToken.isNotEmpty) {
            try {
              final newAccessToken =
                  await _refreshAccessToken(refreshToken, baseUrl);
              if (newAccessToken != null) {
                authProvider.setAccessToken(accessToken: newAccessToken);

                // Retry the original request with the new token
                final requestOptions = error.requestOptions;
                requestOptions.headers['Authorization'] =
                    'Bearer $newAccessToken';

                final response = await _dio.fetch(requestOptions);
                handler.resolve(response);
                return;
              }
            } catch (e) {
              // Token refresh failed, continue with original error
              print(e);
            }
          }
        }
        handler.next(error);
      },
    ));

    _client = MosquitoAlert(dio: _dio);
  }

  /// Attempts to refresh the access token using the refresh token
  Future<String?> _refreshAccessToken(
      String refreshToken, String baseUrl) async {
    try {
      final refreshDio = Dio(BaseOptions(baseUrl: baseUrl));
      final response = await refreshDio.post(
        '/auth/token/refresh/',
        data: {'refresh': refreshToken},
      );

      if (response.statusCode == 200 && response.data['access'] != null) {
        return response.data['access'] as String;
      }
    } catch (e) {
      print(e);
    }
    return null;
  }

  static Future<ApiService> init({required AuthProvider authProvider}) async {
    final config = await AppConfig.loadConfig();
    return ApiService._(
      authProvider: authProvider,
      baseUrl: config.baseUrl,
    );
  }

  MosquitoAlert get client => _client;
}
