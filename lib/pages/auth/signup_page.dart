import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:mosquito_alert_app/api/api.dart';
import 'package:mosquito_alert_app/pages/main/main_vc.dart';
import 'package:mosquito_alert_app/utils/MyLocalizations.dart';
import 'package:mosquito_alert_app/utils/UserManager.dart';
import 'package:mosquito_alert_app/utils/Utils.dart';
import 'package:mosquito_alert_app/utils/style.dart';

class SignupPage extends StatefulWidget {
  final String email;

  SignupPage(this.email);

  @override
  _SignupPageState createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  TextEditingController _emailController = TextEditingController();
  TextEditingController _passwordController = TextEditingController();
  TextEditingController _firstNameController = TextEditingController();
  TextEditingController _lastNameController = TextEditingController();
  StreamController<bool> loadingStream = StreamController<bool>.broadcast();

  @override
  void initState() {
    _emailController.text = widget.email;
    super.initState();
  }

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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: <Widget>[
                                      Style.titleMedium(MyLocalizations.of(
                                          context, "signup_user_title")),
                                      SizedBox(
                                        height: 20,
                                      ),
                                      Form(
                                        child: Column(children: <Widget>[
                                          Style.textField(
                                              MyLocalizations.of(
                                                  context, "email_txt"),
                                              _emailController,
                                              context,
                                              enabled: false),
                                          SizedBox(
                                            height: 10,
                                          ),
                                          Style.textField(
                                              MyLocalizations.of(
                                                  context, "password_txt"),
                                              _passwordController,
                                              context,
                                              obscure: true),
                                          SizedBox(
                                            height: 10,
                                          ),
                                          Container(
                                              width: double.infinity,
                                              child: Style.button(
                                                  MyLocalizations.of(
                                                      context, "signup_btn"),
                                                  () {
                                                _signUp();
                                              }))
                                        ]),
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
                              ]),
                        ),
                      )));
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

  _showSocialError() {
    Utils.showAlert(MyLocalizations.of(context, "app_name"),
        MyLocalizations.of(context, "social_login_ko_txt"), context);
  }

  _signUp() async {
    loadingStream.add(true);
    ApiSingleton()
        .singUp(
      _emailController.text,
      _passwordController.text,
    )
        .then((user) async {
      loadingStream.add(false);
      UserManager.user = user;
      await UserManager.setFrirebaseId(user.uid);

      var createProfile = await ApiSingleton().createProfile(user.uid);

      if (createProfile == true) {}
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
