import 'package:dio/dio.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:mosquito_alert/mosquito_alert.dart';
import 'package:mosquito_alert/src/auth/jwt_auth.dart';
import 'package:mosquito_alert_app/features/auth/data/auth_repository.dart';

class ApiService {
  final MosquitoAlert _client;
  late final InternetConnection _connection;

  MosquitoAlert get client => _client;
  InternetConnection get connection => _connection;

  ApiService({String baseUrl = ''}) : _client = _buildClient(baseUrl) {
    _connection = InternetConnection.createInstance(
      checkInterval: const Duration(seconds: 30),
      useDefaultOptions: false,
      enableStrictCheck: true,
      customCheckOptions: [
        // NOTE: this is dummy, all the logic is in customConnectivityCheck
        InternetCheckOption(uri: Uri.parse(baseUrl)),
      ],
      customConnectivityCheck: (option) async {
        try {
          final pingApi = _client.getPingApi();
          final response = await pingApi.retrieve();

          return InternetCheckResult(
            option: option,
            isSuccess: response.statusCode == 204,
          );
        } catch (_) {
          return InternetCheckResult(option: option, isSuccess: false);
        }
      },
    );
  }

  static MosquitoAlert _buildClient(String baseUrl) {
    final BaseOptions options = BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(milliseconds: 5000),
      // A lower receiveTimeout causes a timeout on the notifications endpoint
      receiveTimeout: const Duration(milliseconds: 30000),
      sendTimeout: const Duration(milliseconds: 30000),
    );

    final Dio dio = Dio(options);

    dio.interceptors.add(
      JwtAuthInterceptor(
        options: options,
        getAccessToken: () async => await AuthRepository.getAccessToken() ?? '',
        getRefreshToken: () async =>
            await AuthRepository.getRefreshToken() ?? '',
        onTokenUpdateCallback: (newAccessToken) async {
          await AuthRepository.setAccessToken(newAccessToken);
        },
      ),
    );

    return MosquitoAlert(dio: dio);
  }
}
