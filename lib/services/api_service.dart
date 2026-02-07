import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'dart:io';
import 'package:mosquito_alert/mosquito_alert.dart';
import 'package:mosquito_alert/src/auth/jwt_auth.dart';
import 'package:mosquito_alert_app/features/auth/data/auth_repository.dart';

class ApiService {
  final MosquitoAlert _client;
  MosquitoAlert get client => _client;

  ApiService({String baseUrl = ''}) : _client = _buildClient(baseUrl);

  static MosquitoAlert _buildClient(String baseUrl) {
    final BaseOptions options = BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(milliseconds: 15000),
      // A lower receiveTimeout causes a timeout on the notifications endpoint
      receiveTimeout: const Duration(milliseconds: 10000),
    );

    final Dio dio = Dio(options);

    // Ensure we bypass any system proxy/PAC that can cause connection refused
    // for app traffic on iOS. This makes network behavior more robust and
    // consistent with direct socket connectivity.
    dio.httpClientAdapter = IOHttpClientAdapter(
      createHttpClient: () {
        final client = HttpClient();
        client.findProxy = (uri) => 'DIRECT';
        return client;
      },
    );

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
