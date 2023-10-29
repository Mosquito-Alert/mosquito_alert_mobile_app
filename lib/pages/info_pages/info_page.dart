import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mosquito_alert_app/utils/Utils.dart';
import 'package:webview_flutter/webview_flutter.dart';

class InfoPage extends StatefulWidget {
  final String? url;
  final bool localHtml;

  InfoPage(this.url, {this.localHtml = false});

  @override
  _InfoPageState createState() => _InfoPageState();
}

class _InfoPageState extends State<InfoPage> {
  late WebViewController _controller;
  var title;

  StreamController<bool> loadingStream = StreamController<bool>.broadcast();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.white,
            centerTitle: true,
            title: title == null ? Image.asset(
              'assets/img/ic_logo.png',
              height: 45,
            ) : Text(title),
          ),
          body: SafeArea(child: Stack(
            children: [
              Builder(builder: (BuildContext context) {
                return WebView(
                  initialUrl: widget.localHtml ? 'about:blank' : widget.url,
                  javascriptMode: JavascriptMode.unrestricted,
                  onWebViewCreated: (WebViewController webViewController) {
                    _controller = webViewController;
                    widget.localHtml ? _loadHtmlFromAssets() : null;
                  },
                  javascriptChannels: <JavascriptChannel>[
                    _toasterJavascriptChannel(context),
                  ].toSet(),
                  onPageFinished: (String url) {
                    loadingStream.add(false);
                  },
                  onPageStarted: (String url) {
                    loadingStream.add(true);
                  },
                  gestureNavigationEnabled: true,
                );
              }),
              StreamBuilder<bool>(
                  stream: loadingStream.stream,
                  initialData: true,
                  builder:
                      (BuildContext context, AsyncSnapshot<bool> snapLoading) {
                    if (snapLoading.data == true) {
                      return Container(
                        child: Center(
                          child: Utils.loading(true),
                        ),
                      );
                    }
                    return Container();
                  }),
            ],
          ),),
        ),
      ],
    );
  }

  JavascriptChannel _toasterJavascriptChannel(BuildContext context) {
    return JavascriptChannel(
        name: 'Toaster',
        onMessageReceived: (JavascriptMessage message) {
          Scaffold.of(context).showSnackBar(
            SnackBar(content: Text(message.message)),
          );
        });
  }

  void _loadHtmlFromAssets() async {
    var fileText = await rootBundle.loadString(widget.url!);
    await _controller.loadUrl(Uri.dataFromString(fileText,
            mimeType: 'text/html', encoding: Encoding.getByName('utf-8'))
        .toString());
  }
}
