import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:mosquito_alert_app/core/localizations/my_localizations.dart';
import 'package:mosquito_alert_app/core/utils/style.dart';
import 'package:mosquito_alert_app/core/utils/utils.dart';
import 'package:webview_flutter/webview_flutter.dart';

final Uri _publicMapUri = Uri.parse('https://map.mosquitoalert.com/en');

/// How long the loaded map is kept after the screen is closed.
///
/// Most of the wait is the map's own data request (every report since 2014,
/// several MB, from an API that often takes well over ten seconds to answer),
/// so reopening the map shortly after closing it reuses the loaded page
/// instead of paying that again. The page is then released so the WebView
/// does not hold its memory for the rest of the app session.
const Duration _keepAliveAfterClose = Duration(minutes: 10);

/// WebKit reports a navigation that was superseded by another one as an
/// error (NSURLErrorCancelled); that is not a failed load.
const int _navigationCancelledErrorCode = -999;

class PublicMap extends StatefulWidget {
  const PublicMap({super.key});

  @override
  State<PublicMap> createState() => _PublicMapState();
}

class _PublicMapState extends State<PublicMap> {
  late final _PublicMapSession _session;

  @override
  void initState() {
    super.initState();
    _logScreenView();
    _session = _PublicMapSession.attach();
  }

  @override
  void dispose() {
    _session.detach();
    super.dispose();
  }

  Future<void> _logScreenView() async {
    await FirebaseAnalytics.instance.logScreenView(screenName: '/map');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        centerTitle: true,
        title: Image.asset('assets/img/ic_logo.webp', height: 40),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            WebViewWidget(controller: _session.controller),
            ListenableBuilder(
              listenable: Listenable.merge([
                _session.isLoading,
                _session.progress,
                _session.hasError,
              ]),
              builder: (BuildContext context, _) {
                if (_session.hasError.value) {
                  return _buildError(context);
                }
                if (!_session.isLoading.value) {
                  return const SizedBox.shrink();
                }
                return _buildLoading();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return IgnorePointer(
      child: Stack(
        children: [
          LinearProgressIndicator(
            value: _session.progress.value / 100,
            color: Style.colorPrimary,
            backgroundColor: Colors.transparent,
          ),
          Center(child: Utils.loading(true)),
        ],
      ),
    );
  }

  Widget _buildError(BuildContext context) {
    // Opaque, so the WebView's own error page doesn't show through.
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(24),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off, size: 48, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            MyLocalizations.of(context, 'loading_failed_try_again'),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _session.load,
            child: Text(MyLocalizations.of(context, 'retry')),
          ),
        ],
      ),
    );
  }
}

/// The public map's WebView and its load state, which can outlive a
/// [PublicMap] screen (see [_keepAliveAfterClose]).
class _PublicMapSession {
  _PublicMapSession._({required this.keptAlive}) {
    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            progress.value = 0;
            isLoading.value = true;
          },
          onProgress: (int value) => progress.value = value,
          onPageFinished: (_) => isLoading.value = false,
          onWebResourceError: (WebResourceError error) {
            debugPrint('Public map: $error');
            // Failures of images or API calls inside the page are the map's
            // own business; only a failed page load gets the retry screen.
            if (error.isForMainFrame == true &&
                error.errorCode != _navigationCancelledErrorCode) {
              hasError.value = true;
            }
          },
          onHttpError: (HttpResponseError error) {
            // Android reports every resource along with its URL; iOS only
            // reports page navigations, without one.
            final Uri? uri = error.request?.uri;
            if (uri == null || uri == _publicMapUri) {
              hasError.value = true;
            }
          },
        ),
      );
    load();
  }

  static _PublicMapSession? _keptAliveSession;
  static bool _keptAliveSessionAttached = false;
  static Timer? _releaseTimer;

  /// Returns the kept-alive session, creating it if needed.
  static _PublicMapSession attach() {
    if (_keptAliveSessionAttached) {
      // A native view can only be shown in one place, so a second map screen
      // (e.g. pushed by a double tap) gets a WebView of its own.
      return _PublicMapSession._(keptAlive: false);
    }
    _releaseTimer?.cancel();
    _releaseTimer = null;
    _keptAliveSessionAttached = true;
    final session = _keptAliveSession ??= _PublicMapSession._(keptAlive: true);
    if (session.hasError.value) {
      session.load();
    }
    return session;
  }

  final bool keptAlive;
  late final WebViewController controller;
  final ValueNotifier<bool> isLoading = ValueNotifier<bool>(true);
  final ValueNotifier<int> progress = ValueNotifier<int>(0);
  final ValueNotifier<bool> hasError = ValueNotifier<bool>(false);

  void load() {
    hasError.value = false;
    isLoading.value = true;
    progress.value = 0;
    controller.loadRequest(_publicMapUri);
  }

  void detach() {
    if (!keptAlive) {
      _unload();
      return;
    }
    _keptAliveSessionAttached = false;
    _releaseTimer = Timer(_keepAliveAfterClose, () {
      _releaseTimer = null;
      _keptAliveSession = null;
      _unload();
    });
  }

  /// Frees the page's memory now; the WebView itself is destroyed once the
  /// controller is garbage collected.
  void _unload() {
    controller.loadRequest(Uri.parse('about:blank'));
  }
}
