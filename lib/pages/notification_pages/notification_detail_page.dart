import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart' as html;
import 'package:mosquito_alert/mosquito_alert.dart' as sdk;
import 'package:provider/provider.dart';
import 'package:mosquito_alert_app/utils/style.dart';
import 'package:mosquito_alert_app/utils/html_parser.dart';

class NotificationDetailPage extends StatefulWidget {
  final sdk.Notification notification;
  final void Function(sdk.Notification)? onNotificationUpdated;

  const NotificationDetailPage({
    super.key,
    required this.notification,
    this.onNotificationUpdated,
  });

  static Future<NotificationDetailPage> fromId({
    required BuildContext context,
    required int notificationId,
    void Function(sdk.Notification)? onNotificationUpdated,
  }) async {
    final sdk.MosquitoAlert apiClient =
        Provider.of<sdk.MosquitoAlert>(context, listen: false);
    final sdk.NotificationsApi notificationsApi =
        apiClient.getNotificationsApi();
    final response = await notificationsApi.retrieve(id: notificationId);

    return NotificationDetailPage(
      notification: response.data!,
      onNotificationUpdated: onNotificationUpdated,
    );
  }

  @override
  State<NotificationDetailPage> createState() => _NotificationDetailPageState();
}

class _NotificationDetailPageState extends State<NotificationDetailPage> {
  late sdk.Notification _notification; // local mutable copy
  late sdk.NotificationsApi notificationsApi;

  @override
  void initState() {
    super.initState();
    _notification = widget.notification;

    sdk.MosquitoAlert apiClient =
        Provider.of<sdk.MosquitoAlert>(context, listen: false);
    notificationsApi = apiClient.getNotificationsApi();

    WidgetsBinding.instance.addPostFrameCallback((_) => _markAsRead());
  }

  Future<void> _markAsRead() async {
    if (_notification.isRead) return;

    try {
      final request = sdk.PatchedNotificationRequest((b) => b..isRead = true);
      final response = await notificationsApi.partialUpdate(
          id: _notification.id, patchedNotificationRequest: request);

      final updatedNotification = response.data!;
      if (!mounted) return;

      setState(() => _notification = updatedNotification);

      // notify parent
      widget.onNotificationUpdated?.call(updatedNotification);
    } catch (e) {
      debugPrint("Failed to mark notification as read: $e");
    }
  }

  String get formattedDate {
    final date = _notification.createdAt.toLocal();
    return DateFormat('MMM d, yyyy • h:mm a').format(date);
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
