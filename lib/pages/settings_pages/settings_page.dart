import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:language_picker/language_picker.dart';

import 'package:language_picker/languages.dart';
import 'package:mosquito_alert_app/api/api.dart';
import 'package:mosquito_alert_app/pages/info_pages/info_page.dart';
import 'package:mosquito_alert_app/pages/main/main_vc.dart';
import 'package:mosquito_alert_app/pages/settings_pages/components/settings_menu_widget.dart';
import 'package:mosquito_alert_app/pages/settings_pages/gallery_page.dart';
import 'package:mosquito_alert_app/pages/settings_pages/partners_page.dart';
import 'package:mosquito_alert_app/pages/settings_pages/tutorial_page.dart';
import 'package:mosquito_alert_app/utils/Application.dart';
import 'package:mosquito_alert_app/utils/MyLocalizations.dart';
import 'package:mosquito_alert_app/utils/PushNotificationsManager.dart';
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
  String hashtag;
  var packageInfo;

  final languageCodes = [
    Language('es_ES', 'Spanish'),
    Language('ca_ES', 'Catalan'),
    Language('sq_AL', 'Albanian'),
    Language('bg_BG', 'Bulgarian'),
    Language('nl_NL', 'Dutch'),
    Language('de_DE', 'German'),
    Language('it_IT', 'Italian'),
    Language('pt_PT', 'Protuguese'),
    Language('en_US', 'English'),
    Language('el_GR', 'Greek'),
    Language('fr_FR', 'French'),
    Language('hr_HR', 'Croatian'),
    Language('hu_HU', 'Hungarian'),
    Language('lb_LU', 'Luxembourgish (Luxembourg)'),
    Language('mk_MK', 'Macedonian (Former Yugoslav Republic of Macedonia)'),
    Language('sl_SI', 'Slovenian (Slovenia)'),
    Language('sr_RS', 'Serbian'),
    Language('tr_TR', 'Turkish (Turkey)'),
    Language('ro_RO', 'Romanian'),
  ];

  String selectedLanguage;

  @override
  void initState() {
    super.initState();
    getTracking();
    getHashtag();
  }

  getTracking() async {
    enableTracking = await UserManager.getTracking();
    PackageInfo _packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      packageInfo = _packageInfo;
    });
  }

  getHashtag() async {
    hashtag = await UserManager.getHashtag();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final key = new GlobalKey<ScaffoldState>();

    return Scaffold(
      key: key,
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
              height: 12,
            ),

            FutureBuilder(
              future: UserManager.getUUID(),
              builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
                print(snapshot.data);
                return Row(
                  children: [
                    Style.body('ID'),
                    SizedBox(
                      width: 12,
                    ),
                    Expanded(
                        child: Style.bodySmall(snapshot.data,
                            color: Colors.black.withOpacity(0.7))),
                    GestureDetector(
                      child: Icon(
                        Icons.copy_rounded,
                        size: 18,
                      ),
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: snapshot.data));
                        key.currentState.showSnackBar(new SnackBar(
                          content: new Text('Copied to Clipboard'),
                        ));
                      },
                    )
                  ],
                );
              },
            ),
            SizedBox(
              height: 12,
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
              height: 10,
            ),
            SettingsMenuWidget(
                hashtag == null
                    ? MyLocalizations.of(context, 'enable_auto_hashtag')
                    : MyLocalizations.of(context, 'disable_auto_hashtag'), () {
              _manageHashtag();
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
            SettingsMenuWidget(MyLocalizations.of(context, 'coordination_txt'),
                () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) =>
                        InfoPage(MyLocalizations.of(context, 'url_about_us'))),
              );
            }),
            SizedBox(
              height: 10,
            ),
            SettingsMenuWidget(MyLocalizations.of(context, 'partners_txt'), () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => PartnersPage()),
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
                languages: languageCodes,
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
                      PushNotificationsManager.subscribeToTopic(
                          languageCodes[0]);
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
    await ApiSingleton().logout().then((res) {
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

  _manageHashtag() async {
    if (hashtag != null) {
      await Utils.showAlertYesNo(
        MyLocalizations.of(context, 'app_name'),
        MyLocalizations.of(context, 'disable_auto_hashtag_text'),
        () async {
          hashtag = null;
          updateHashtag();
        },
        context,
      );
      return;
    }

    var controller = TextEditingController();
    if (Platform.isIOS) {
      hashtag = await showDialog(
          context: context,
          builder: (context) {
            return CupertinoAlertDialog(
              title: Text(MyLocalizations.of(context, 'app_name')),
              content: Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Material(
                  color: Colors.transparent,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(MyLocalizations.of(
                          context, 'enable_auto_hashtag_text')),
                      const SizedBox(
                        height: 20,
                      ),
                      SizedBox(
                        height: 150,
                        child: TextField(
                          controller: controller,
                          expands: true,
                          minLines: null,
                          maxLines: null,
                          textAlign: TextAlign.start,
                          textAlignVertical: TextAlignVertical.top,
                          decoration: InputDecoration(
                            hintText: MyLocalizations.of(
                                context, 'enable_auto_hashtag_hint'),
                            hintMaxLines: 5,
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                  color: Style.colorPrimary, width: 1.0),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                  color: Style.colorPrimary, width: 1.0),
                            ),
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: Text(MyLocalizations.of(context, 'cancel')),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                TextButton(
                  child: Text(MyLocalizations.of(context, 'save')),
                  onPressed: () {
                    Navigator.of(context).pop(controller.text);
                  },
                ),
              ],
            );
          });
    } else {
      hashtag = await showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: Text(MyLocalizations.of(context, 'app_name')),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(MyLocalizations.of(
                        context, 'enable_auto_hashtag_text')),
                    const SizedBox(
                      height: 20,
                    ),
                    SizedBox(
                      height: 150,
                      child: TextField(
                        controller: controller,
                        expands: true,
                        minLines: null,
                        maxLines: null,
                        textAlign: TextAlign.start,
                        textAlignVertical: TextAlignVertical.top,
                        decoration: InputDecoration(
                          hintText: MyLocalizations.of(
                              context, 'enable_auto_hashtag_hint'),
                          hintMaxLines: 5,
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                                color: Style.colorPrimary, width: 1.0),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                                color: Style.colorPrimary, width: 1.0),
                          ),
                        ),
                      ),
                    )
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: Text(MyLocalizations.of(context, 'cancel')),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                TextButton(
                  child: Text(MyLocalizations.of(context, 'save')),
                  onPressed: () {
                    Navigator.of(context).pop(controller.text);
                  },
                ),
              ],
            );
          });
    }

    updateHashtag();
  }

  void updateHashtag() async {
    await UserManager.setHashtag(hashtag);

    setState(() {});
  }
}
