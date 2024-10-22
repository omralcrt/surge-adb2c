import 'package:surge_adb2c/surge_adb2c_token_type_enum.dart';

extension SurgeADB2CTokenTypeX on SurgeADB2CTokenType {
  String get jsonName {
    switch (this) {
      case SurgeADB2CTokenType.accessToken:
        return 'access_token';
      case SurgeADB2CTokenType.idToken:
        return 'id_token';
      case SurgeADB2CTokenType.refreshToken:
        return 'refresh_token';
    }
  }
}
