import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:language_picker/language_picker.dart';
import 'package:language_picker/languages.dart';
import 'package:mosquito_alert/mosquito_alert.dart';
import 'package:mosquito_alert_app/pages/settings_pages/components/hashtag.dart';
import 'package:mosquito_alert_app/pages/settings_pages/components/settings_menu_widget.dart';
import 'package:mosquito_alert_app/providers/user_provider.dart';
import 'package:mosquito_alert_app/utils/BackgroundTracking.dart';
import 'package:mosquito_alert_app/utils/MyLocalizations.dart';
import 'package:mosquito_alert_app/utils/UserManager.dart';
import 'package:mosquito_alert_app/utils/style.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:country_codes/country_codes.dart';

class SettingsPage extends StatefulWidget {
  SettingsPage();

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool isBgTrackingEnabled = false;
  bool isBgTrackingLoading = false;
  var packageInfo;
  late int? numTagsAdded;
  bool isLoading = true;
  late UsersApi usersApi;

  @override
  void initState() {
    super.initState();
    MosquitoAlert apiClient =
        Provider.of<MosquitoAlert>(context, listen: false);
    usersApi = apiClient.getUsersApi();
    _logScreenView();
    getPackageInfo();
    initializeBgTracking();
    initializeTagsNum();
  }

  Future<void> _logScreenView() async {
    await FirebaseAnalytics.instance.logScreenView(screenName: '/settings');
  }

  void initializeBgTracking() async {
    isBgTrackingEnabled = await BackgroundTracking.isEnabled();
  }

  void getPackageInfo() async {
    PackageInfo _packageInfo = await PackageInfo.fromPlatform();
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
      body: SafeArea(
        child: SingleChildScrollView(
          child: Container(
            margin: const EdgeInsets.all(15),
            child: isLoading
                ? Container(
                    height: MediaQuery.sizeOf(context).height * 0.8,
                    child: Center(
                        child: CircularProgressIndicator(
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Style.colorPrimary),
                    )),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                        const SizedBox(
                          height: 10,
                        ),
                        SettingsMenuWidget(
                          MyLocalizations.of(context, 'select_language_txt'),
                          _openLanguagePickerDialog,
                          trailingText: _localeToLanguage(
                                  Provider.of<UserProvider>(context).locale)
                              .nativeName,
                        ),
                        const SizedBox(
                          height: 10,
                        ),
                        Container(
                          padding:
                              const EdgeInsets.only(bottom: 12.0, top: 12.0),
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(5),
                              color: Colors.white,
                              border: Border.all(
                                  color: Colors.black.withValues(alpha: 0.1))),
                          child: SwitchListTile(
                            title: Style.body(MyLocalizations.of(
                                context, 'background_tracking_title')),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                MyLocalizations.of(
                                    context, 'background_tracking_subtitle'),
                                style: const TextStyle(fontSize: 11),
                              ),
                            ),
                            value: isBgTrackingEnabled,
                            activeColor: Style.colorPrimary,
                            secondary: isBgTrackingLoading
                                ? CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Style.colorPrimary),
                                  )
                                : null,
                            onChanged: (bool value) async {
                              if (value) {
                                setState(() {
                                  isBgTrackingLoading = true;
                                  isBgTrackingEnabled = true;
                                });
                                await BackgroundTracking.start(shouldRun: true)
                                    .whenComplete(() {
                                  setState(() {
                                    isBgTrackingLoading = false;
                                  });
                                });
                              } else {
                                setState(() {
                                  isBgTrackingEnabled = false;
                                });
                                await BackgroundTracking.stop();
                              }
                              bool trackingStatus =
                                  await BackgroundTracking.isEnabled();
                              setState(() {
                                isBgTrackingEnabled = trackingStatus;
                              });
                            },
                          ),
                        ),
                        const SizedBox(
                          height: 10,
                        ),
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(5),
                            color: Colors.white,
                            border: Border.all(
                                color: Colors.black.withValues(alpha: 0.1)),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: ExpansionTile(
                                  initiallyExpanded: numTagsAdded! > 0,
                                  title: Row(
                                    children: [
                                      Style.body(
                                        MyLocalizations.of(context,
                                            'auto_tagging_settings_title'),
                                      ),
                                      Spacer(flex: 1),
                                      if (numTagsAdded! > 0)
                                        Container(
                                          margin:
                                              const EdgeInsets.only(left: 8.0),
                                          padding: const EdgeInsets.all(4.0),
                                          decoration: const BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: Colors.grey,
                                          ),
                                          child: Text(
                                            '$numTagsAdded',
                                            style: const TextStyle(
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
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 15.0),
                                      child: Text(
                                        MyLocalizations.of(context,
                                            'enable_auto_hashtag_text'),
                                        style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey[600]),
                                      ),
                                    ),
                                    StringMultilineTags(
                                        updateTagsNum: updateTagsNum),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        )
                      ]),
          ),
        ),
      ),
    );
  }

  Language _localeToLanguage(Locale locale) {
    final _tempBaseLanguage = Language.fromIsoCode(locale.languageCode);
    final _numDuplicatedLanguages = MyLocalizations.supportedLocales
        .where((l) => l.languageCode == locale.languageCode)
        .length;

    return Language(
        _tempBaseLanguage.isoCode +
            (locale.countryCode != null && locale.countryCode!.isNotEmpty
                ? "_" + locale.countryCode!
                : ""),
        _tempBaseLanguage.name,
        _tempBaseLanguage.nativeName.split(',').first +
            (_numDuplicatedLanguages > 1 && locale.countryCode != null
                ? " (${CountryCodes.detailsForLocale(locale).name})"
                : "")); // Clean native name
  }

  List<Language> _getLanguages() {
    final List<Language> result = [];

    for (final locale in MyLocalizations.supportedLocales) {
      result.add(_localeToLanguage(locale));
    }

    return result;
  }

  void _openLanguagePickerDialog() => showDialog(
        context: context,
        builder: (context) => Theme(
            data: Theme.of(context).copyWith(primaryColor: Style.colorPrimary),
            child: LanguagePickerDialog(
                languages: _getLanguages()
                  ..sort((a, b) => a.nativeName.compareTo(b.nativeName)),
                titlePadding: const EdgeInsets.all(8.0),
                searchCursorColor: Style.colorPrimary,
                searchInputDecoration: InputDecoration(
                    hintText: MyLocalizations.of(context, 'search_txt')),
                isSearchable: true,
                title: Text(MyLocalizations.of(context, 'select_language_txt')),
                onValuePicked: (Language language) async {
                  await _selectLanguage(language);
                },
                itemBuilder: (Language language) {
                  return Text(language.nativeName);
                })),
      );

  Future<void> _selectLanguage(Language language) async {
    final isoCodeParts = language.isoCode.split('_');
    final languageCode = isoCodeParts[0];
    final countryCode = isoCodeParts.length > 1 ? isoCodeParts[1] : null;
    final locale = Locale(languageCode, countryCode);

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    try {
      userProvider.locale = locale;
    } catch (e) {
      print('Error setting locale: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not update language on server.'),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }
}
