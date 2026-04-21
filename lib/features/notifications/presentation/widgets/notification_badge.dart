import 'package:flutter/material.dart';
import 'package:badges/badges.dart' as badges;
import 'package:mosquito_alert_app/features/notifications/presentation/pages/notification_list_page.dart';
import 'package:mosquito_alert_app/features/notifications/presentation/state/notification_provider.dart';
import 'package:provider/provider.dart';

class NotificationBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final unreadNotifications = context
        .watch<NotificationProvider>()
        .unreadNotificationsCount;
    return badges.Badge(
      ignorePointer: true,
      position: badges.BadgePosition.topEnd(top: 0, end: 3),
      showBadge: unreadNotifications > 0,
      badgeContent: Text(
        unreadNotifications > 9 ? '+9' : '$unreadNotifications',
        style: TextStyle(
          color: Colors.white,
          fontSize: unreadNotifications > 9 ? 10 : 13,
        ),
      ),
      badgeStyle: badges.BadgeStyle(
        padding: unreadNotifications > 9
            ? EdgeInsets.all(5)
            : EdgeInsets.all(6),
        shape: badges.BadgeShape.circle,
        badgeColor: Colors.red,
        borderSide: BorderSide(color: Colors.white, width: 2), // white border
      ),
      child: IconButton(
        icon: Icon(Icons.notifications_none),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => NotificationsPage()),
          );
        },
      ),
    );
  }
}
