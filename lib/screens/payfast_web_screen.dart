import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class PayfastWebScreen extends StatefulWidget {
  final String paymentToken;
  final bool isCardRegistration;

  const PayfastWebScreen({
    Key? key,
    required this.paymentToken,
    this.isCardRegistration = false,
  }) : super(key: key);

  @override
  State<PayfastWebScreen> createState() => _PayfastWebScreenState();
}

class _PayfastWebScreenState extends State<PayfastWebScreen> {
  InAppWebViewController? _webViewController;
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  bool _resultHandled = false;

  // Mirror of PayFastWebActivity JS bridge
  String get _paymentHtml => '''
<!DOCTYPE html>
<html><head>
<meta name='viewport' content='width=device-width, initial-scale=1.0'>
<script src='https://www.payfast.co.za/onsite/engine.js'></script>
</head><body>
<script>
window.onload = function() {
  try {
    window.payfast_do_onsite_payment(
      { uuid: '${widget.paymentToken}' },
      function(result) {
        if (result === true) {
          if (window.flutter_inappwebview) {
            window.flutter_inappwebview.callHandler('onPaymentComplete');
          }
        } else {
          if (window.flutter_inappwebview) {
            window.flutter_inappwebview.callHandler('onPaymentCancelled');
          }
        }
      }
    );
  } catch(e) {
    document.body.innerHTML = '<h3 style="color:red">Payment failed to load. Please try again.</h3>';
  }
};
</script>
</body></html>
''';

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        _handlePaymentCancelled();
        return true;
      },
      child: Scaffold(
        body: Stack(
          children: [
            if (!_hasError)
              InAppWebView(
                initialData: InAppWebViewInitialData(
                  data: _paymentHtml,
                  baseUrl: WebUri('https://www.payfast.co.za/'),
                  mimeType: 'text/html',
                  encoding: 'UTF-8',
                ),
                initialSettings: InAppWebViewSettings(
                  javaScriptEnabled: true,
                  domStorageEnabled: true,
                  databaseEnabled: true,
                  allowFileAccess: true,
                  mixedContentMode: MixedContentMode.MIXED_CONTENT_ALWAYS_ALLOW,
                  cacheMode: CacheMode.LOAD_NO_CACHE,
                  thirdPartyCookiesEnabled: true,
                  useHybridComposition: true,
                ),
                onWebViewCreated: (controller) {
                  _webViewController = controller;

                  // JS bridge — mirrors PayFastJsBridge in Java
                  controller.addJavaScriptHandler(
                    handlerName: 'onPaymentComplete',
                    callback: (_) => _handlePaymentSuccess(),
                  );
                  controller.addJavaScriptHandler(
                    handlerName: 'onPaymentCancelled',
                    callback: (_) => _handlePaymentCancelled(),
                  );
                },
                onLoadStart: (controller, url) {
                  setState(() => _isLoading = true);
                  // Safety-net URL check (mirrors handleUrl in Java)
                  final urlStr = url?.toString() ?? '';
                  if (urlStr.contains('payment-success')) {
                    _handlePaymentSuccess();
                  } else if (urlStr.contains('payment-cancelled')) {
                    _handlePaymentCancelled();
                  }
                },
                onLoadStop: (controller, url) {
                  setState(() => _isLoading = false);
                  final urlStr = url?.toString() ?? '';
                  if (urlStr.contains('payment-success')) {
                    _handlePaymentSuccess();
                  } else if (urlStr.contains('payment-cancelled')) {
                    _handlePaymentCancelled();
                  }
                },
                onReceivedError: (controller, request, error) {
                  if (request.isForMainFrame == true) {
                    setState(() {
                      _isLoading = false;
                      _hasError = true;
                      _errorMessage =
                          'Network error: Cannot connect to PayFast. Please check your internet connection and try again.';
                    });
                  }
                },
                shouldOverrideUrlLoading:
                    (controller, navigationAction) async {
                  final url =
                      navigationAction.request.url?.toString() ?? '';
                  if (url.contains('payment-success')) {
                    _handlePaymentSuccess();
                    return NavigationActionPolicy.CANCEL;
                  }
                  if (url.contains('payment-cancelled')) {
                    _handlePaymentCancelled();
                    return NavigationActionPolicy.CANCEL;
                  }
                  return NavigationActionPolicy.ALLOW;
                },
              ),

            // Loading overlay
            if (_isLoading && !_hasError)
              Container(
                color: Colors.black54,
                child: const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: Colors.white),
                      SizedBox(height: 16),
                      Text('Processing payment...',
                          style: TextStyle(color: Colors.white)),
                    ],
                  ),
                ),
              ),

            // Error state — mirrors showError() in Java
            if (_hasError)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _errorMessage,
                        textAlign: TextAlign.center,
                        style:
                            const TextStyle(fontSize: 16, color: Colors.red),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _hasError = false;
                                _isLoading = true;
                                _resultHandled = false;
                              });
                              _webViewController?.loadData(
                                data: _paymentHtml,
                                baseUrl:
                                    WebUri('https://www.payfast.co.za/'),
                                mimeType: 'text/html',
                                encoding: 'UTF-8',
                              );
                            },
                            child: const Text('Confirm'),
                          ),
                          const SizedBox(width: 16),
                          OutlinedButton(
                            onPressed: () {
                              if (!_resultHandled) {
                                _resultHandled = true;
                                Navigator.pop(context, false);
                              }
                            },
                            child: const Text('Close'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _handlePaymentSuccess() {
    if (_resultHandled) return;
    _resultHandled = true;
    if (mounted) Navigator.pop(context, true);
  }

  void _handlePaymentCancelled() {
    if (_resultHandled) return;
    _resultHandled = true;
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment cancelled')));
      Navigator.pop(context, false);
    }
  }
}