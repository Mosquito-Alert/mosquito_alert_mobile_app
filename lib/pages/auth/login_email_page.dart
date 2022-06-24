import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:mosquito_alert_app/api/api.dart';
import 'package:mosquito_alert_app/pages/auth/login_password_page.dart';
import 'package:mosquito_alert_app/pages/auth/signup_page.dart';
import 'package:mosquito_alert_app/utils/MyLocalizations.dart';
import 'package:mosquito_alert_app/utils/Utils.dart';
import 'package:mosquito_alert_app/utils/style.dart';

class LoginEmail extends StatefulWidget {
  @override
  _LoginEmailState createState() => _LoginEmailState();
}

class _LoginEmailState extends State<LoginEmail> {
  TextEditingController _emailController = TextEditingController();
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
                                    context, 'enter_email_title')),
                                SizedBox(
                                  height: 20,
                                ),
                                Style.textField(
                                    MyLocalizations.of(context, 'email_txt'),
                                    _emailController,
                                    context,
                                    keyboardType: TextInputType.emailAddress),
                                SizedBox(
                                  height: 20,
                                ),
                                Container(
                                    width: double.infinity,
                                    child: Style.button(
                                        MyLocalizations.of(
                                            context, 'access_txt'), () {
                                      _checkEmail();
                                    })),
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
          ),
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

  _checkEmail() async {
    FocusScope.of(context).requestFocus(FocusNode());

    loadingStream.add(true);
    if (!Utils.mailRegExp.hasMatch(_emailController.text)) {
      Utils.showAlert(MyLocalizations.of(context, 'app_name'),
          MyLocalizations.of(context, 'invalid_mail_txt'), context);
      loadingStream.add(false);
    } else {
      ApiSingleton().checkEmail(_emailController.text).then((res) {
        loadingStream.add(false);
        if (res.length > 0) {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => LoginPassword(_emailController.text)),
          );
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => SignupPage(_emailController.text)),
          );
        }
      }).catchError((e) {
        loadingStream.add(false);
        Utils.showAlert(MyLocalizations.of(context, 'app_name'),
            MyLocalizations.of(context, 'email_error_txt'), context);
        print(e);
      });
    }
  }
}
