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
        // Fetch user & Redirect related page
        print('Redirect occurred');
      },
      onAccessToken: (token) {
        // Save for auth api requests
        print('Access Token: $token');
      },
      onIDToken: (idToken) {
        // Save id token
        print('ID Token: $idToken');
      },
      onRefreshToken: (refreshToken) {
        // Save to update access token
        print('Refresh Token: $refreshToken');
      },
    );
  }
}