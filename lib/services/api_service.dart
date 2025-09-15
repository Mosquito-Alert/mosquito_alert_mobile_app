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

    _dio.interceptors.add(LogInterceptor(
      requestBody: false,
      responseBody: false,
      requestHeader: false,
      responseHeader: false,
      request: true,
      error: true,
    ));

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = authProvider.accessToken;
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          } else {
            print(
                'Auth interceptor: No token available for ${options.method} ${options.path}');
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          if (error.response?.statusCode == 401) {
            print('Auth interceptor: 401 error, token might be expired');
          }
          handler.next(error);
        },
      ),
    );

    _client = MosquitoAlert(
      dio: _dio,
      basePathOverride: baseUrl,
    );
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
