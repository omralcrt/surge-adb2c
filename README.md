> ⚠️ **Important Notice:** This repository has moved!  
> The new repository is located at [https://electrode@dev.azure.com/electrode/surge-mobility-mobile-sdks/_git/surge-mobility-adb2c-auth-flutter](https://electrode@dev.azure.com/electrode/surge-mobility-mobile-sdks/_git/surge-mobility-adb2c-auth-flutter).
> Please update your bookmarks and clone the new repository for the latest updates and support.


# Surge ADB2C Flutter Package

## Overview

The Surge ADB2C Flutter package provides a seamless way to integrate Azure Active Directory B2C (ADB2C) login support into your Flutter applications. This package simplifies the authentication process, allowing developers to easily implement user authentication flows using ADB2C.

## Features

- **Easy Integration**: Simple setup and integration into your Flutter project.
- **Customizable**: Supports various user flows and scopes.
- **Token Management**: Automatically handles access tokens, ID tokens, and refresh tokens.
- **WebView Support**: Utilizes a WebView for the authentication process.

## Installation

To use the Surge ADB2C package, add the following dependency to your `pubspec.yaml` file:
```yaml
dependencies:
  surge_adb2c:
  git:
    ref: 0.0.3
    url: https://github.com/omralcrt/surge-adb2c
```


Then, run the following command to install the package:
```bash
flutter pub get
```

## Usage

### Example

Here’s a basic example of how to use the `SurgeADB2CWebView` in your Flutter application:
```dart
import 'package:flutter/material.dart';
import 'package:surge_adb2c/surge_adb2c_web_view.dart';

class ExampleLoginPage extends StatelessWidget {
  const ExampleLoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SurgeADB2CWebView(
      tenantBaseUrl: 'your-tenant-url',
      clientId: 'your-client-id',
      redirectUrl: 'your-redirect-url',
      userFlowName: 'your-user-flow',
      scopes: ['scope1', 'scope2'],
      onRedirect: () {
        // Handle redirect after login
        print('Redirect occurred');
      },
      onAccessToken: (token) {
        // Handle access token
        print('Access Token: $token');
      },
      onIDToken: (idToken) {
        // Handle ID token
        print('ID Token: $idToken');
      },
      onRefreshToken: (refreshToken) {
        // Handle refresh token
        print('Refresh Token: $refreshToken');
      },
    );
  }
}
```


### Refresh Token Example

Here’s an example of how to refresh the access token using the `RefreshTokenInterceptor`:

```dart
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
    if (refreshTokenString == null || refreshTokenString.isEmpty) {
      throw Exception("Refresh token is missing");
    }

    final response = await surgeADB2CService.refreshTokens(
      refreshToken: refreshTokenString,
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
```
```dart
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
```

### Parameters

- `tenantBaseUrl`: The base URL of your Azure AD B2C tenant.
- `clientId`: The client ID of your application registered in Azure AD B2C.
- `redirectUrl`: The URL to which the user will be redirected after authentication.
- `userFlowName`: The name of the user flow to be used for authentication.
- `scopes`: A list of scopes that your application requires.
- `onRedirect`: Callback function that is called when a redirect occurs.
- `onAccessToken`: Callback function that is called with the access token.
- `onIDToken`: Callback function that is called with the ID token.
- `onRefreshToken`: Callback function that is called with the refresh token.
- `optionalParameters`: Additional optional parameters for the authentication request.
- `responseType`: The type of response expected (default is 'code').

## Contributing

Contributions are welcome! Please feel free to submit a pull request or open an issue for any enhancements or bug fixes.

## License

This package is licensed under the MIT License. See the [LICENSE](LICENSE) file for more information.
