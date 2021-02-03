import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:mosquito_alert_app/api/api.dart';
import 'package:mosquito_alert_app/pages/auth/recover_password_page.dart';
import 'package:mosquito_alert_app/pages/main/main_vc.dart';
import 'package:mosquito_alert_app/utils/MyLocalizations.dart';
import 'package:mosquito_alert_app/utils/Utils.dart';
import 'package:mosquito_alert_app/utils/style.dart';

class LoginPassword extends StatefulWidget {
  final String email;

  LoginPassword(this.email);

  @override
  _LoginPasswordState createState() => _LoginPasswordState();
}

class _LoginPasswordState extends State<LoginPassword> {
  TextEditingController _passwordController = TextEditingController();
  StreamController<bool> loadingStream = StreamController<bool>.broadcast();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        Container(
          width: double.infinity,
          height: double.infinity,
          alignment: Alignment.topCenter,
          decoration: new BoxDecoration(
            color: Colors.white,
          ),
          child: SvgPicture.asset(
            'assets/img/bg_login_small.svg',
            width: double.infinity,
            fit: BoxFit.fitWidth,
            alignment: Alignment.topCenter,
          ),
        ),
        Scaffold(
            appBar: AppBar(
              elevation: 0,
              centerTitle: true,
              backgroundColor: Colors.transparent,
              title: Image.asset('assets/img/ic_logo.png', width: 200),
            ),
            backgroundColor: Colors.transparent,
            body: LayoutBuilder(
              builder:
                  (BuildContext context, BoxConstraints viewportConstraints) {
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: viewportConstraints.maxHeight,
                    ),
                    child: IntrinsicHeight(
                      child: SafeArea(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[
                            SizedBox(
                              height: 60,
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 15),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: <Widget>[
                                  Style.titleMedium(MyLocalizations.of(
                                      context, "enter_password_title")),
                                  SizedBox(
                                    height: 20,
                                  ),
                                  Style.textField(
                                      MyLocalizations.of(
                                          context, "user_password_txt"),
                                      _passwordController,
                                      context,
                                      obscure: true),
                                  SizedBox(
                                    height: 20,
                                  ),
                                  Container(
                                      width: double.infinity,
                                      child: Style.button(
                                          MyLocalizations.of(
                                              context, "access_txt"), () {
                                        _login();
                                      })),
                                  SizedBox(
                                    height: 20,
                                  ),
                                  Divider(),
                                  Container(
                                    width: double.infinity,
                                    child: Style.noBgButton(
                                        MyLocalizations.of(
                                            context, "forgot_password_txt"),
                                        () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) =>
                                                RecoverPassword(
                                                  email: widget.email,
                                                )),
                                      );
                                    }, textColor: Colors.black),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Container(
                                height: 50,
                              ),
                            ),
                            Utils.authBottomInfo(context),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            )),
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

  _login() async {
    FocusScope.of(context).requestFocus(FocusNode());

    loadingStream.add(true);
    ApiSingleton()
        .loginEmail(widget.email, _passwordController.text)
        .then((FirebaseUser user) {
      loadingStream.add(false);
      ApiSingleton().createProfile(user.uid);
      Navigator.popUntil(context, (route) => route.isFirst);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => MainVC()),
      );
    }).catchError((e) {
      Utils.showAlert(MyLocalizations.of(context, 'app_name'),
          MyLocalizations.of(context, 'login_alert_ko_text'), context);
      loadingStream.add(false);
      print(e);
    });
  }
}
