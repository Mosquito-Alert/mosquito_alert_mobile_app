import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:mosquito_alert_app/api/api.dart';
import 'package:mosquito_alert_app/pages/auth/login_email_page.dart';
import 'package:mosquito_alert_app/pages/main/main_vc.dart';
import 'package:mosquito_alert_app/utils/MyLocalizations.dart';
import 'package:mosquito_alert_app/utils/UserManager.dart';
import 'package:mosquito_alert_app/utils/Utils.dart';
import 'package:mosquito_alert_app/utils/style.dart';

class LoginMainPage extends StatefulWidget {
  @override
  _LoginMainPageState createState() => _LoginMainPageState();
}

class _LoginMainPageState extends State<LoginMainPage> {

  StreamController<bool> loadingStream = StreamController<bool>.broadcast();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        Scaffold(
          backgroundColor: Colors.white,
          body:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: <
                  Widget>[
            Expanded(
              flex: 7,
              child: Stack(
                children: <Widget>[
                  Image.asset(
                    'assets/img/bg_login.png',
                    width: double.infinity,
                    fit: BoxFit.fitWidth,
                    alignment: Alignment.bottomCenter,
                  ),
                  Center(
                    child: Image.asset(
                      'assets/img/ic_logo.png',
                      width: MediaQuery.of(context).size.width * 0.75,
                    ),
                  ),
                  SafeArea(
                    child: Row(
                      children: <Widget>[
                        IconButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          icon: Style.iconBack,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              margin: EdgeInsets.symmetric(horizontal: 15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  SizedBox(
                    height: 27.5,
                  ),
                  Style.title(MyLocalizations.of(context, 'welcome_app_title')),
                  Style.body(MyLocalizations.of(context, 'login_method_txt')),
                  SizedBox(
                    height: 20,
                  ),
                  Style.loginButton(
                      SvgPicture.asset(
                        'assets/img/ic_facebook.svg',
                        height: 21,
                        fit: BoxFit.fitHeight,
                      ),
                      MyLocalizations.of(context, 'login_btn1'),
                      Color(0XFF3B5998),
                      Colors.white, () {
                    _facebookSignIn();
                  }),
                  SizedBox(
                    height: 10,
                  ),
                  Style.loginButton(
                      SvgPicture.asset(
                        'assets/img/ic_twitter.svg',
                        height: 21,
                        fit: BoxFit.fitHeight,
                        color: Colors.white,
                      ),
                      MyLocalizations.of(context, 'login_btn5'),
                      Color(0XFF08a0e9),
                      Colors.white, () {
                    _twitterSignIn();
                  }),
                  SizedBox(
                    height: 10,
                  ),
                  Style.loginButton(
                      SvgPicture.asset(
                        'assets/img/ic_google.svg',
                        height: 21,
                        fit: BoxFit.fitHeight,
                      ),
                      MyLocalizations.of(context, 'login_btn2'),
                      Colors.white,
                      Colors.black, () {
                    _googleSignIn();
                  }, colorBorder: Colors.black.withOpacity(0.1)),
                  SizedBox(
                    height: 10,
                  ),
                  Divider(),
                  SizedBox(
                    height: 10,
                  ),
                  Container(
                    width: double.infinity,
                    child: Style.noBgButton(
                        MyLocalizations.of(context, 'login_btn4'), () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => LoginEmail()),
                      );
                    }, textColor: Colors.black),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 1,
              child: Container(),
            ),
            Utils.authBottomInfo(context),
          ]),
        ),
        StreamBuilder<bool>(
          stream: loadingStream.stream,
          initialData: false,
          builder: (BuildContext ctxt, AsyncSnapshot<bool> snapshot) {
            if (snapshot.hasData == false || snapshot.data == false) {
              return Container();
            }
            return Utils.loading(
              snapshot.data,
            );
          },
        )
      ],
    );
  }

  _showSocialError() {
    Utils.showAlert(MyLocalizations.of(context, 'app_name'),
        MyLocalizations.of(context, 'social_login_ko_txt'), context);
  }

  _googleSignIn() async {
    loadingStream.add(true);
    ApiSingleton().sigInWithGoogle().then((User user) async {
      loadingStream.add(false);
      if (user != null) {
        UserManager.user = user;
        await UserManager.setFrirebaseId(user.uid);

        var createProfile = await ApiSingleton().createProfile(user.uid);

        if (createProfile == true) {}
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => MainVC()),
        );
      }
    }).catchError((e) {
      loadingStream.add(false);
      _showSocialError();
      print(e);
    });
  }

  _facebookSignIn() async {
    loadingStream.add(true);
    ApiSingleton().singInWithFacebook().then((User user) {
      loadingStream.add(false);
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => MainVC()),
      );
    }).catchError((e) {
      loadingStream.add(false);
      _showSocialError();
      print(e);
    });
  }

   _twitterSignIn() async {
    loadingStream.add(true);
    ApiSingleton().singInWithTwitter().then((User user) {
      loadingStream.add(false);
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => MainVC()),
      );
    }).catchError((e) {
      loadingStream.add(false);
      _showSocialError();
      print(e);
    });
  }
}
