import 'dart:async';
import 'dart:io';

import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:badges/badges.dart' as badges;
import 'package:flutter/services.dart';
import 'package:mosquito_alert_app/api/api.dart';
import 'package:mosquito_alert_app/models/notification.dart';
import 'package:mosquito_alert_app/pages/info_pages/info_page_webview.dart';
import 'package:mosquito_alert_app/pages/main/home_page.dart';
import 'package:mosquito_alert_app/pages/my_reports_pages/my_reports_page.dart';
import 'package:mosquito_alert_app/pages/notification_pages/notifications_page.dart';
import 'package:mosquito_alert_app/pages/settings_pages/gallery_page.dart';
import 'package:mosquito_alert_app/pages/settings_pages/info_page.dart';
import 'package:mosquito_alert_app/pages/settings_pages/settings_page.dart';
import 'package:mosquito_alert_app/utils/MyLocalizations.dart';
import 'package:mosquito_alert_app/utils/UserManager.dart';
import 'package:mosquito_alert_app/utils/Utils.dart';
import 'package:package_info/package_info.dart';


class MainVC extends StatefulWidget {
  const MainVC({key});

  @override
  State<MainVC> createState() => _MainVCState();
}

class _MainVCState extends State<MainVC> {
  int _selectedIndex = 0;
  int unreadNotifications = 0;
  var packageInfo;
  String? userUuid;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _startAsyncTasks();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _startAsyncTasks() async {
    await UserManager.startFirstTime(context);
    setState(() {
      isLoading = false;
    });
    await _getNotificationCount();
    await getPackageInfo();
    await initAuthStatus();
  }

  Future<void> _getNotificationCount() async {
    List<MyNotification> notifications = await ApiSingleton().getNotifications();
    var unacknowledgedCount = notifications.where((notification) => notification.acknowledged == false).length;
    updateNotificationCount(unacknowledgedCount);
  }

  void updateNotificationCount(int newCount) {
    setState(() {
      unreadNotifications = newCount;
    });
  }

  Future<bool> getPackageInfo() async {
    var _packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      packageInfo = _packageInfo;
    });
    return true;
  }

  Future<bool> initAuthStatus() async {
    if (Platform.isIOS) {
      await AppTrackingTransparency.requestTrackingAuthorization();
    }

    userUuid = await UserManager.getUUID();
    UserManager.userScore = await ApiSingleton().getUserScores();
    await UserManager.setUserScores(UserManager.userScore);
    await Utils.loadFirebase();
    await Utils.getLocation(context);
    return true;
  }

  late final List<Widget> _widgetOptions = <Widget>[
    HomePage(),
    MyReportsPage(),
    GalleryPage(goBackToHomepage: _onItemTapped),
    SettingsPage(),
    InfoPage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        centerTitle: true,
        title: Image.asset(
          'assets/img/ic_logo.png',
          height: 40,
        ),
        actions: <Widget>[
          badges.Badge(
            position: badges.BadgePosition.topEnd(top: 4, end: 4),
            showBadge: unreadNotifications > 0,
            badgeContent: Text('$unreadNotifications', style: TextStyle(color: Colors.white)),
            child: IconButton(
              padding: EdgeInsets.only(top: 6),
              icon: Icon(Icons.notifications, size: 24),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => NotificationsPage(onNotificationUpdate: updateNotificationCount)),
                );
              },
            )
          )
        ],
      ),
      body: Center(
        child: isLoading
          ? CircularProgressIndicator()
          : _widgetOptions[_selectedIndex],
      ),
      drawer: Drawer(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  DrawerHeader(
                    child: Row(
                      children: <Widget>[
                        // User score
                        InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => InfoPageInWebview("${MyLocalizations.of(context, 'url_point_1')}$userUuid")),
                            );
                          },
                          child: Container(
                            height: 60,
                            width: 60,
                            decoration: BoxDecoration(
                              image: DecorationImage(
                                image: AssetImage('assets/img/points_box.png'),
                              ),
                            ),
                            child: StreamBuilder<int?>(
                              stream: Utils.userScoresController.stream,
                              initialData: UserManager.userScore,
                              builder: (context, snapshot) {
                                return Center(
                                  child: AutoSizeText(
                                    snapshot.data != null && snapshot.hasData
                                      ? snapshot.data.toString()
                                      : '',
                                    maxLines: 1,
                                    maxFontSize: 26,
                                    minFontSize: 16,
                                    style: TextStyle(
                                      color: Color(0xFF4B3D04),
                                      fontWeight: FontWeight.w500,
                                      fontSize: 24),
                                  )
                                );
                              }
                            ),
                          ),
                        ),

                        SizedBox(width: 12),

                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: EdgeInsets.only(top: 50.0, bottom: 10.0),
                              child: Text(
                                MyLocalizations.of(context, 'welcome_text'),
                                style: TextStyle(fontSize: 22),
                              ),
                            ),
                            _uuidWithClipboard(),
                          ],
                        )
                      ],
                    )
                  ),
                  _buildCustomTile(0, Icons.home, 'home_tab', context),
                  _buildCustomTile(1, Icons.file_copy, 'your_reports_txt', context),
                  _buildCustomTile(2, Icons.biotech, 'guide_tab', context),
                  _buildCustomTile(3, Icons.info, 'info_tab', context),
                  _buildCustomTile(4, Icons.settings, 'settings_title', context),
                ],
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 20.0),
                child: Text(
                  packageInfo != null
                    ? 'version ${packageInfo.version} (build ${packageInfo.buildNumber})'
                    : '',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 8.0,                  
                  ),
                ),
              ),
            ),
          ],
        )        
      ),
    );
  }

  Widget _uuidWithClipboard(){
    return FutureBuilder(
      future: UserManager.getUUID(),
      builder: (BuildContext context, AsyncSnapshot<String?> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator();
        } else if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        }

        return Row(
          children: [
            Text(
              'ID: ',
              style: TextStyle(
                color: Colors.black.withOpacity(0.7),
                fontSize: 8,
              ),
            ),
            Text(
              snapshot.data ?? '',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 8,
              ),
            ),
            GestureDetector(
              child: Icon(
                Icons.copy_rounded,
                size: 12,
              ),
              onTap: () {
                final data = snapshot.data;
                if (data != null) {
                  Clipboard.setData(ClipboardData(text: data));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(MyLocalizations.of(context, 'copied_to_clipboard_success')),
                    ),
                  );
                } else {
                  // Display an error message for troubleshooting
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(MyLocalizations.of(context, 'copied_to_clipboard_error')),
                    ),
                  );
                }
              },
            )
          ],            
        );
      }
    );
  }

  Widget _buildCustomTile(int index, IconData icon, String title, context){
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      child: Container(
        decoration: BoxDecoration(
          color: _selectedIndex == index ? Colors.orange.shade200 : Colors.transparent,
          borderRadius: BorderRadius.circular(50.0),
        ),
        child: ListTile(
          title: Text(
            MyLocalizations.of(context, title),
            style: TextStyle(color: Colors.black)
          ),
          leading: Icon(
            icon,
            color: Colors.black,
          ),
          minLeadingWidth: 0,
          selected: _selectedIndex == index,
          onTap: () {
            _onItemTapped(index);
            Navigator.pop(context);
          },
        ),
      ),
    );
  }
}
