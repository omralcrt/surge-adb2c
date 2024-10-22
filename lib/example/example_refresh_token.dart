import 'dart:async';
import 'package:dio/dio.dart';
import 'package:surge_adb2c/surge_adb2c_service.dart';

class RefreshTokenInterceptor extends Interceptor {
  RefreshTokenInterceptor({required this.dio})
      : surgeADB2CService = SurgeADB2CService(dio);

  final Dio dio;
  final SurgeADB2CService surgeADB2CService;

  @override
  Future<void> onError(
      DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      try {
        final newAccessToken = await refreshToken();
        return retryRequest(err, newAccessToken, handler);
      } catch (e) {
        return handler.next(err);
      }
    }
    return handler.next(err);
  }

  Future<String> refreshToken() async {
    final refreshTokenString = 'your-refresh-token';
    if (refreshTokenString == null || refreshTokenString!.isEmpty) {
      throw Exception("Refresh token is missing");
    }

    final response = await surgeADB2CService.refreshTokens(
      refreshToken: refreshTokenString!,
      clientId: 'your-client-id',
      userFlowName: 'your-user-flow',
      tenantBaseUrl: 'your-tenant-url',
      scopes: 'scope1, scope2',
    );

    if (response == null || response.accessToken == null) {
      throw Exception("Failed to refresh token");
    }

    // Save access token here
    return response.accessToken!;
  }

  Future<void> retryRequest(DioException err, String newToken,
      ErrorInterceptorHandler handler) async {
    final requestOptions = err.requestOptions;
    requestOptions.headers['Authorization'] = 'Bearer $newToken';

    final response = await dio.fetch(requestOptions);
    return handler.resolve(response);
  }
}

void main() async {
  final dio = Dio();
  final refreshTokenInterceptor = RefreshTokenInterceptor(dio: dio);

  dio.interceptors.add(refreshTokenInterceptor);

  // Example API call that may trigger the interceptor
  try {
    final response =
        await dio.get('https://api.yourservice.com/protected-endpoint');
    print('Response: ${response.data}');
  } catch (e) {
    print('Error: $e');
  }
}
