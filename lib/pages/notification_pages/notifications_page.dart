import 'dart:async';

import 'package:built_collection/built_collection.dart';
import 'package:flutter/material.dart';
import 'package:html/parser.dart' show parse;
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:mosquito_alert/mosquito_alert.dart' as sdk;
import 'package:mosquito_alert_app/pages/notification_pages/notification_detail_page.dart';
import 'package:mosquito_alert_app/services/analytics_service.dart';
import 'package:mosquito_alert_app/utils/MyLocalizations.dart';
import 'package:mosquito_alert_app/utils/UserManager.dart';
import 'package:mosquito_alert_app/utils/style.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;

class NotificationsPage extends StatefulWidget {
  final AnalyticsService? analyticsService;

  const NotificationsPage({
    Key? key,
    this.analyticsService,
  }) : super(key: key);

  @override
  _NotificationsPageState createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  String languageCode = 'en';

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
  late AnalyticsService _analyticsService;

  @override
  void initState() {
    super.initState();
    sdk.MosquitoAlert apiClient =
        Provider.of<sdk.MosquitoAlert>(context, listen: false);
    notificationsApi = apiClient.getNotificationsApi();
    _analyticsService = widget.analyticsService ?? FirebaseAnalyticsService();
    initLanguage();
    _logScreenView();
    loadingStream.add(true);
  }

  Future<void> initLanguage() async {
    languageCode = await UserManager.getLanguage() ?? 'en';
  }

  @override
  void dispose() {
    _pagingController.dispose();
    super.dispose();
  }

  Future<void> _logScreenView() async {
    await _analyticsService.logScreenView(screenName: '/notifications');
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
          flexibleSpace: FlexibleSpaceBar(
            centerTitle: true,
            title: Text(MyLocalizations.of(context, 'notifications_title'),
                style: TextStyle(color: Colors.black87)),
          ),
        ),
        body: SafeArea(
          child: PagingListener<int, sdk.Notification>(
            controller: _pagingController,
            builder: (context, state, fetchNextPage) {
              return PagedListView<int, sdk.Notification>(
                state: state,
                fetchNextPage: fetchNextPage,
                builderDelegate: PagedChildBuilderDelegate<sdk.Notification>(
                  itemBuilder: (context, notification, index) {
                    return Column(children: [
                      ListTile(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => NotificationDetailPage(
                                  notification: notification,
                                  onNotificationUpdated: (notification) {
                                    // Update the notification in the paging controller
                                    // See: https://github.com/EdsonBueno/infinite_scroll_pagination/issues/389
                                    _pagingController.mapItems(
                                        (sdk.Notification item) =>
                                            item.id == notification.id
                                                ? notification
                                                : item);
                                  }),
                            ),
                          );
                        },
                        tileColor: notification.isRead
                            ? Colors.white
                            : Colors.grey[200],
                        titleTextStyle: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: notification.isRead
                              ? Colors.black54
                              : Colors.black,
                        ),
                        isThreeLine: true,
                        trailing: Text(timeago.format(notification.createdAt,
                            locale: languageCode + '_short')),
                        title: Text.rich(
                          TextSpan(
                            children: [
                              if (!notification.isRead) ...[
                                WidgetSpan(
                                  alignment: PlaceholderAlignment.middle,
                                  child: Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                                const WidgetSpan(child: SizedBox(width: 8)),
                              ],
                              TextSpan(
                                text: notification.message.title,
                                style: const TextStyle(
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                            _parseHtmlString(notification.message.body),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis),
                      ),
                      // Add a divider after each tile
                      const Divider(
                          height: 1, thickness: 0.2, color: Colors.grey),
                    ]);
                  },
                  noItemsFoundIndicatorBuilder: (context) => Center(
                    child: Style.body(
                      MyLocalizations.of(context, 'no_notifications_yet_txt'),
                    ),
                  ),
                  firstPageProgressIndicatorBuilder: (context) => Center(
                      child: CircularProgressIndicator(
                    valueColor:
                        AlwaysStoppedAnimation<Color>(Style.colorPrimary),
                  )),
                  newPageProgressIndicatorBuilder: (context) => Center(
                      child: CircularProgressIndicator(
                    valueColor:
                        AlwaysStoppedAnimation<Color>(Style.colorPrimary),
                  )),
                ),
              );
            },
          ),
        ));
  }
}
