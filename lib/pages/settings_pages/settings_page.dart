import 'package:flutter/material.dart';
import 'package:language_pickers/language_picker_dialog.dart';
import 'package:language_pickers/languages.dart';
import 'package:mosquito_alert_app/api/api.dart';
import 'package:mosquito_alert_app/pages/auth/login_main_page.dart';
import 'package:mosquito_alert_app/pages/info_pages/info_page.dart';
import 'package:mosquito_alert_app/pages/main/main_vc.dart';
import 'package:mosquito_alert_app/pages/settings_pages/components/settings_menu_widget.dart';
import 'package:mosquito_alert_app/pages/settings_pages/countries_involved.dart';
import 'package:mosquito_alert_app/pages/settings_pages/gallery_page.dart';
import 'package:mosquito_alert_app/pages/settings_pages/tutorial_page.dart';
import 'package:mosquito_alert_app/utils/Application.dart';
import 'package:mosquito_alert_app/utils/MyLocalizations.dart';
import 'package:mosquito_alert_app/utils/UserManager.dart';
import 'package:mosquito_alert_app/utils/Utils.dart';
import 'package:mosquito_alert_app/utils/style.dart';
import 'package:flutter_background_geolocation/flutter_background_geolocation.dart'
    as bg;
import 'package:package_info/package_info.dart';

class SettingsPage extends StatefulWidget {
  final Function enableTracking;

  SettingsPage({this.enableTracking});
  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool enableTracking = false;
  var packageInfo;

  List<Map<String, String>> languageCodes = [
    {'name': 'Spanish', 'isoCode': 'es_ES'},
    {'name': 'Catalan', 'isoCode': 'ca_ES'},
    {'name': 'Albanian', 'isoCode': 'sq_AL'},
    {'name': 'Bulgarian', 'isoCode': 'bg_BG'},
    {'name': 'Dutch', 'isoCode': 'nl_NL'},
    {'name': 'German', 'isoCode': 'de_DE'},
    {'name': 'Italian', 'isoCode': 'it_IT'},
    {'name': 'Protuguese', 'isoCode': 'pt_PT'},
    // {'name': 'Romanian', 'isoCode': 'ro_RO'},
    {'name': 'English', 'isoCode': 'en_US'},
    {'name': 'Greek', 'isoCode': 'el_GR'},
    {'name': 'French', 'isoCode': 'fr_FR'},
    {'name': 'Croatian', 'isoCode': 'hr_HR'},
    {'name': 'Hungarian', 'isoCode': 'hu_HU'},
    {'name': 'Luxembourgish (Luxembourg)', 'isoCode': 'lb_LU'},
    {
      'name': 'Macedonian (Former Yugoslav Republic of Macedonia)',
      'isoCode': 'mk_MK'
    },
    // {'name': 'Russian (Russia)', 'isoCode': 'ru_RU'},
    {'name': 'Slovenian (Slovenia)', 'isoCode': 'sl_SI'},
    {'name': 'Serbian', 'isoCode': 'sr_RS'},
    {'name': 'Turkish (Turkey)', 'isoCode': 'tr_TR'},
    // {'name': 'Chinese', 'isoCode': 'zh_CH'},
    // {'name': 'Chinese (Traditional, Hong Kong)', 'isoCode': 'zh_HK'},
  ];

  String selectedLanguage;

  @override
  void initState() {
    super.initState();
    getTracking();
  }

