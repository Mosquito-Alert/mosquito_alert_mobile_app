import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mosquito_alert_app/utils/Utils.dart';
import 'package:webview_flutter/webview_flutter.dart';

class PublicMap extends StatefulWidget {
  @override
  _PublicMapState createState() => _PublicMapState();
}

class _PublicMapState extends State<PublicMap> {
  late WebViewController _controller;
  StreamController<bool> loadingStream = StreamController<bool>.broadcast();

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
          },
          onPageFinished: (String url) {
            loadingStream.add(false);
          },
          onWebResourceError: (WebResourceError error) {
            print(error);
          },
        ),
      );

      _controller.loadRequest(Uri.parse('https://map.mosquitoalert.com'));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        centerTitle: true,
        title: Image.asset(
          'assets/img/ic_logo.png',
          height: 40,
        ),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Builder(builder: (BuildContext context) {
              return WebViewWidget(
                controller: _controller,
              );
            }),
            StreamBuilder<bool>(
              stream: loadingStream.stream,
              initialData: true,
              builder: (BuildContext context, AsyncSnapshot<bool> snapLoading) {
                if (snapLoading.data != true) {
                  return Container();
                }

                return Container(
                  child: Center(
                    child: Utils.loading(true),
                  ),
                );
              }
            ),
          ],
        ),
      ),
    );
  }
}