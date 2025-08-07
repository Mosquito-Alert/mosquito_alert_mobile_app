import 'dart:async';

import 'package:built_collection/built_collection.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart' as html;
import 'package:html/parser.dart' show parse;
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:intl/intl.dart';
import 'package:mosquito_alert/mosquito_alert.dart' as sdk;
import 'package:mosquito_alert_app/utils/MyLocalizations.dart';
import 'package:mosquito_alert_app/utils/customModalBottomSheet.dart';
import 'package:mosquito_alert_app/utils/style.dart';
import 'package:provider/provider.dart';

class NotificationsPage extends StatefulWidget {
  final int? notificationId;

  const NotificationsPage({Key? key, this.notificationId}) : super(key: key);

  @override
  _NotificationsPageState createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  bool _isLastPage = false;
  static const _pageSize = 20;
  late final _pagingController =
      PagingController<int, sdk.Notification>(getNextPageKey: (state) {
    return _isLastPage ? null : state.nextIntPageKey;
  }, fetchPage: (pageKey) async {
    final response = await notificationsApi.listMine(
      page: pageKey,
      pageSize: _pageSize,
      orderBy: BuiltList<String>(["-created_at"]),
    );
    final data = response.data;
    if (data == null) return [];
    _isLastPage = data.next == null;

    return data.results?.toList() ?? [];
  });

  StreamController<bool> loadingStream = StreamController<bool>.broadcast();
  late sdk.NotificationsApi notificationsApi;

  @override
  void initState() {
    super.initState();
    sdk.MosquitoAlert apiClient =
        Provider.of<sdk.MosquitoAlert>(context, listen: false);
    notificationsApi = apiClient.getNotificationsApi();
    _logScreenView();
    loadingStream.add(true);

    if (widget.notificationId != null) {
      // Delay until the first frame is rendered
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final notification =
            await fetchNotificationById(widget.notificationId!);
        if (notification != null && mounted) {
          _showNotificationBottomSheet(context, notification);
        }
      });
    }
  }

  Future<sdk.Notification?> fetchNotificationById(int id) async {
    try {
      final response = await notificationsApi.retrieve(id: id);
      return response.data;
    } catch (e) {
      // Handle error if needed
      return null;
    }
  }

  @override
  void dispose() {
    _pagingController.dispose();
    super.dispose();
  }

  Future<void> _logScreenView() async {
    await FirebaseAnalytics.instance
        .logScreenView(screenName: '/notifications');
  }

  String _parseHtmlString(String htmlString) {
    final document = parse(htmlString);
    final String parsedString = document.body?.text ?? '';
    return parsedString.trim();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        centerTitle: true,
        title: Style.title(
          MyLocalizations.of(context, 'notifications_title'),
          fontSize: 16,
        ),
      ),
      body: Container(
        margin: EdgeInsets.all(12),
        child: PagingListener<int, sdk.Notification>(
          controller: _pagingController,
          builder: (context, state, fetchNextPage) {
            return PagedListView<int, sdk.Notification>(
              state: state,
              fetchNextPage: fetchNextPage,
              padding: const EdgeInsets.only(top: 4, bottom: 12),
              builderDelegate: PagedChildBuilderDelegate<sdk.Notification>(
                itemBuilder: (context, notification, index) {
                  return Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    color:
                        notification.isRead ? Colors.grey[200] : Colors.white,
                    child: ListTile(
                      contentPadding: EdgeInsets.all(12),
                      onTap: () {
                        _showNotificationBottomSheet(context, notification);
                      },
                      title: Text(
                        notification.message.title,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: notification.isRead
                              ? Colors.black54
                              : Colors.black,
                        ),
                      ),
                      subtitle: Text(
                          _parseHtmlString(notification.message.body),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ),
                  );
                },
                noItemsFoundIndicatorBuilder: (context) => Center(
                  child: Style.body(
                    MyLocalizations.of(context, 'no_notifications_yet_txt'),
                  ),
                ),
                firstPageProgressIndicatorBuilder: (context) =>
                    Center(child: CircularProgressIndicator()),
                newPageProgressIndicatorBuilder: (context) =>
                    Center(child: CircularProgressIndicator()),
              ),
            );
          },
        ),
      ),
    );
  }

  void _showNotificationBottomSheet(
      BuildContext context, sdk.Notification notification) async {
    await FirebaseAnalytics.instance.logSelectContent(
        contentType: 'notification', itemId: '${notification.id}');

    if (!notification.isRead) {
      await markNotificationAsRead(notification);
    }

    CustomShowModalBottomSheet.customShowModalBottomSheet(
        context: context,
        builder: (BuildContext bc) {
          return SafeArea(
            bottom: false,
            child: Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.8,
              ),
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(10),
                    topRight: Radius.circular(10),
                  )),
              child: Container(
                margin:
                    EdgeInsets.only(left: 20, right: 10, top: 10, bottom: 10),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      SizedBox(
                        height: 15,
                      ),
                      Style.titleMedium(notification.message.title),
                      Style.bodySmall(
                          DateFormat('dd-MM-yyyy HH:mm')
                              .format(notification.createdAt.toLocal()),
                          color: Colors.grey),
                      SizedBox(
                        height: 10,
                      ),
                      html.Html(
                        data: notification.message.body
                            .replaceAll('<p><a', '<a')
                            .replaceAll('</a></p>', '</a>'),
                        style: {
                          '*': html.Style(
                            padding: html.HtmlPaddings.zero,
                            margin: html.Margins.zero,
                          ),
                        },
                      )
                    ],
                  ),
                ),
              ),
            ),
          );
        });
  }

  Future<void> markNotificationAsRead(sdk.Notification notification) async {
    if (notification.isRead) return;

    sdk.PatchedNotificationRequest patchedNotificationRequest =
        sdk.PatchedNotificationRequest((b) => b..isRead = true);
    final response = await notificationsApi.partialUpdate(
        id: notification.id,
        patchedNotificationRequest: patchedNotificationRequest);

    final sdk.Notification? newNotification = response.data;
    if (newNotification == null || response.statusCode != 200) {
      print('Failed to update notification: No data returned');
      return;
    }

    // Update the notification in the paging controller
    // See: https://github.com/EdsonBueno/infinite_scroll_pagination/issues/389
    _pagingController.mapItems((sdk.Notification item) =>
        item.id == newNotification.id ? newNotification : item);
  }
}
