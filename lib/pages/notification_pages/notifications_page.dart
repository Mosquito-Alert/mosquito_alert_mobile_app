import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart' as html;
import 'package:flutter_html/style.dart' as html_style;
import 'package:intl/intl.dart';
import 'package:mosquito_alert_app/api/api.dart';
import 'package:mosquito_alert_app/models/notification.dart';
import 'package:mosquito_alert_app/utils/MyLocalizations.dart';
import 'package:mosquito_alert_app/utils/Utils.dart';
import 'package:mosquito_alert_app/utils/customModalBottomSheet.dart';
import 'package:mosquito_alert_app/utils/style.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../utils/UserManager.dart';

class NotificationsPage extends StatefulWidget {
  final String? notificationId;
  final Function(int)? onNotificationUpdate;

  const NotificationsPage({Key? key, this.notificationId, this.onNotificationUpdate}) : super(key: key);

  @override
  _NotificationsPageState createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  List<MyNotification> notifications = [];
  StreamController<bool> loadingStream = StreamController<bool>.broadcast();

  @override
  void initState() {
    super.initState();
    loadingStream.add(true);
    _getData().then((_) {
      _updateUnreadNotificationCount();
    });
  }

  Future<void> _getData() async {
    List<MyNotification> response = await ApiSingleton().getNotifications();

    setState(() {
      notifications = response;
      _checkOpenNotification();
    });
      loadingStream.add(false);
  }

  void _checkOpenNotification() {
    try {
      if (widget.notificationId != null && widget.notificationId!.isNotEmpty) {
        var notifId = widget.notificationId;
        for (var notif in notifications) {
          if (notifId == '${notif.id}') {
            _infoBottomSheet(context, notif);
            return;
          }
        }
      }
    } catch (e) {
      print(e);
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
              title: Style.title(
                  MyLocalizations.of(context, 'notifications_title'),
                  fontSize: 16),
            ),
            body: notifications.isEmpty
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                        Center(
                          child: Style.body(MyLocalizations.of(
                              context, 'no_notifications_yet_txt')),
                        ),
                      ])
                : Container(
                    margin: EdgeInsets.all(12),
                    child: ListView.builder(
                        itemCount: notifications.length,
                        itemBuilder: (ctx, index) {
                          return Opacity(
                            opacity:
                                !notifications[index].acknowledged! ? 1 : 0.5,
                            child: Card(
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                              child: ListTile(
                                contentPadding: EdgeInsets.all(12),
                                onTap: () {
                                  !notifications[index].acknowledged!
                                      ? _updateNotification(
                                          notifications[index].id)
                                      : null;
                                  _infoBottomSheet(
                                      context, notifications[index]);
                                },
                                title: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Style.titleMedium(
                                        notifications[index].expert_comment,
                                        fontSize: 16),
                                    SizedBox(
                                      height: 4,
                                    ),
                                    Style.bodySmall(
                                        MyLocalizations.of(
                                            context, 'see_more_txt'),
                                        color: Colors.grey),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }))),
        StreamBuilder<bool>(
            stream: loadingStream.stream,
            initialData: true,
            builder: (BuildContext context, AsyncSnapshot<bool> snapLoading) {
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
    );
  }

  void _infoBottomSheet(BuildContext context, MyNotification notification) {
    CustomShowModalBottomSheet.customShowModalBottomSheet(
        context: context,
        builder: (BuildContext bc) {
          log(notification.expert_html!);
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
                    EdgeInsets.only(left: 10, right: 10, top: 10, bottom: 80),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      SizedBox(
                        height: 15,
                      ),
                      Style.titleMedium(notification.expert_comment),
                      SizedBox(
                        height: 10,
                      ),
                      Container(
                          child: html.Html(
                        data: notification.expert_html!
                            .replaceAll('<p><a', '<a')
                            .replaceAll('</a></p>', '</a>'),
                        onLinkTap: (String? url, html.RenderContext context,
                            Map<String, String> attributes, _) async {
                          await launch(url!, forceSafariVC: true);
                        },
                        style: {
                          'a': html.Style(
                              backgroundColor: Colors.transparent,
                              color: Colors.blueAccent,
                              padding: EdgeInsets.all(12),
                              margin: html_style.Margins(
                                  bottom: html_style.Margin(12.0),
                                  right: html_style.Margin(12.0),
                                  top: html_style.Margin(12.0),
                                  left: html_style.Margin(12.0)),
                              textDecoration: TextDecoration.underline,
                              textAlign: TextAlign.center,
                              fontSize: html.FontSize(16.0)),
                        },
                        tagsList: html.Html.tags..addAll(['bird', 'flutter']),
                      )),

                      SizedBox(
                        height: 10,
                      ),
                      Style.bodySmall(
                          DateFormat('dd-MM-yyyy HH:mm').format(
                              DateTime.parse(notification.date_comment!).toLocal()),
                          color: Colors.grey)
                    ],
                  ),
                ),
              ),
            ),
          );
        });
  }

  Future<void> _updateNotification(id) async {
    var userId = await UserManager.getUUID();
    var res = await ApiSingleton().markNotificationAsRead(userId, id);

    if (res) {
      var index = notifications.indexWhere((element) => element.id == id);
      setState(() {
        notifications[index].acknowledged = true;
      });
      _updateUnreadNotificationCount();
    } 
  }

  void _updateUnreadNotificationCount(){
    var unacknowledgedCount = notifications.where((notification) => notification.acknowledged == false).length;
    if(widget.onNotificationUpdate != null) {
      widget.onNotificationUpdate!(unacknowledgedCount);
    }
  }
}
