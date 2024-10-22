import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:pkce/pkce.dart';
import 'package:surge_adb2c/surge_adb2c_auth_response.dart';
import 'package:surge_adb2c/surge_adb2c_service.dart';
import 'package:surge_adb2c/surge_adb2c_token_type_enum.dart';

class SurgeADB2CWebView extends StatefulWidget {
  final String tenantBaseUrl;
  final String clientId;
  final String redirectUrl;
  final String userFlowName;
  final List<String> scopes;
  final VoidCallback onRedirect;
  final ValueChanged<String> onAccessToken;
  final ValueChanged<String> onIDToken;
  final ValueChanged<String> onRefreshToken;
  final Map<String, String> optionalParameters;
  final String responseType;

  const SurgeADB2CWebView({
    super.key,
    required this.tenantBaseUrl,
    required this.clientId,
    required this.redirectUrl,
    required this.userFlowName,
    required this.scopes,
    required this.onRedirect,
    required this.onAccessToken,
    required this.onIDToken,
    required this.onRefreshToken,
    this.optionalParameters = const {},
    this.responseType = 'code',
  });

  @override
  SurgeADB2CWebViewState createState() => SurgeADB2CWebViewState();
}

class SurgeADB2CWebViewState extends State<SurgeADB2CWebView> {
  final SurgeADB2CService surgeADB2CService;

  SurgeADB2CWebViewState() : surgeADB2CService = SurgeADB2CService(Dio());

  final PkcePair pkcePair = PkcePair.generate();
  final _key = UniqueKey();
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    InAppWebViewController.clearAllCache();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      body: Stack(
        children: [
          InAppWebView(
            key: _key,
            initialUrlRequest: URLRequest(
              url: WebUri(
                _getUserFlowUrl(
                  userFlow: '${widget.tenantBaseUrl}/oauth2/v2.0/authorize',
                ),
              ),
            ),
            initialSettings: InAppWebViewSettings(
              useShouldOverrideUrlLoading: true,
              cacheEnabled: false,
              cacheMode: CacheMode.LOAD_NO_CACHE,
              clearCache: true,
              clearSessionCache: true,
            ),
            shouldOverrideUrlLoading: (controller, navigationAction) async {
              final uri = navigationAction.request.url!;
              final url = uri.toString();
              if (url.contains(
                '${widget.redirectUrl}?code',
              )) {
                final response = Uri.dataFromString(url);
                _onPageFinishedTasks(url, response);

                return NavigationActionPolicy.CANCEL;
              } else {
                return NavigationActionPolicy.ALLOW;
              }
            },
            onLoadStop: (controller, url) {
              controller.evaluateJavascript(
                source: """
            document.addEventListener('focusin', function(event) {
              if (event.target.tagName === 'INPUT' || event.target.tagName === 'TEXTAREA') {
                setTimeout(() => {
                  event.target.scrollIntoView({behavior: 'smooth', block: 'end'});
                }, 800); // Adjust the delay if needed
              }
            });
          """,
              );
              setState(() {
                isLoading = false;
              });
            },
          ),
          if (isLoading)
            Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }

  void _onPageFinishedTasks(String url, Uri response) {
    if (response.path.contains(widget.redirectUrl)) {
      if (url.contains(SurgeADB2CTokenType.idToken.name) ||
          url.contains(SurgeADB2CTokenType.accessToken.name)) {
        if (!mounted) return;
        widget.onRedirect();
      } else if (url.contains('code')) {
        _authorizationCodeFlow(url);
      }
    }
  }

  Future<void> _authorizationCodeFlow(String url) async {
    final authCode = url.split('code=')[1];

    await surgeADB2CService
        .getAllTokens(
      redirectUri: widget.redirectUrl,
      clientId: widget.clientId,
      authCode: authCode,
      userFlowName: widget.userFlowName,
      tenantBaseUrl: widget.tenantBaseUrl,
      scopes: _createScopesWithSeparator(widget.scopes, ' '),
      pkcePair: pkcePair,
    )
        .then((value) {
      if (value != null) {
        _handleTokenCallbacks(surgeADB2CTokensResponse: value);
        widget.onRedirect();
      }
    });
  }

  void _handleTokenCallbacks({
    required SurgeADB2CTokensResponse surgeADB2CTokensResponse,
  }) {
    final accessTokenValue = surgeADB2CTokensResponse.accessToken;
    final idTokenValue = surgeADB2CTokensResponse.idToken;
    final refreshTokenValue = surgeADB2CTokensResponse.refreshToken;

    if (accessTokenValue != null) {
      widget.onAccessToken(accessTokenValue);
    }

    if (idTokenValue != null) {
      widget.onIDToken(idTokenValue);
    }

    if (refreshTokenValue != null) {
      widget.onRefreshToken(refreshTokenValue);
    }
  }

  String _getUserFlowUrl({required String userFlow}) {
    final userFlowSplit = userFlow.split('?');
    //Check if the user added the full user flow or just till 'authorize'
    if (userFlowSplit.length == 1) {
      return _concatUserFlow(userFlow);
    }
    return userFlow;
  }

  String _concatUserFlow(String url) {
    const idClientParam = '&client_id=';
    const nonceParam = '&nonce=defaultNonce&redirect_uri=';
    const scopeParam = '&scope=';
    const responseTypeParam = '&response_type=';
    const promptParam = '&prompt=login';
    const pageParam = '?p=';
    const codeChallengeMethod = '&code_challenge_method=S256';
    final codeChallenge = '&code_challenge=${pkcePair.codeChallenge}';

    final newParameters = StringBuffer();
    if (widget.optionalParameters.isNotEmpty) {
      for (final param in widget.optionalParameters.entries) {
        newParameters.write('&${param.key}=${param.value}');
      }
    }

    return url +
        pageParam +
        widget.userFlowName +
        idClientParam +
        widget.clientId +
        nonceParam +
        widget.redirectUrl +
        scopeParam +
        _createScopesWithSeparator(widget.scopes, '%20') +
        responseTypeParam +
        widget.responseType +
        promptParam +
        codeChallenge +
        codeChallengeMethod +
        newParameters.toString();
  }

  String _createScopesWithSeparator(List<String> scopeList, String separator) {
    final allScope = StringBuffer();
    for (final scope in scopeList) {
      allScope
        ..write(scope)
        ..write(separator);
    }
    final result = allScope.toString();
    return result.substring(0, result.length - separator.length);
  }
}
