import 'dart:math';

import 'package:flutter/material.dart';
import 'package:webviewx/webviewx.dart';

class TohruWebViewPage extends StatefulWidget {
  TohruWebViewPage({
    required onPageStarted,
    required onPageFinished,
    required webviewController,
    Key? key,
  }) : super(key: key);

  final void Function(String) onPageStarted;
  final void Function(String) onPageFinished;

  late WebViewXController webviewController;

  @override
  State<TohruWebViewPage> createState() => _TohruWebViewPageState();
}

class _TohruWebViewPageState extends State<TohruWebViewPage> {
  static const String tohruURL = 'https://tohru.3gpp.org';

  late WebViewXController webviewController = widget.webviewController;

  // final initialContent =
  //     '<h4> This is some hardcoded HTML code embedded inside the webview <h4> <h2> Hello world! <h2>';
  // final executeJsErrorMessage =
  //     'Failed to execute this task because the current content is (probably) URL that allows iframe embedding, on Web.\n\n'
  //     'A short reason for this is that, when a normal URL is embedded in the iframe, you do not actually own that content so you cant call your custom functions\n'
  //     '(read the documentation to find out why).';
  Size get screenSize => MediaQuery.of(context).size;

  @override
  void dispose() {
    webviewController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WebViewX(
      height: screenSize.height,
      width: screenSize.width,
      key: const ValueKey('webviewx'),
      initialContent: tohruURL,
      initialSourceType: SourceType.url,
      onWebViewCreated: (controller) => webviewController = controller,
      onPageStarted: widget.onPageStarted,
      onPageFinished: widget.onPageFinished,
      jsContent: const {
        EmbeddedJsContent(
          js: "function testPlatformIndependentMethod() { console.log('Hi from JS') }",
        ),
        EmbeddedJsContent(
          webJs:
              "function testPlatformSpecificMethod(msg) { TestDartCallback('Web callback says: ' + msg) }",
          mobileJs:
              "function testPlatformSpecificMethod(msg) { TestDartCallback.postMessage('Mobile callback says: ' + msg) }",
        ),
      },
      dartCallBacks: {
        DartCallback(
          name: 'TestDartCallback',
          callBack: (msg) => (print(msg.toString())),
        )
      },
      webSpecificParams: const WebSpecificParams(
        printDebugInfo: true,
      ),
      mobileSpecificParams: const MobileSpecificParams(
        androidEnableHybridComposition: true,
      ),
      navigationDelegate: (navigation) {
        debugPrint(navigation.content.sourceType.toString());
        return NavigationDecision.navigate;
      },
    );
  }

  Future<Object> runJavaScriptReturningResult(String javascript) async {
    // return webViewController.runJavaScriptReturningResult(javascript);
  }

  Future<void> runJavaScript(String javascript) async {
    // return webViewController.runJavaScript(javascript);
  }
}
















// class TohruWebView {
//   static final TohruWebView _instance = TohruWebView._(); //Singletone
//   late final Function(int) onProgress;

//   late final WebViewXController webViewController;

//   factory TohruWebView({
//     required Function(int) onProgress,
//     required Function(String) onPageStarted,
//     required Function(String) onPageFinished,
//   }) {
//     _instance
//       ..onProgress = onProgress
//       ..onPageStarted = onPageStarted
//       ..onPageFinished = onPageFinished;
//     return _instance;
//   }

//   static TohruWebView getInstance() {
//     return _instance;
//   }

//   // void dispose() {
//   //   webViewController.runJavaScript("MainScreen.down();)");
//   // }

//   TohruWebView._() {
//     final navDelegate = NavigationDelegate(
//       onProgress: (int progress) {
//         onProgress(progress);
//         // Update loading bar.
//       },
//       onPageStarted: (String url) async {
//         if (kDebugMode) {
//           print("Start to load Webpage");
//         }
//         onPageStarted(url);
//       },
//       onPageFinished: (String url) async {
//         if (kDebugMode) {
//           print("Finish to load Webpage");
//         }
//         onPageFinished(url);
//       },
//       onWebResourceError: (WebResourceError error) {},
//       onNavigationRequest: (NavigationRequest request) {
//         // if (!request.url.startsWith(tohruURL)) {
//         //   if (kDebugMode) {
//         //     print("Not tohru. Stop to URL");
//         //   }
//         //   return NavigationDecision.prevent;
//         // }
//         // if (kDebugMode) {
//         //   print("It is tohru. go to URL");
//         // }
//         // return NavigationDecision.navigate;
//       },
//     );
//     webViewController = WebViewXController()
    
    
//     webviewController.loadContent(
//     'https://flutter.dev',
//     SourceType.url,
// );
      
//       // ..setJavaScriptMode(JavaScriptMode.unrestricted)
//       // ..enableZoom(true)
//       // ..setNavigationDelegate(navDelegate)
//       // ..loadRequest(Uri.parse(tohruURL));
//   }

//   Future<void> loadRequest(String content) async {
//     webViewController.loadContent(content, SourceType.url);
//   }

//   Future<Object> runJavaScriptReturningResult(String javascript) async {
//     // return webViewController.runJavaScriptReturningResult(javascript);
//   }

//   Future<void> runJavaScript(String javascript) async {
//     // return webViewController.runJavaScript(javascript);
//   }

//   void setJavaScriptMode(JavaScriptMode? mode) {

//     webViewController.JavascriptMode(mode ?? JavaScriptMode.disabled);
//   }

//   void enableZoom(bool enabled) {
//     // webViewController.enableZoom(enabled);
//   }

//   void setNavigationDelegate(NavigationDelegate delegate) {
//     // webViewController.setNavigationDelegate(delegate);
//   }
// }
