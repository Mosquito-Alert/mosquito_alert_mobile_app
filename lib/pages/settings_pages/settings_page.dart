import 'package:flutter/material.dart';
import 'package:language_picker/language_picker.dart';

import 'package:language_picker/languages.dart';
import 'package:mosquito_alert_app/pages/settings_pages/components/hashtag.dart';
import 'package:mosquito_alert_app/pages/settings_pages/components/settings_menu_widget.dart';
import 'package:mosquito_alert_app/utils/Application.dart';
import 'package:mosquito_alert_app/utils/MyLocalizations.dart';
import 'package:mosquito_alert_app/utils/PushNotificationsManager.dart';
import 'package:mosquito_alert_app/utils/UserManager.dart';
import 'package:mosquito_alert_app/utils/Utils.dart';
import 'package:mosquito_alert_app/utils/style.dart';
import 'package:package_info/package_info.dart';
import 'package:workmanager/workmanager.dart';

class SettingsPage extends StatefulWidget {
  SettingsPage();

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool isBgTrackingEnabled = false;
  var packageInfo;
  late int? numTagsAdded;
  bool isLoading = true;

  final languageCodes = [
    Language('bg_BG', 'Bulgarian'),
    Language('bn_BD', 'Bengali'),
    Language('ca_ES', 'Catalan'),
    Language('de_DE', 'German'),
    Language('el_GR', 'Greek'),
    Language('en_US', 'English'),
    Language('es_ES', 'Spanish'),
    Language('es_UY', 'Spanish (Uruguay)'),
    Language('eu_ES', 'Basque'),
    Language('fr_FR', 'French'),
    Language('gl_ES', 'Galician'),
    Language('hr_HR', 'Croatian'),
    Language('hu_HU', 'Hungarian'),
    Language('it_IT', 'Italian'),
    Language('lb_LU', 'Luxembourgish (Luxembourg)'),
    Language('mk_MK', 'Macedonian (Former Yugoslav Republic of Macedonia)'),
    Language('nl_NL', 'Dutch'),
    Language('pt_PT', 'Protuguese'),
    Language('ro_RO', 'Romanian'),
    Language('sl_SI', 'Slovenian (Slovenia)'),
    Language('sq_AL', 'Albanian'),
    Language('sr_RS', 'Serbian'),
    Language('sv_SE', 'Swedish'),
    Language('tr_TR', 'Turkish (Turkey)'),
  ];

  @override
  void initState() {
    super.initState();
    getPackageInfo();
    initializeBgTracking();
    initializeTagsNum();
  }

  void initializeBgTracking() async {
    isBgTrackingEnabled = await UserManager.getTracking();
  }

  void getPackageInfo() async {
    var _packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      packageInfo = _packageInfo;
    });
  }

  void initializeTagsNum() async {
    var hashtags = await UserManager.getHashtags();
    setState(() {
      numTagsAdded = hashtags?.length ?? 0;
      isLoading = false;
    });
  }

  void updateTagsNum(int newValue) {
    setState(() {
      numTagsAdded = newValue;
    });
  }

  @override
  Widget build(BuildContext context) {
    final key = GlobalKey<ScaffoldState>();

    return Scaffold(
      key: key,
      body: SingleChildScrollView(
        child: Container(
          margin: EdgeInsets.all(15),
          child: isLoading ? 
            Container(
                height: MediaQuery.sizeOf(context).height * 0.8,
                child: Center(
                  child: CircularProgressIndicator()
                ),
            )            
          :
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
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
            Container(
              padding: EdgeInsets.only(bottom: 12.0, top: 12.0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(5),
                color: Colors.white,
                border: Border.all(color: Colors.black.withOpacity(0.1))
              ),
              child: SwitchListTile(
                title: Style.body(MyLocalizations.of(context, 'background_tracking_title')),
                subtitle: Padding(
                  padding: EdgeInsets.only(top: 8.0),
                  child: Text(
                    MyLocalizations.of(context, 'background_tracking_subtitle'),
                    style: TextStyle(fontSize: 11),
                  ),
                ),
                value: isBgTrackingEnabled,
                activeColor: Colors.orange,
                onChanged: (bool value) async {
                  await UserManager.setTracking(value);
                  var trackingStatus = await UserManager.getTracking();
                  setState(() {
                    isBgTrackingEnabled = trackingStatus;
                  });
                  if (!isBgTrackingEnabled){
                    await Workmanager().cancelByTag('trackingTask');
                  }
                },
              ),
            ),
            SizedBox(
              height: 10,
            ),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(5),
                color: Colors.white,
                border: Border.all(color: Colors.black.withOpacity(0.1)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: ExpansionTile(
                      initiallyExpanded: numTagsAdded! > 0,
                      title: Row(
                        children: [
                            Text(
                              MyLocalizations.of(context, 'auto_tagging_settings_title'),
                            ),
                            Spacer(flex: 1),
                          if (numTagsAdded! > 0)
                            Container(
                              margin: EdgeInsets.only(left: 8.0),
                              padding: EdgeInsets.all(4.0),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.grey,
                              ),
                              child: Text(
                                '$numTagsAdded',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12.0,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 15.0),
                          child: Text(
                            MyLocalizations.of(context, 'enable_auto_hashtag_text'),
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[600]),
                          ),
                        ),
                        StringMultilineTags(updateTagsNum: updateTagsNum),
                      ],
                    ),
                  ),
                ],
              ),
            )
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
        languages: languageCodes.map(
          (language) => Language(
            language.isoCode,
            MyLocalizations.of(context, language.isoCode)
          )).toList()..sort(
                  (a, b) => a.name.compareTo(b.name)
                ),
        titlePadding: EdgeInsets.all(8.0),
        searchCursorColor: Style.colorPrimary,
        searchInputDecoration: InputDecoration(
            hintText: MyLocalizations.of(context, 'search_txt')),
        isSearchable: true,
        title:
            Text(MyLocalizations.of(context, 'select_language_txt')),
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
            ],
          );
        })),
  );
}
