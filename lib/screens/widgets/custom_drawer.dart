import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mosquito_alert/mosquito_alert.dart';
import 'package:mosquito_alert_app/features/user/presentation/state/user_provider.dart';
import 'package:mosquito_alert_app/core/widgets/info_page_webview.dart';
import 'package:mosquito_alert_app/core/localizations/MyLocalizations.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:provider/provider.dart';

class CustomDrawerItem {
  final IconData icon;
  final String title;
  final Widget destination;

  CustomDrawerItem({
    required this.icon,
    required this.title,
    required this.destination,
  });
}

class CustomDrawer extends StatefulWidget {
  final void Function(int) onTapChanged;
  final List<CustomDrawerItem> items;
  final int selectedIndex;

  CustomDrawer({
    required this.onTapChanged,
    required this.items,
    this.selectedIndex = 0,
  });

  @override
  _CustomDrawerState createState() => _CustomDrawerState();
}

class _CustomDrawerState extends State<CustomDrawer> {
  late int _selectedIndex;
  PackageInfo? packageInfo;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.selectedIndex;
    getPackageInfo();
  }

  Future<void> getPackageInfo() async {
    PackageInfo _packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      packageInfo = _packageInfo;
    });
  }

  @override
  Widget build(BuildContext context) {
    final User? user = context.watch<UserProvider>().user;
    return Drawer(
      child: Column(
        children: [
          Expanded(
            child: ListView(
              // Important: Remove any padding from the ListView.
              padding: EdgeInsets.zero,
              children: <Widget>[
                DrawerHeader(
                  child: Row(
                    children: <Widget>[
                      // User score
                      InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              settings: RouteSettings(name: '/user_score'),
                              builder: (context) => InfoPageInWebview(
                                "${MyLocalizations.of(context, 'url_point_1')}/${user?.uuid ?? 'not_found'}",
                              ),
                            ),
                          );
                        },
                        child: Container(
                          height: 60,
                          width: 60,
                          decoration: BoxDecoration(
                            image: DecorationImage(
                              image: AssetImage('assets/img/points_box.webp'),
                            ),
                          ),
                          child: Center(
                            child: AutoSizeText(
                              (user?.score.value ?? 0).toString(),
                              maxLines: 1,
                              maxFontSize: 26,
                              minFontSize: 16,
                              style: TextStyle(
                                color: Color(0xFF4B3D04),
                                fontWeight: FontWeight.w500,
                                fontSize: 24,
                              ),
                            ),
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
                          _uuidWithClipboard(user),
                        ],
                      ),
                    ],
                  ),
                ),
                ListView.builder(
                  shrinkWrap: true,
                  padding: EdgeInsets.symmetric(horizontal: 8.0),
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: widget.items.length,
                  itemBuilder: (_, index) {
                    final item = widget.items[index];
                    return Container(
                      decoration: BoxDecoration(
                        color: _selectedIndex == index
                            ? Colors.orange.shade200
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(50.0),
                      ),
                      child: ListTile(
                        title: Text(
                          item.title,
                          style: TextStyle(color: Colors.black),
                        ),
                        leading: Icon(item.icon, color: Colors.black),
                        minLeadingWidth: 0,
                        selected: _selectedIndex == index,
                        onTap: () {
                          // Update the state of the app
                          setState(() {
                            _selectedIndex = index;
                          });
                          widget.onTapChanged(_selectedIndex);
                          // Then close the drawer
                          Navigator.pop(context);
                        },
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Mosquito Alert ${packageInfo?.version} (build ${packageInfo?.buildNumber})',
              style: TextStyle(color: Colors.grey, fontSize: 9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _uuidWithClipboard(User? user) {
    if (user == null) {
      // Don't show anything if UUID is not available
      return SizedBox.shrink();
    }
    String uuid = user.uuid;
    return Row(
      children: [
        Text(
          'ID: ',
          style: TextStyle(
            color: Colors.black.withValues(alpha: 0.7),
            fontSize: 8,
          ),
        ),
        Container(
          width: 150,
          child: Text(
            uuid,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: Colors.grey, fontSize: 8),
          ),
        ),
        GestureDetector(
          child: Icon(Icons.copy_rounded, size: 12),
          onTap: () {
            Clipboard.setData(ClipboardData(text: uuid));
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  MyLocalizations.of(context, 'copied_to_clipboard_success'),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
