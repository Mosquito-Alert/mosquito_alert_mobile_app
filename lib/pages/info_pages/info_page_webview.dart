import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mosquito_alert_app/utils/Utils.dart';
import 'package:webview_flutter/webview_flutter.dart';

class InfoPageInWebview extends StatefulWidget {
  final String? url;
  final bool localHtml;

  InfoPageInWebview(this.url, {this.localHtml = false});

  @override
  _InfoPageInWebviewState createState() => _InfoPageInWebviewState();
}

class _InfoPageInWebviewState extends State<InfoPageInWebview> {
  var title;

  StreamController<bool> loadingStream = StreamController<bool>.broadcast();

  late WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            loadingStream.add(true);
          },
          onPageFinished: (String url) {
            loadingStream.add(false);
          },
          onWebResourceError: (WebResourceError error) {
            print(error);
          },
        ),
      );

      if (widget.localHtml) {
        _loadHtmlFromAssets();
      } else {
        _controller.loadRequest(Uri.parse(widget.url ?? 'https://www.mosquitoalert.com/'));
      }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.white,
            centerTitle: true,
            title: title == null
                ? Image.asset(
                    'assets/img/ic_logo.png',
                    height: 45,
                  )
                : Text(title),
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
                    builder: (BuildContext context,
                        AsyncSnapshot<bool> snapLoading) {
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
            ),
          ),
        ),
      ],
    );
  }

  void _loadHtmlFromAssets() async {
    loadingStream.add(true);
    var fileText = await rootBundle.loadString(widget.url!);
    try {
      await _controller.loadRequest(
        Uri.dataFromString(
          fileText,
          mimeType: 'text/html',
          encoding: Encoding.getByName('utf-8')
        )
      );
    } catch (e) {
      print('Error loading local HTML: $e');
    }
    loadingStream.add(false);
  }
}
