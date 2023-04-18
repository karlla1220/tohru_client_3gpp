import 'package:flutter/foundation.dart';
import 'package:tohru_client_3gpp/main.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class TohruWebView {
  static final TohruWebView _instance = TohruWebView._(); //Singletone
  // String tohruURL = 'https://www.google.com';
  String tohruURL = 'about:blank';
  // String tohruURL = '/';

  late final Function(int) onProgress;
  late final Function(String) onPageStarted;
  late final Function(String) onPageFinished;
  late final WebViewController webViewController;
  late final WebViewCookieManager webViewCookieManager;

  late final WebViewWidget webViewWidget;

  factory TohruWebView({
    required Function(int) onProgress,
    required Function(String) onPageStarted,
    required Function(String) onPageFinished,
  }) {
    _instance
      ..onProgress = onProgress
      ..onPageStarted = onPageStarted
      ..onPageFinished = onPageFinished;
    return _instance;
  }

  static TohruWebView getInstance() {
    return _instance;
  }

  TohruWebView._() {
    final navDelegate = NavigationDelegate(
      onProgress: (int progress) {
        onProgress(progress);
        // Update loading bar.
      },
      onPageStarted: (String url) async {
        if (kDebugMode) {
          print("Start to load Webpage");
        }
        onPageStarted(url);
      },
      onPageFinished: (String url) async {
        if (kDebugMode) {
          print("Finish to load Webpage");
        }
        onPageFinished(url);
      },
      onWebResourceError: (WebResourceError error) {},
      onNavigationRequest: (NavigationRequest request) {
        printDebug("[onNavigationRequest] Check URL in onNavigationRequest");

        if (!request.url.contains("tohru") &&
            !request.url.contains("about:blank") &&
            !request.url.contains("hand") &&
            !request.url.contains("rasi")) {
          printDebug("Not tohru. Stop to URL");
          return NavigationDecision.prevent;
        }
        printDebug("It is tohru. go to URL");
        return NavigationDecision.navigate;
      },
    );
    webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..enableZoom(true)
      ..setNavigationDelegate(navDelegate)
      ..setBackgroundColor(Colors.white)
      ..loadRequest(Uri.parse(tohruURL));

    webViewCookieManager = WebViewCookieManager();

    webViewWidget = WebViewWidget(controller: webViewController);
  }

  //getter of webViewWidget
  WebViewWidget getWebViewWidget() {
    return webViewWidget;
  }

  Future<void> loadRequest(Uri url) async {
    webViewController.loadRequest(url);
  }

  Future<void> clearCache() async {
    webViewController.clearCache();
  }

  Future<void> clearCacheAndCookies() async {
    webViewCookieManager.clearCookies();
    webViewController.clearCache();
    final cookies = await runJavaScriptReturningResult(
      'document.cookie',
    );
    printDebug("cookies : ");
    printDebug(cookies);
  }

  // method for getting URL and load the URL
  Future<void> loadUrl(String url) async {
    if (url.startsWith('about:')) {
      tohruURL = url;
      loadRequest(Uri.parse(tohruURL));
      return;
    }

    String scheme = 'https';
    tohruURL = '$scheme://$url';

    try {
      final uri = Uri.parse(tohruURL);

      // Check if HTTPS is available
      final response = await http.head(Uri.https(uri.host, uri.path));
      if (response.statusCode != 200) {
        // HTTPS didn't work, use HTTP instead
        scheme = 'http';
      }
    } catch (e) {
      // Invalid URL or HTTPS didn't work - use HTTP instead
      scheme = 'http';
    }

    tohruURL = '$scheme://$url';
    loadRequest(Uri.parse(tohruURL));
  }

  Future<Object> runJavaScriptReturningResult(String javascript) async {
    return webViewController.runJavaScriptReturningResult(javascript);
  }

  Future<void> runJavaScript(String javascript) async {
    return webViewController.runJavaScript(javascript);
  }

  void setJavaScriptMode(JavaScriptMode? mode) {
    webViewController.setJavaScriptMode(mode ?? JavaScriptMode.disabled);
  }

  void enableZoom(bool enabled) {
    webViewController.enableZoom(enabled);
  }

  void setNavigationDelegate(NavigationDelegate delegate) {
    webViewController.setNavigationDelegate(delegate);
  }

  Future<void> reload() async {
    webViewController.reload();
  }
}
