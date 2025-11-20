import 'dart:async';

import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart' as html;
import 'package:mosquito_alert/mosquito_alert.dart' as sdk;
import 'package:mosquito_alert_app/providers/notification_provider.dart';
import 'package:provider/provider.dart';
import 'package:mosquito_alert_app/utils/style.dart';
import 'package:mosquito_alert_app/utils/html_parser.dart';

class NotificationDetailPage extends StatefulWidget {
  final sdk.Notification notification;

  const NotificationDetailPage({
    super.key,
    required this.notification,
  });

  static Future<NotificationDetailPage> fromId(
      {required BuildContext context,
      required int notificationId,
      bool refresh = false}) async {
    final notificationProvider = context.read<NotificationProvider>();
    if (refresh) {
      // Run refresh in the background without blocking
      unawaited(
        Future(() async {
          await notificationProvider.refresh();
        }),
      );
    }

    final notification = await notificationProvider.getById(id: notificationId);

    return NotificationDetailPage(
      notification: notification!,
    );
  }

  @override
  State<NotificationDetailPage> createState() => _NotificationDetailPageState();
}

class _NotificationDetailPageState extends State<NotificationDetailPage> {
  late sdk.Notification _notification; // local mutable copy

  @override
  void initState() {
    super.initState();
    _notification = widget.notification;

    WidgetsBinding.instance.addPostFrameCallback((_) => context
        .read<NotificationProvider>()
        .markAsRead(notification: _notification));
  }

  String get formattedDate {
    final date = _notification.createdAt.toLocal();
    return DateFormat.yMMMd().addPattern('•').add_jm().format(date);
  }

  @override
  Widget build(BuildContext context) {
    final title = _notification.message.title;
    final body = _notification.message.body;

    return Scaffold(
      appBar: AppBar(
          backgroundColor: Colors.white,
          centerTitle: false,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(60.0),
            child: Container(
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.only(left: 16.0),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: Style.colorPrimary,
                        fontSize: 20.0,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      formattedDate,
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 12.0,
                      ),
                    )
                  ]),
            ),
          )),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: SelectionArea(
            child: html.Html(
              data: prepareHtmlBody(body),
              style: {
                '*': html.Style(
                  padding: html.HtmlPaddings.zero,
                  margin: html.Margins.zero,
                ),
              },
            ),
          ),
        ),
      ),
    );
  }
}
