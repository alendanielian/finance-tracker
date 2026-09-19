import 'dart:async';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../l10n/app_strings.dart';

const privacyPolicyUrl =
    'https://sites.google.com/view/finance-tracker-alen-privacy/';

class PrivacyPolicyScreen extends StatefulWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  State<PrivacyPolicyScreen> createState() => _PrivacyPolicyScreenState();
}

class _PrivacyPolicyScreenState extends State<PrivacyPolicyScreen> {
  late final WebViewController _controller;
  double _progress = 0;
  bool _loading = true;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (progress) {
            if (!mounted || _failed) return;
            setState(() => _progress = progress / 100);
          },
          onPageStarted: (_) {
            if (!mounted) return;
            setState(() {
              _loading = true;
              _progress = 0;
            });
          },
          onPageFinished: (_) {
            if (!mounted || _failed) return;
            setState(() {
              _loading = false;
              _progress = 1;
            });
          },
          onWebResourceError: (error) {
            // A missing image or other subresource must not hide the policy.
            if (error.isForMainFrame != true || !mounted) return;
            setState(() {
              _loading = false;
              _failed = true;
            });
          },
        ),
      );
    unawaited(_loadPolicy());
  }

  Future<void> _loadPolicy() async {
    setState(() {
      _loading = true;
      _failed = false;
      _progress = 0;
    });
    try {
      await _controller.loadRequest(Uri.parse(privacyPolicyUrl));
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _failed = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(strings.t('privacy'))),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_loading && !_failed)
            Align(
              alignment: Alignment.topCenter,
              child: LinearProgressIndicator(value: _progress),
            ),
          if (_failed)
            Positioned.fill(
              child: ColoredBox(
                color: Theme.of(context).scaffoldBackgroundColor,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.wifi_off_rounded, size: 48),
                      const SizedBox(height: 16),
                      Text(strings.t('privacyLoadError')),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: _loadPolicy,
                        icon: const Icon(Icons.refresh_rounded),
                        label: Text(strings.t('retry')),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
