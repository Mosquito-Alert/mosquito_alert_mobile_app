import 'package:dio/dio.dart';
import 'package:mosquito_alert/mosquito_alert.dart';
import 'package:mosquito_alert/src/auth/jwt_auth.dart';
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

    _dio.interceptors.add(JwtAuthInterceptor(
        options: options,
        getAccessToken: () async => authProvider.accessToken ?? '',
        getRefreshToken: () async => authProvider.refreshToken ?? '',
        onTokenUpdateCallback: (newAccessToken) async {
          await authProvider.setAccessToken(accessToken: newAccessToken);
        }));

    _client = MosquitoAlert(dio: _dio);
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
