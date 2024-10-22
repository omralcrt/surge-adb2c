import 'package:surge_adb2c/surge_adb2c_token_type_enum.dart';
import 'package:surge_adb2c/surge_enum_extensions.dart';

class SurgeADB2CTokensResponse {
  SurgeADB2CTokensResponse({
    this.idToken,
    this.accessToken,
    this.refreshToken,
  });

  SurgeADB2CTokensResponse.fromJson(Map<String, dynamic> json)
      : idToken = json[SurgeADB2CTokenType.idToken.jsonName] as String?,
        accessToken = json[SurgeADB2CTokenType.accessToken.jsonName] as String?,
        refreshToken =
            json[SurgeADB2CTokenType.refreshToken.jsonName] as String?;
  final String? idToken;
  final String? refreshToken;
  final String? accessToken;
}
