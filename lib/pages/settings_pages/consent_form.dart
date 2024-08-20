import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:mosquito_alert_app/pages/info_pages/info_page_webview.dart';
import 'package:mosquito_alert_app/utils/MyLocalizations.dart';
import 'package:mosquito_alert_app/utils/style.dart';

class ConsentForm extends StatefulWidget {
  @override
  _ConsentFormState createState() => _ConsentFormState();
}

class _ConsentFormState extends State<ConsentForm> {
  bool? acceptConditions = false;
  bool? acceptPrivacy = false;
  StreamController<bool> buttonStream = StreamController<bool>.broadcast();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: <Widget>[
            SingleChildScrollView(
              child: Column(
                children: <Widget>[
                  Image.asset(
                    'assets/img/bg_consent.png',
                    fit: BoxFit.cover,
                  ),
                  Container(
                    margin: EdgeInsets.symmetric(horizontal: 15),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        SizedBox(
                          height: 35,
                        ),
                        Style.title(
                            MyLocalizations.of(context, 'consent_welcome_txt')),
                        SizedBox(
                          height: 20,
                        ),
                        Style.body(
                            MyLocalizations.of(context, 'consent_txt_01')),
                        SizedBox(
                          height: 5,
                        ),
                        Style.body(
                            MyLocalizations.of(context, 'consent_txt_02')),
                        SizedBox(
                          height: 20,
                        ),
                        Style.titleMedium(
                            MyLocalizations.of(context, 'consent_txt_03')),
                        SizedBox(
                          height: 10,
                        ),
                        Style.body(
                            MyLocalizations.of(context, 'consent_txt_04')),
                        SizedBox(
                          height: 5,
                        ),
                        Style.body(
                            MyLocalizations.of(context, 'consent_txt_05')),
                        SizedBox(
                          height: 20,
                        ),
                        Style.titleMedium(
                            MyLocalizations.of(context, 'consent_txt_06')),
                        SizedBox(
                          height: 10,
                        ),
                        Style.body(
                            MyLocalizations.of(context, 'consent_txt_07')),
                        Row(
                          children: <Widget>[
                            Checkbox(
                              value: acceptConditions,
                              onChanged: (newValue) {
                                buttonStream.add(acceptPrivacy! && newValue!);
                                setState(() {
                                  acceptConditions = newValue;
                                });
                              },
                            ),
                            Expanded(
                              child: RichText(
                                text: TextSpan(
                                    style: TextStyle(
                                        color: Style.textColor, fontSize: 14),
                                    children: [
                                      TextSpan(
                                        text: MyLocalizations.of(
                                            context, 'consent_txt_08'),
                                      ),
                                      TextSpan(
                                          text: MyLocalizations.of(
                                              context, 'consent_txt_09'),
                                          style: TextStyle(
                                              color: Style.colorPrimary),
                                          recognizer: TapGestureRecognizer()
                                            ..onTap = () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                    builder: (context) =>
                                                        InfoPageInWebview(
                                                          MyLocalizations.of(
                                                              context,
                                                              'terms_link'),
                                                          localHtml: true,
                                                        )),
                                              );
                                            }),
                                    ]),
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: <Widget>[
                            Checkbox(
                              value: acceptPrivacy,
                              onChanged: (newValue) {
                                buttonStream.add(acceptConditions! && newValue!);
                                setState(() {
                                  acceptPrivacy = newValue;
                                });
                              },
                            ),
                            Expanded(
                              child: RichText(
                                text: TextSpan(
                                    style: TextStyle(
                                        color: Style.textColor, fontSize: 14),
                                    children: [
                                      TextSpan(
                                        text: MyLocalizations.of(
                                            context, 'consent_txt_10'),
                                      ),
                                      TextSpan(
                                        text: MyLocalizations.of(
                                            context, 'consent_txt_11'),
                                        style: TextStyle(
                                            color: Style.colorPrimary),
                                        recognizer: TapGestureRecognizer()
                                          ..onTap = () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                  builder: (context) =>
                                                      InfoPageInWebview(
                                                        MyLocalizations.of(
                                                            context,
                                                            'privacy_link'),
                                                        localHtml: true,
                                                      )),
                                            );
                                          },
                                      ),
                                    ]),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(
                          height: 10,
                        ),
                        RichText(
                          text: TextSpan(
                              style: TextStyle(
                                  color: Style.textColor, fontSize: 14),
                              children: [
                                TextSpan(
                                  text: MyLocalizations.of(
                                      context, 'consent_txt_14'),
                                ),
                                TextSpan(
                                  text: MyLocalizations.of(
                                      context, 'consent_txt_15'),
                                  style:
                                      TextStyle(color: Style.colorPrimary),
                                  recognizer: TapGestureRecognizer()
                                    ..onTap = () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) => InfoPageInWebview(
                                                  MyLocalizations.of(
                                                      context, 'url_about_us'),
                                                  localHtml: false,
                                                )),
                                      );
                                    },
                                ),
                              ]),
                        ),
                        SizedBox(
                          height: 10,
                        ),
                        RichText(
                          text: TextSpan(
                              style: TextStyle(
                                  color: Style.textColor, fontSize: 14),
                              children: [
                                TextSpan(
                                  text: MyLocalizations.of(
                                      context, 'consent_txt_12'),
                                ),
                                TextSpan(
                                  text: MyLocalizations.of(
                                      context, 'consent_txt_13'),
                                  style:
                                      TextStyle(color: Style.colorPrimary),
                                  recognizer: TapGestureRecognizer()
                                    ..onTap = () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) => InfoPageInWebview(
                                                  MyLocalizations.of(
                                                      context, 'lisence_link'),
                                                  localHtml: true,
                                                )),
                                      );
                                    },
                                ),
                              ]),
                        ),
                        SizedBox(
                          height: 10,
                        ),
                      ],
                    ),
                  ),
                  Style.bottomOffset
                ],
              ),
            ),
            StreamBuilder<Object>(
                stream: buttonStream.stream,
                initialData: acceptPrivacy! && acceptConditions!,
                builder: (context, snapshot) {
                  return Container(
                    margin: EdgeInsets.all(15),
                    width: double.infinity,
                    child: Style.button(
                      MyLocalizations.of(context, 'continue_txt'),
                      snapshot.data as bool
                      ? () {
                        Navigator.pop(context);
                      }
                      : null),
                  );
                })
          ],
        ),
      ),
    );
  }
}