  getTracking() async {
    enableTracking = await UserManager.getTracking();
    PackageInfo _packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      packageInfo = _packageInfo;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        centerTitle: true,
        title: Style.title(MyLocalizations.of(context, 'settings_title'),
            fontSize: 16),
      ),
      body: SingleChildScrollView(
        child: Container(
          margin: EdgeInsets.all(15),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: <
                  Widget>[
            SizedBox(
              height: 35,
            ),
            // UserManager.user != null
            //     ? SettingsMenuWidget(MyLocalizations.of(context, "logout_txt"),
            //         () {
            //         Utils.showAlertYesNo(
            //             MyLocalizations.of(context, "logout_txt"),
            //             MyLocalizations.of(context, "logout_alert_txt"), () {
            //           _signOut();
            //         }, context);
            //       })
            //     : Column(
            //         children: <Widget>[
            //           SettingsMenuWidget(
            //               MyLocalizations.of(
            //                   context, "login_with_your_account_txt"), () {
            //             Navigator.push(
            //               context,
            //               MaterialPageRoute(
            //                   builder: (context) => LoginMainPage()),
            //             );
            //           }),
            //           Padding(
            //             padding: const EdgeInsets.all(10.0),
            //             child: Style.bodySmall(
            //                 MyLocalizations.of(
            //                     context, "use_your_acount_details_txt"),
            //                 color: Colors.grey),
            //           ),
            //         ],
            //       ),
            SizedBox(
              height: 10,
            ),
            SettingsMenuWidget(
                MyLocalizations.of(context, 'select_language_txt'), () {
              _openLanguagePickerDialog();
            }),
            SizedBox(
              height: 10,
            ),
            SettingsMenuWidget(
                enableTracking
                    ? MyLocalizations.of(context, 'enable_background_tracking')
                    : MyLocalizations.of(
                        context, 'disable_background_tracking'), () {
              _disableBgTracking();
            }),
            SizedBox(
              height: 35,
            ),
            SettingsMenuWidget(
                MyLocalizations.of(context, 'mosquitos_gallery_txt'), () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => GalleryPage()),
              );
            }),
            SizedBox(
              height: 10,
            ),
            SettingsMenuWidget(MyLocalizations.of(context, 'tutorial_txt'), () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => TutorialPage(true)),
              );
            }),
            SizedBox(
              height: 10,
            ),
            SettingsMenuWidget(MyLocalizations.of(context, 'info_scores_txt'),
                () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) =>
                        InfoPage(MyLocalizations.of(context, 'url_scoring_1'))),
              );
            }),
            SizedBox(
              height: 10,
            ),
            SettingsMenuWidget(
                MyLocalizations.of(context, 'about_the_project_txt'), () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => InfoPage(
                        MyLocalizations.of(context, 'url_about_project'))),
              );
            }),
            SizedBox(
              height: 10,
            ),
            SettingsMenuWidget(MyLocalizations.of(context, 'about_us_txt'), () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) =>
                        InfoPage(MyLocalizations.of(context, 'url_about_us'))),
              );
            }),
                /*SizedBox(
                  height: 10,
                ),
                SettingsMenuWidget("countries_involved", () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            CountriesInvolvedPage()),
                  );
                }),*/
            SizedBox(
              height: 30,
            ),
            SettingsMenuWidget(MyLocalizations.of(context, 'terms_of_use_txt'),
                () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => InfoPage(
                          MyLocalizations.of(context, 'terms_link'),
                          localHtml: true,
                        )),
              );
            }),
            SizedBox(
              height: 10,
            ),
            SettingsMenuWidget(MyLocalizations.of(context, 'privacy_txt'), () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => InfoPage(
                          MyLocalizations.of(context, 'privacy_link'),
                          localHtml: true,
                        )),
              );
            }),
            SizedBox(
              height: 10,
            ),
            SettingsMenuWidget(MyLocalizations.of(context, 'license_txt'), () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => InfoPage(
                          MyLocalizations.of(context, 'lisence_link'),
                          localHtml: true,
                        )),
              );
            }),
            SizedBox(
              height: 10,
            ),
            SizedBox(
              height: 60,
            ),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Style.title(MyLocalizations.of(context, 'app_name'),
                      fontSize: 8, textAlign: TextAlign.center),
                  Style.bodySmall(
                      packageInfo != null
                          ? '${packageInfo.version} (build ${packageInfo.buildNumber})'
                          : '',
                      fontSize: 8,
                      textAlign: TextAlign.center),
                ],
              ),
            ),
            SizedBox(
              height: 60,
            ),
          ]),
        ),
      ),
    );
  }

  void _openLanguagePickerDialog() => showDialog(
        context: context,
        builder: (context) => Theme(
            data: Theme.of(context).copyWith(primaryColor: Style.colorPrimary),
            child: LanguagePickerDialog(
                languagesList: languageCodes,
                titlePadding: EdgeInsets.all(8.0),
                searchCursorColor: Style.colorPrimary,
                searchInputDecoration: InputDecoration(
                    hintText: MyLocalizations.of(context, 'search_txt')),
                isSearchable: true,
                title: Text(MyLocalizations.of(context, 'select_language_txt')),
                onValuePicked: (Language language) => setState(() {
                      var languageCodes = language.isoCode.split('_');

                      Utils.language =
                          Locale(languageCodes[0], languageCodes[1]);
                      UserManager.setLanguage(languageCodes[0]);
                      UserManager.setLanguageCountry(languageCodes[1]);
                      application.onLocaleChanged(
                          Locale(languageCodes[0], languageCodes[1]));
                    }),
                itemBuilder: (Language language) {
                  return Row(
                    children: <Widget>[
                      Text(MyLocalizations.of(context, language.isoCode)),
                      // Text(language.name),
                    ],
                  );
                })),
      );

  _signOut() async {
    ApiSingleton().logout().then((res) {
      UserManager.signOut();
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (context) => MainVC()));
    }).catchError((e) {
      print(e);
    });
  }

  _disableBgTracking() {
    Utils.showAlertYesNo(
        MyLocalizations.of(context, 'app_name'),
        enableTracking
            ? MyLocalizations.of(context, 'enable_tracking_question_text')
            : MyLocalizations.of(context, 'disable_tracking_question_text'),
        () async {
      await UserManager.setTracking(!enableTracking);
      if (enableTracking) {
        widget.enableTracking();
      } else {
        bg.BackgroundGeolocation.stop();
        bg.BackgroundGeolocation.stopSchedule();
        print('disable');
      }

      setState(() {
        enableTracking = !enableTracking;
      });
    }, context);
  }
}
