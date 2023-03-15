import 'package:flutter/foundation.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter/material.dart';

class TohruWebView {
  static final TohruWebView _instance = TohruWebView._(); //Singletone
  static const String tohruURL = 'https://tohru.3gpp.org';
  late final Function(int) onProgress;
  late final Function(String) onPageStarted;
  late final Function(String) onPageFinished;
  late final WebViewController webViewController;

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
      // onProgress: (int progress) {
      //   onProgress(progress);
      //   // Update loading bar.
      // }, //not supported in windows environment
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
        if (!request.url.startsWith(tohruURL)) {
          if (kDebugMode) {
            print("Not tohru. Stop to URL");
          }
          return NavigationDecision.prevent;
        }
        if (kDebugMode) {
          print("It is tohru. go to URL");
        }
        return NavigationDecision.navigate;
      },
    );
    webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      // ..enableZoom(true)
      ..setNavigationDelegate(navDelegate)
      ..setBackgroundColor(Colors.white)
      ..loadRequest(Uri.parse(tohruURL));
  }

  Future<void> loadRequest(Uri url) async {
    webViewController.loadRequest(url);
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
}
