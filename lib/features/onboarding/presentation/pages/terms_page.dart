import 'dart:async';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:mosquito_alert_app/core/widgets/info_page_webview.dart';
import 'package:mosquito_alert_app/core/localizations/MyLocalizations.dart';
import 'package:mosquito_alert_app/core/utils/style.dart';

class TermsPage extends StatefulWidget {
  final Future<void> Function()? onAccepted;

  TermsPage({this.onAccepted});

  @override
  _TermsPageState createState() => _TermsPageState();
}

class _TermsPageState extends State<TermsPage> {
  bool acceptConditions = false;
  bool acceptPrivacy = false;

  @override
  void initState() {
    super.initState();
    _logScreenView();
  }

  Future<void> _logScreenView() async {
    await FirebaseAnalytics.instance.logScreenView(screenName: '/consent_form');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton(
            key: ValueKey("acceptTermsButton"),
            child: Text(MyLocalizations.of(context, 'continue_txt')),
            onPressed: acceptPrivacy && acceptConditions
                ? () async {
                    await widget.onAccepted?.call();
                  }
                : null,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Style.title(MyLocalizations.of(context, 'consent_welcome_txt')),
              const SizedBox(height: 8),
              Style.body(MyLocalizations.of(context, 'consent_txt_01')),
              const SizedBox(height: 4),
              Style.body(MyLocalizations.of(context, 'consent_txt_02')),
              const SizedBox(height: 16),

              Style.titleMedium(MyLocalizations.of(context, 'consent_txt_03')),
              const SizedBox(height: 8),
              Style.body(MyLocalizations.of(context, 'consent_txt_04')),
              const SizedBox(height: 4),
              Style.body(MyLocalizations.of(context, 'consent_txt_05')),
              const SizedBox(height: 16),

              Style.titleMedium(MyLocalizations.of(context, 'consent_txt_06')),
              const SizedBox(height: 8),
              Style.body(MyLocalizations.of(context, 'consent_txt_07')),
              Row(
                children: <Widget>[
                  Checkbox(
                    visualDensity: VisualDensity.compact,
                    key: ValueKey("acceptConditionsCheckbox"),
                    value: acceptConditions,
                    onChanged: (newValue) {
                      setState(() {
                        acceptConditions = newValue!;
                      });
                    },
                  ),
                  RichText(
                    text: TextSpan(
                      style: TextStyle(color: Style.textColor, fontSize: 14),
                      children: [
                        TextSpan(
                          text: MyLocalizations.of(context, 'consent_txt_08'),
                        ),
                        TextSpan(
                          text: MyLocalizations.of(context, 'consent_txt_09'),
                          style: TextStyle(color: Style.colorPrimary),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => InfoPageInWebview(
                                    MyLocalizations.of(context, 'terms_link'),
                                    localHtml: true,
                                  ),
                                ),
                              );
                            },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Row(
                children: <Widget>[
                  Checkbox(
                    key: ValueKey("acceptPrivacyPolicy"),
                    visualDensity: VisualDensity.compact,
                    value: acceptPrivacy,
                    onChanged: (newValue) {
                      setState(() {
                        acceptPrivacy = newValue!;
                      });
                    },
                  ),
                  RichText(
                    text: TextSpan(
                      style: TextStyle(color: Style.textColor, fontSize: 14),
                      children: [
                        TextSpan(
                          text: MyLocalizations.of(context, 'consent_txt_10'),
                        ),
                        TextSpan(
                          text: MyLocalizations.of(context, 'consent_txt_11'),
                          style: TextStyle(color: Style.colorPrimary),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => InfoPageInWebview(
                                    MyLocalizations.of(context, 'privacy_link'),
                                    localHtml: true,
                                  ),
                                ),
                              );
                            },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              RichText(
                text: TextSpan(
                  style: TextStyle(color: Style.textColor, fontSize: 14),
                  children: [
                    TextSpan(
                      text: MyLocalizations.of(context, 'consent_txt_14'),
                    ),
                    TextSpan(
                      text: MyLocalizations.of(context, 'consent_txt_15'),
                      style: TextStyle(color: Style.colorPrimary),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => InfoPageInWebview(
                                MyLocalizations.of(context, 'url_about_us'),
                                localHtml: false,
                              ),
                            ),
                          );
                        },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              RichText(
                text: TextSpan(
                  style: TextStyle(color: Style.textColor, fontSize: 14),
                  children: [
                    TextSpan(
                      text: MyLocalizations.of(context, 'consent_txt_12'),
                    ),
                    TextSpan(
                      text: MyLocalizations.of(context, 'consent_txt_13'),
                      style: TextStyle(color: Style.colorPrimary),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => InfoPageInWebview(
                                MyLocalizations.of(context, 'lisence_link'),
                                localHtml: true,
                              ),
                            ),
                          );
                        },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
