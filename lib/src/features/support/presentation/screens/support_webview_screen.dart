import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class SupportWebViewScreen extends StatefulWidget {
  final String supportUrl;

  const SupportWebViewScreen({
    super.key,
    // Default to a placeholder or specific Tawk.to direct chat link
    // Replace heavily with your actual Tawk.to direct chat link
    this.supportUrl = 'https://tawk.to/chat/67b4d1b72e50337c7689fc7d/1ikcpovde',
  });

  @override
  State<SupportWebViewScreen> createState() => _SupportWebViewScreenState();
}

class _SupportWebViewScreenState extends State<SupportWebViewScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() => _isLoading = true);
          },
          onPageFinished: (String url) {
            setState(() => _isLoading = false);
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint('WebView error: ${error.description}');
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.supportUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Help & Support')),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading) const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}
