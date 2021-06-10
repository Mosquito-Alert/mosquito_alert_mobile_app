import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
import 'package:mosquito_alert_app/api/api.dart';
import 'package:mosquito_alert_app/models/notification.dart';
import 'package:mosquito_alert_app/utils/MyLocalizations.dart';
import 'package:mosquito_alert_app/utils/Utils.dart';
import 'package:mosquito_alert_app/utils/customModalBottomSheet.dart';
import 'package:mosquito_alert_app/utils/style.dart';
import 'package:intl/intl.dart';

import '../../utils/UserManager.dart';

class NotificationsPage extends StatefulWidget {
  final String notificationId;

  const NotificationsPage({Key key, this.notificationId}) : super(key: key);

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
    _getData();
  }

  _getData() async {
    List<MyNotification> response = await ApiSingleton().getNotifications();

    if (response != null) {
      setState(() {
        notifications = response;
        _checkOpenNotification();
      });
    }
    loadingStream.add(false);
  }

  _checkOpenNotification() {
    try {
      if (widget.notificationId != null && widget.notificationId.isNotEmpty) {
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
                  MyLocalizations.of(context, "notifications_title"),
                  fontSize: 16),
            ),
            body: notifications.length == 0 || notifications.isEmpty
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                        Center(
                          child: Style.body(MyLocalizations.of(
                              context, "no_notifications_yet_txt")),
                        ),
                      ])
                : Container(
                    margin: EdgeInsets.all(12),
                    child: ListView.builder(
                        // physics: NeverScrollableScrollPhysics(),
                        // shrinkWrap: true,
                        itemCount: notifications.length,
                        itemBuilder: (ctx, index) {
                          return Opacity(
                            opacity:
                                !notifications[index].acknowledged ? 1 : 0.5,
                            child: Card(
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                              child: ListTile(
                                contentPadding: EdgeInsets.all(12),
                                onTap: () {
                                  !notifications[index].acknowledged
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
                                            context, "see_more_txt"),
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
              if (snapLoading.data == true)
                return Container(
                  child: Center(
                    child: Utils.loading(true),
                  ),
                );
              return Container();
            }),
      ],
    );
  }

  void _infoBottomSheet(BuildContext context, MyNotification notification) {
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
                    EdgeInsets.only(left: 10, right: 10, top: 10, bottom: 80),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    // mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: <Widget>[
                      SizedBox(
                        height: 15,
                      ),
                      Style.titleMedium(notification.expert_comment),
                      SizedBox(
                        height: 10,
                      ),
                      Container(
                        // padding: EdgeInsets.all(10),
                        child: HtmlWidget(notification.expert_html),
                      ),
                      // ClipRRect(
                      //   borderRadius: BorderRadius.circular(15),
                      //   child: Image.asset(
                      //     'assets/img/placeholder.jpg',
                      //     height: 100,
                      //     width: double.infinity,
                      //     fit: BoxFit.cover,
                      //   ),
                      // ),
                      // SizedBox(
                      //   height: 10,
                      // ),
                      // Style.title("¡Nueva especie detectada en Barcelona!"),
                      // SizedBox(
                      //   height: 10,
                      // ),
                      // Style.body(
                      //     "Lorem Ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry's standard dummy text ever since the 1500s, when an unknown printer took a galley of type and scrambled it to make a type specimen book. It has survived not only five centuries"),
                      SizedBox(
                        height: 10,
                      ),
                      Style.bodySmall(
                          DateFormat('dd-MM-yyyy hh:mm').format(
                              DateTime.parse(notification.date_comment)),
                          color: Colors.grey)
                    ],
                  ),
                ),
              ),
            ),
          );
        });
  }

  _updateNotification(id) async {
    var userId = await UserManager.getUUID();
    var res = await ApiSingleton().markNotificationAsRead(userId, id);

    if (res) {
      var index = notifications.indexWhere((element) => element.id == id);
      setState(() {
        notifications[index].acknowledged = true;
      });
    }
  }
}
