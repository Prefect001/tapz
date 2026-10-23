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
  // Set to true ONLY if your Cloud Function creates the payment in sandbox.
  static const bool _useSandbox = false;

  InAppWebViewController? _webViewController;

  bool _isLoading = true;
  bool _hasError = false;
  bool _resultHandled = false;

  String _errorMessage = '';

  // PayFast hosted payment page, loaded as a normal top-level page
  // (no iframe, no injected HTML, no JS handlers) so Apple Pay can show.
  String get _hostedUrl {
    final host = _useSandbox ? 'sandbox.payfast.co.za' : 'www.payfast.co.za';
    return 'https://$host/eng/process/payment/${widget.paymentToken}';
  }

  URLRequest get _hostedRequest => URLRequest(url: WebUri(_hostedUrl));

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        _handlePaymentCancelled();
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Secure Payment'),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: _handlePaymentCancelled,
          ),
        ),
        body: SafeArea(
          child: Stack(
            children: [
              // WEBVIEW
              if (!_hasError)
                InAppWebView(
                  initialUrlRequest: _hostedRequest,
                  initialSettings: InAppWebViewSettings(
                    javaScriptEnabled: true,
                    thirdPartyCookiesEnabled: true,
                    // Enables the Apple Pay API in WKWebView (iOS 13+)
                    applePayAPIEnabled: true,
                  ),

                  onWebViewCreated: (controller) {
                    _webViewController = controller;
                    // NOTE: no JavaScript handlers on purpose. With
                    // applePayAPIEnabled the plugin's script injection is
                    // limited. Results are detected via URL checks below.
                  },

                  onLoadStart: (controller, url) {
                    setState(() {
                      _isLoading = true;
                    });

                    final urlStr = url?.toString() ?? '';

                    if (urlStr.contains('payment-success')) {
                      _handlePaymentSuccess();
                    }

                    if (urlStr.contains('payment-cancelled')) {
                      _handlePaymentCancelled();
                    }
                  },

                  onLoadStop: (controller, url) {
                    setState(() {
                      _isLoading = false;
                    });

                    final urlStr = url?.toString() ?? '';

                    if (urlStr.contains('payment-success')) {
                      _handlePaymentSuccess();
                    }

                    if (urlStr.contains('payment-cancelled')) {
                      _handlePaymentCancelled();
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

                  onReceivedError: (controller, request, error) {
                    if (request.isForMainFrame == true) {
                      setState(() {
                        _isLoading = false;
                        _hasError = true;

                        _errorMessage =
                            'Network error: Cannot connect to PayFast.\n\nPlease check your internet connection and try again.';
                      });
                    }
                  },
                ),

              // LOADING OVERLAY
              if (_isLoading && !_hasError)
                Container(
                  color: Colors.black54,
                  child: const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(
                          color: Colors.white,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Loading secure payment...',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // ERROR UI
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
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.red,
                          ),
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

                                // The InAppWebView is rebuilt when _hasError
                                // flips back to false, and it loads
                                // initialUrlRequest again by itself.
                                _webViewController?.loadUrl(
                                  urlRequest: _hostedRequest,
                                );
                              },
                              child: const Text('Retry'),
                            ),
                            const SizedBox(width: 16),
                            OutlinedButton(
                              onPressed: _handlePaymentCancelled,
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
      ),
    );
  }

  void _handlePaymentSuccess() {
    if (_resultHandled) return;

    _resultHandled = true;

    if (mounted) {
      Navigator.pop(context, true);
    }
  }

  void _handlePaymentCancelled() {
    if (_resultHandled) return;

    _resultHandled = true;

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Payment cancelled'),
        ),
      );

      Navigator.pop(context, false);
    }
  }
}