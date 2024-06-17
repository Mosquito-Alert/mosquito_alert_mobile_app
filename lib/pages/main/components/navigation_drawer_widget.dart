import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mosquito_alert_app/pages/my_reports_pages/my_reports_page.dart';
import 'package:mosquito_alert_app/pages/settings_pages/campaign_tutorial_page.dart';
import 'package:mosquito_alert_app/pages/settings_pages/settings_page.dart';
import 'package:mosquito_alert_app/utils/MyLocalizations.dart';
import 'package:mosquito_alert_app/utils/UserManager.dart';
import 'package:mosquito_alert_app/utils/Utils.dart';
import 'package:mosquito_alert_app/utils/style.dart';
import 'package:package_info/package_info.dart';

class CustomDrawer extends StatefulWidget {
  const CustomDrawer({Key? key}) : super(key: key);

  @override
  State<CustomDrawer> createState() => _CustomDrawerState();
}

class _CustomDrawerState extends State<CustomDrawer> {
  var packageInfo;

  @override
  void initState() {
    super.initState();
    getPackageInfo();
  }

  void getPackageInfo() async {
    var _packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      packageInfo = _packageInfo;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            child: Row(
              children: <Widget>[
                // User score
                Container(
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
          ListTile(
            title: Text(MyLocalizations.of(context, 'home_tab')),
            leading: Icon(Icons.home),
            onTap: () {

            },
          ),
          ListTile(
            title: const Text('My reports'),
            leading: Icon(Icons.file_copy),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MyReportsPage()),
              );
            },
          ),
          ListTile(
            title: Text(MyLocalizations.of(context, 'public_map_tab')),
            leading: Icon(Icons.map),
            onTap: () {
              // TODO: Public map
            },
          ),
          ListTile(
            title: Text(MyLocalizations.of(context, 'guide_tab')),
            leading: Icon(Icons.science),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CampaignTutorialPage()),
              );
            },
          ),
          ListTile(
            title: Text(MyLocalizations.of(context, 'settings_title')),
            leading: Icon(Icons.settings),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SettingsPage()),
              );
            },
          ),
          ListTile(
            title: Text(MyLocalizations.of(context, 'info_tab')),
            leading: Icon(Icons.info),
            onTap: () {
              // TODO: About page
            },
          ),
          SizedBox(
            height: 100,
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Style.bodySmall(
                  packageInfo != null
                      ? 'version ${packageInfo.version} (build ${packageInfo.buildNumber})'
                      : '',
                  fontSize: 8,
                  textAlign: TextAlign.center),
              ],
            ),
          ),
        ],
      ));
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

        print(snapshot.data);
        return Row(
          children: [
            Text(snapshot.data ?? '',
              style: TextStyle(
                color: Colors.black.withOpacity(0.7),
                fontSize: 9
              )
            ),
            GestureDetector(
              child: Icon(
                Icons.copy_rounded,
                size: 18,
              ),
              onTap: () {
                final data = snapshot.data;
                if (data != null) {
                  Clipboard.setData(ClipboardData(text: data));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Copied to Clipboard'),
                    ),
                  );
                } else {
                  // Display an error message for troubleshooting
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: Unable to copy to clipboard. Data is null.'),
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
}