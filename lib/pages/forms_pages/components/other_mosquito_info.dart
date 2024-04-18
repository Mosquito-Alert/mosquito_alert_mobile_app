import 'package:flutter/material.dart';
import 'package:mosquito_alert_app/utils/MyLocalizations.dart';
import 'package:mosquito_alert_app/utils/style.dart';
import 'package:url_launcher/url_launcher.dart';

class OtherMosquitoInfo extends StatelessWidget {
  Null get language => null;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 15),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              SizedBox(
                height: 35,
              ),
              Style.title(MyLocalizations.of(context, 'other_type_info_txt')),
              SizedBox(
                height: 10,
              ),
              Wrap(
                children: <Widget>[
                  Text('${MyLocalizations.of(context, 'more_info_in_txt')} ',
                      style: TextStyle(color: Style.textColor, fontSize: 14)),
                  InkWell(
                    onTap: () async {
                      final url = MyLocalizations.of(context, 'url_web')!;
                      if (await canLaunch(url)) {
                        await launch(url);
                      } else {
                        throw 'Could not launch $url';
                      }
                    },
                    child: Text(MyLocalizations.of(context, 'url_web')!,
                        style: TextStyle(
                            color: Style.textColor,
                            fontSize: 14,
                            decoration: TextDecoration.underline)),
                  ),
                ],
              ),
            ]),
      ),
    );
  }
}
