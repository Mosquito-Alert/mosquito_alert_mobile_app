import 'dart:async';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:mosquito_alert/mosquito_alert.dart' as sdk;
import 'package:mosquito_alert_app/features/notifications/presentation/pages/notification_detail_page.dart';
import 'package:mosquito_alert_app/features/notifications/presentation/state/notification_provider.dart';
import 'package:mosquito_alert_app/core/localizations/MyLocalizations.dart';
import 'package:mosquito_alert_app/core/utils/html_parser.dart';
import 'package:mosquito_alert_app/core/utils/style.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({Key? key}) : super(key: key);

  @override
  _NotificationsPageState createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  @override
  void initState() {
    super.initState();
    _logScreenView();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<NotificationProvider>();
      if (provider.loadedInitial == false) {
        provider.loadInitial();
      }
    });
  }

  Future<void> _logScreenView() async {
    try {
      await FirebaseAnalytics.instance.logScreenView(
        screenName: '/notifications',
      );
    } catch (e) {
      // Handle error if necessary
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NotificationProvider>();
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        centerTitle: true,
        flexibleSpace: FlexibleSpaceBar(
          centerTitle: true,
          title: Text(
            MyLocalizations.of(context, 'notifications_title'),
            style: TextStyle(color: Colors.black87),
          ),
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => provider.refresh(),
          child: Consumer<NotificationProvider>(
            builder: (context, provider, _) {
              return PagedListView<int, sdk.Notification>.separated(
                state: PagingState(
                  pages: [provider.items],
                  keys: [1],
                  hasNextPage: provider.hasMore,
                  isLoading: provider.isLoading,
                  error: provider.error,
                ),
                fetchNextPage: provider.loadMore,
                separatorBuilder: (context, index) => const Divider(
                  height: 1,
                  thickness: 0.2,
                  color: Colors.grey,
                ),
                builderDelegate: PagedChildBuilderDelegate<sdk.Notification>(
                  itemBuilder: (context, notification, index) {
                    return ListTile(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => NotificationDetailPage(
                              notification: notification,
                            ),
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
                      trailing: Text(timeago.format(notification.createdAt)),
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
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
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
                        getHtmlText(notification.message.body),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  },
                  noItemsFoundIndicatorBuilder: (context) => Center(
                    child: Style.body(
                      MyLocalizations.of(context, 'no_notifications_yet_txt'),
                    ),
                  ),
                  firstPageProgressIndicatorBuilder: (context) => Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Style.colorPrimary,
                      ),
                    ),
                  ),
                  newPageProgressIndicatorBuilder: (context) => Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Style.colorPrimary,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
