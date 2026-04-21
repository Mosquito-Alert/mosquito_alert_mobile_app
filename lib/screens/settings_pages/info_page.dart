import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:mosquito_alert_app/core/widgets/info_page_webview.dart';
import 'package:mosquito_alert_app/screens/settings_pages/campaign_tutorial_page.dart';
import 'package:mosquito_alert_app/screens/settings_pages/components/settings_menu_widget.dart';
import 'package:mosquito_alert_app/screens/settings_pages/partners_page.dart';
import 'package:mosquito_alert_app/core/localizations/MyLocalizations.dart';

class InfoPage extends StatefulWidget {
  InfoPage();

  @override
  _InfoPageState createState() => _InfoPageState();
}

class _InfoPageState extends State<InfoPage> {
  @override
  void initState() {
    super.initState();
    _logScreenView();
  }

  Future<void> _logScreenView() async {
    await FirebaseAnalytics.instance.logScreenView(screenName: '/info');
  }

  @override
  Widget build(BuildContext context) {
    final key = GlobalKey<ScaffoldState>();

    return Scaffold(
      key: key,
      body: SingleChildScrollView(
        child: Container(
          margin: EdgeInsets.all(15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              SizedBox(height: 10),
              SettingsMenuWidget(
                MyLocalizations.of(context, 'info_scores_txt'),
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      settings: RouteSettings(name: '/info/scoring'),
                      builder: (context) => InfoPageInWebview(
                        MyLocalizations.of(context, 'url_scoring_1'),
                      ),
                    ),
                  );
                },
              ),
              SizedBox(height: 10),
              SettingsMenuWidget(
                MyLocalizations.of(context, 'about_the_project_txt'),
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      settings: RouteSettings(name: '/info/about_project'),
                      builder: (context) => InfoPageInWebview(
                        MyLocalizations.of(context, 'url_about_project'),
                      ),
                    ),
                  );
                },
              ),
              SizedBox(height: 10),
              SettingsMenuWidget(
                MyLocalizations.of(context, 'coordination_txt'),
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      settings: RouteSettings(name: '/info/about_us'),
                      builder: (context) => InfoPageInWebview(
                        MyLocalizations.of(context, 'url_about_us'),
                      ),
                    ),
                  );
                },
              ),
              SizedBox(height: 10),
              SettingsMenuWidget(
                MyLocalizations.of(context, 'partners_txt'),
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => PartnersPage()),
                  );
                },
              ),
              SizedBox(height: 10),
              SettingsMenuWidget(
                MyLocalizations.of(context, 'mailing_mosquito_samples'),
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CampaignTutorialPage(),
                    ),
                  );
                },
              ),
              SizedBox(height: 30),
              SettingsMenuWidget(
                MyLocalizations.of(context, 'terms_of_use_txt'),
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      settings: RouteSettings(name: '/info/terms'),
                      builder: (context) => InfoPageInWebview(
                        MyLocalizations.of(context, 'terms_link'),
                        localHtml: true,
                      ),
                    ),
                  );
                },
              ),
              SizedBox(height: 10),
              SettingsMenuWidget(
                MyLocalizations.of(context, 'privacy_txt'),
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      settings: RouteSettings(name: '/info/privacy'),
                      builder: (context) => InfoPageInWebview(
                        MyLocalizations.of(context, 'privacy_link'),
                        localHtml: true,
                      ),
                    ),
                  );
                },
              ),
              SizedBox(height: 10),
              SettingsMenuWidget(
                MyLocalizations.of(context, 'license_txt'),
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      settings: RouteSettings(name: '/info/license'),
                      builder: (context) => InfoPageInWebview(
                        MyLocalizations.of(context, 'lisence_link'),
                        localHtml: true,
                      ),
                    ),
                  );
                },
              ),
              SizedBox(height: 10),
              SizedBox(height: 60),
            ],
          ),
        ),
      ),
    );
  }
}
