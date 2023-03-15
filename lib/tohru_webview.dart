import 'dart:async';

import 'package:tohru_client_3gpp/main.dart';
import 'package:webview_windows/webview_windows.dart' as ww;
import 'package:flutter/material.dart';

//모든 webview 종속성을 이곳에서 관리

class TohruWebView {
  static const String tohruURL = 'https://tohru.3gpp.org';
  final Function(int) onProgress;
  final Function(String) onPageStarted;
  final Function(String) onPageFinished;
  final ww.WebviewController webViewController = ww.WebviewController();

  //dispose function
  void dispose() {
    webViewController.dispose();
  }

  TohruWebView({
    required this.onProgress,
    required this.onPageStarted,
    required this.onPageFinished,
  }) {
    webViewinit();
  }

  //constructor of this class

  //fuction to create webview widget
  Widget createWebView() {
    return ww.Webview(webViewController);
  }

  void webViewinit() async {
    webViewController.loadingState.listen((event) {
      if (event == ww.LoadingState.loading) {
        // webViewController.url.last.then((value) {
        onPageStarted(tohruURL);
        // });
      } else if (event == ww.LoadingState.navigationCompleted) {
        // webViewController.url.last.then((value) {
        onPageFinished(tohruURL);
        // });
      }
    });

    await webViewController.initialize();
    printDebug("End of webview init");
    await webViewController.setBackgroundColor(Colors.white);
    await webViewController
        .setPopupWindowPolicy(ww.WebviewPopupWindowPolicy.deny);
    printDebug("start of load request");
    await loadRequest(Uri.parse(tohruURL));
    printDebug("end of load request");
  }

  Future<void> loadRequest(Uri url) async {
    // webViewController.loadRequest(url);
    await webViewController.loadUrl(url.toString());
  }

  Future<Object> runJavaScriptReturningResult(String javascript) async {
    return await webViewController.executeScript(javascript);
  }

  Future<void> runJavaScript(String javascript) async {
    await webViewController.executeScript(javascript);
  }

  // void setJavaScriptMode(JavaScriptMode? mode) {
  // webViewController.setJavaScriptMode(mode ?? JavaScriptMode.disabled);
  // }

  // void enableZoom(bool enabled) {
  //   // webViewController.enableZoom(enabled);
  // }

  // void setNavigationDelegate(NavigationDelegate delegate) {
  //   webViewController.setNavigationDelegate(delegate);
  //   webViewController.
  // }

  //reload function on webview
  Future<void> reload() async {
    await webViewController.reload();
  }
}
