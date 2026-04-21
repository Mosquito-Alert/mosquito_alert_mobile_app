import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:language_picker/language_picker.dart';
import 'package:language_picker/languages.dart';
import 'package:mosquito_alert_app/features/fixes/presentation/state/fixes_provider.dart';
import 'package:mosquito_alert_app/features/fixes/services/permissions_manager.dart';
import 'package:mosquito_alert_app/features/settings/presentation/state/settings_provider.dart';
import 'package:mosquito_alert_app/core/widgets/tags_text_field.dart';
import 'package:mosquito_alert_app/features/user/presentation/state/user_provider.dart';
import 'package:mosquito_alert_app/core/localizations/MyLocalizations.dart';
import 'package:mosquito_alert_app/core/utils/style.dart';
import 'package:provider/provider.dart';
import 'package:country_codes/country_codes.dart';

class SettingsPage extends StatefulWidget {
  SettingsPage();

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool isBgTrackingLoading = false;

  List<Language> availableLanguages = [];

  @override
  void initState() {
    super.initState();
    availableLanguages = MyLocalizations.supportedLocales
        .map((locale) => _localeToLanguage(locale))
        .toList();
    _logScreenView();
  }

  Future<void> _logScreenView() async {
    await FirebaseAnalytics.instance.logScreenView(screenName: '/settings');
  }

  @override
  Widget build(BuildContext context) {
    final settingsProvider = context.watch<SettingsProvider>();

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                MyLocalizations.of(context, 'settings_title'),
                style: TextStyle(
                  color: Style.colorPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 16),
            SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  // Language picker
                  ListTile(
                    leading: const Icon(
                      Icons.language_outlined,
                      color: Colors.black,
                    ),
                    title: Text(
                      MyLocalizations.of(context, 'select_language_txt'),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Text(
                            _localeToLanguage(
                              Provider.of<UserProvider>(context).locale,
                            ).nativeName,
                            style: const TextStyle(
                              color: Colors.black54,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.arrow_forward_ios,
                          color: Colors.black,
                          size: 16,
                        ),
                      ],
                    ),
                    onTap: _openLanguagePickerDialog,
                  ),
                  const Divider(),
                  // Background tracking toggle
                  Consumer<FixesProvider>(
                    builder: (context, fixesProvider, _) => SwitchListTile(
                      title: Text(
                        MyLocalizations.of(
                          context,
                          'background_tracking_title',
                        ),
                      ),
                      isThreeLine: true,
                      subtitle: Text(
                        MyLocalizations.of(
                          context,
                          'background_tracking_subtitle',
                        ),
                        style: const TextStyle(fontSize: 11),
                      ),
                      value: fixesProvider.isEnabled,
                      activeThumbColor: Style.colorPrimary,
                      secondary: isBgTrackingLoading
                          ? CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Style.colorPrimary,
                              ),
                            )
                          : const Icon(Icons.share_location_outlined),
                      onChanged: (bool value) async {
                        if (value) {
                          setState(() {
                            isBgTrackingLoading = true;
                          });
                          await PermissionsManager.requestPermissions();
                          await fixesProvider.enableTracking(
                            runImmediately: true,
                          );
                          setState(() {
                            isBgTrackingLoading = false;
                          });
                        } else {
                          await fixesProvider.disableTracking();
                        }
                      },
                    ),
                  ),
                  const Divider(),
                  // Hashtag settings
                  ExpansionTile(
                    leading: const Icon(
                      Icons.sell_outlined,
                      color: Colors.black,
                    ),
                    initiallyExpanded: settingsProvider.hashtags.length > 0,
                    title: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          MyLocalizations.of(
                            context,
                            'auto_tagging_settings_title',
                          ),
                        ),
                        const Spacer(),
                        if (settingsProvider.hashtags.length > 0)
                          Badge.count(
                            count: settingsProvider.hashtags.length,
                            backgroundColor: Colors.grey,
                            textColor: Colors.white,
                          ),
                      ],
                    ),
                    childrenPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    children: [
                      Column(
                        children: [
                          Text(
                            MyLocalizations.of(
                              context,
                              'enable_auto_hashtag_text',
                            ),
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 10),
                          TagsTextField(
                            initialTags: settingsProvider.hashtags,
                            onTagsChanged: (tags) async {
                              settingsProvider.hashtags = tags;
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
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
              ? (() {
                  try {
                    final details = CountryCodes.detailsForLocale(locale);
                    return details.name != null ? " (${details.name})" : "";
                  } catch (e) {
                    return "";
                  }
                })()
              : ""),
    ); // Clean native name
  }

  void _openLanguagePickerDialog() => showDialog(
    context: context,
    builder: (context) => Theme(
      data: Theme.of(context).copyWith(primaryColor: Style.colorPrimary),
      child: LanguagePickerDialog(
        languages: availableLanguages
          ..sort((a, b) => a.nativeName.compareTo(b.nativeName)),
        titlePadding: const EdgeInsets.all(8.0),
        searchCursorColor: Style.colorPrimary,
        searchInputDecoration: InputDecoration(
          hintText: MyLocalizations.of(context, 'search_txt'),
        ),
        isSearchable: true,
        title: Text(MyLocalizations.of(context, 'select_language_txt')),
        onValuePicked: (Language language) async {
          final isoCodeParts = language.isoCode.split('_');
          final languageCode = isoCodeParts[0];
          final countryCode = isoCodeParts.length > 1 ? isoCodeParts[1] : null;
          final locale = Locale(languageCode, countryCode);

          final userProvider = Provider.of<UserProvider>(
            context,
            listen: false,
          );
          try {
            await userProvider.setLocale(locale);
          } catch (e) {
            print('Error setting locale: $e');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Could not update language on server.'),
                duration: Duration(seconds: 3),
              ),
            );
          }
        },
        itemBuilder: (Language language) {
          return Text(language.nativeName);
        },
      ),
    ),
  );
}
