import 'package:dio/dio.dart';
import 'package:pkce/pkce.dart';
import 'package:surge_adb2c/surge_adb2c_auth_response.dart'; // Ensure you have Dio imported

class SurgeADB2CService {
  final Dio dio;

  SurgeADB2CService(this.dio);

  Future<SurgeADB2CTokensResponse?> refreshTokens({
    required String refreshToken,
    required String clientId,
    required String userFlowName,
    required String tenantBaseUrl,
    required String scopes,
  }) async {
    const grantType = 'refresh_token';
    final url = '$tenantBaseUrl/$userFlowName/oauth2/v2.0/token';
    final response = await dio.post<Map<String, dynamic>>(
      url,
      data: {
        'grant_type': grantType,
        'scope': scopes,
        'client_id': clientId,
        'refresh_token': refreshToken,
      },
      options: Options(contentType: Headers.formUrlEncodedContentType),
    );
    if (response.data != null) {
      return SurgeADB2CTokensResponse.fromJson(response.data!);
    }

    return null;
  }

  Future<SurgeADB2CTokensResponse?> getAllTokens({
    required String redirectUri,
    required String clientId,
    required String authCode,
    required String userFlowName,
    required String tenantBaseUrl,
    required String scopes,
    required PkcePair pkcePair,
  }) async {
    const grantType = 'authorization_code';
    final url = '$tenantBaseUrl/$userFlowName/oauth2/v2.0/token';
    final response = await dio.post<Map<String, dynamic>>(
      url,
      data: {
        'scope': scopes,
        'grant_type': grantType,
        'code': authCode,
        'client_id': clientId,
        'code_verifier': pkcePair.codeVerifier,
        'redirect_uri': redirectUri,
      },
      options: Options(contentType: Headers.formUrlEncodedContentType),
    );
    if (response.data != null) {
      return SurgeADB2CTokensResponse.fromJson(response.data!);
    }
    return null;
  }
}