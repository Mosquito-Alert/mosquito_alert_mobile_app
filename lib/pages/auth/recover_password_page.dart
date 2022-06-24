import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:mosquito_alert_app/api/api.dart';
import 'package:mosquito_alert_app/utils/MyLocalizations.dart';
import 'package:mosquito_alert_app/utils/Utils.dart';
import 'package:mosquito_alert_app/utils/style.dart';

class RecoverPassword extends StatefulWidget {
  final String email;

  RecoverPassword({Key key, this.email}) : super(key: key);

  @override
  _RecoverPasswordState createState() => _RecoverPasswordState();
}

class _RecoverPasswordState extends State<RecoverPassword> {
  TextEditingController _emailController = TextEditingController();
  StreamController<bool> loadingStream = StreamController<bool>.broadcast();

  @override
  void initState() {
    super.initState();
    if (widget.email != null) {
      _emailController.text = widget.email;
    }
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
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: <Widget>[
                                  Style.titleMedium(MyLocalizations.of(
                                      context, 'recover_password_title')),
                                  SizedBox(
                                    height: 20,
                                  ),
                                  Style.textField(
                                      MyLocalizations.of(context, 'email_txt'),
                                      _emailController,
                                      context),
                                  SizedBox(
                                    height: 20,
                                  ),
                                  Container(
                                      width: double.infinity,
                                      child: Style.button(
                                          MyLocalizations.of(
                                              context, 'recover_password_btn'),
                                          () {
                                        _recoverPassword();
                                      })),
                                  SizedBox(
                                    height: 20,
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

  _recoverPassword() async {
    FocusScope.of(context).requestFocus(FocusNode());

    loadingStream.add(true);
    try {
      await ApiSingleton().recoverPassword(_emailController.text);
    } catch (e) {
      print(e.message);
    }

    Utils.showAlert(MyLocalizations.of(context, 'app_name'),
        MyLocalizations.of(context, 'recover_password_alert'), context);

    loadingStream.add(false);
  }
}
