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
  final PkcePair pkcePair = PkcePair.generate();
  final UniqueKey _key = UniqueKey();
  bool isLoading = true;

  SurgeADB2CWebViewState() : surgeADB2CService = SurgeADB2CService(Dio());

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
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Stack(
        children: [
          _buildWebView(),
          if (isLoading) _buildLoadingIndicator(),
        ],
      ),
    );
  }

  InAppWebView _buildWebView() {
    return InAppWebView(
      key: _key,
      initialUrlRequest: URLRequest(
        url: WebUri(_getUserFlowUrl()),
      ),
      initialSettings: InAppWebViewSettings(
        useShouldOverrideUrlLoading: true,
        cacheEnabled: false,
        cacheMode: CacheMode.LOAD_NO_CACHE,
        clearCache: true,
        clearSessionCache: true,
      ),
      shouldOverrideUrlLoading: _handleUrlLoading,
      onLoadStop: _onLoadStop,
    );
  }

  Center _buildLoadingIndicator() {
    return Center(
      child: CircularProgressIndicator(),
    );
  }

  Future<NavigationActionPolicy> _handleUrlLoading(
      InAppWebViewController controller,
      NavigationAction navigationAction) async {
    final uri = navigationAction.request.url!;
    final url = uri.toString();
    if (url.contains('${widget.redirectUrl}?code')) {
      final response = Uri.dataFromString(url);
      _onPageFinishedTasks(url, response);
      return NavigationActionPolicy.CANCEL;
    }
    return NavigationActionPolicy.ALLOW;
  }

  void _onLoadStop(InAppWebViewController controller, Uri? url) {
    controller.evaluateJavascript(source: _scrollToInputScript());
    setState(() {
      isLoading = false;
    });
  }

  String _scrollToInputScript() {
    return """
      document.addEventListener('focusin', function(event) {
        if (event.target.tagName === 'INPUT' || event.target.tagName === 'TEXTAREA') {
          setTimeout(() => {
            event.target.scrollIntoView({behavior: 'smooth', block: 'end'});
          }, 800);
        }
      });
    """;
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
    final tokensResponse = await surgeADB2CService.getAllTokens(
      redirectUri: widget.redirectUrl,
      clientId: widget.clientId,
      authCode: authCode,
      userFlowName: widget.userFlowName,
      tenantBaseUrl: widget.tenantBaseUrl,
      scopes: widget.scopes.join(' '),
      pkcePair: pkcePair,
    );

    if (tokensResponse != null) {
      _handleTokenCallbacks(tokensResponse);
      widget.onRedirect();
    }
  }

  void _handleTokenCallbacks(SurgeADB2CTokensResponse tokensResponse) {
    if (tokensResponse.accessToken != null) {
      widget.onAccessToken(tokensResponse.accessToken!);
    }
    if (tokensResponse.idToken != null) {
      widget.onIDToken(tokensResponse.idToken!);
    }
    if (tokensResponse.refreshToken != null) {
      widget.onRefreshToken(tokensResponse.refreshToken!);
    }
  }

  String _getUserFlowUrl() {
    final userFlow = '${widget.tenantBaseUrl}/oauth2/v2.0/authorize';
    final userFlowSplit = userFlow.split('?');
    return userFlowSplit.length == 1 ? _concatUserFlow(userFlow) : userFlow;
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
      widget.optionalParameters.forEach((key, value) {
        newParameters.write('&$key=$value');
      });
    }

    return url +
        pageParam +
        widget.userFlowName +
        idClientParam +
        widget.clientId +
        nonceParam +
        widget.redirectUrl +
        scopeParam +
        widget.scopes.join('%20') +
        responseTypeParam +
        widget.responseType +
        promptParam +
        codeChallenge +
        codeChallengeMethod +
        newParameters.toString();
  }
}
