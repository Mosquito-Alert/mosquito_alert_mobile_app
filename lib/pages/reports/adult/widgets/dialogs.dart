import 'package:flutter/material.dart';
import 'package:mosquito_alert/mosquito_alert.dart';
import 'package:mosquito_alert_app/pages/settings_pages/campaign_tutorial_page.dart';
import 'package:mosquito_alert_app/utils/MyLocalizations.dart';
import 'package:mosquito_alert_app/utils/style.dart';

class Dialogs {
  static Future showAlertCampaign(BuildContext ctx, Campaign activeCampaign,
      void Function(BuildContext) onDismiss) {
    final appName = MyLocalizations.of(ctx, 'app_name');
    final campaignBody =
        MyLocalizations.of(ctx, 'alert_campaign_found_create_body');
    final showInfoText = MyLocalizations.of(ctx, 'show_info');
    final noShowInfoText = MyLocalizations.of(ctx, 'no_show_info');

    return showDialog(
      context: ctx,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(appName),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Style.body(
                  campaignBody,
                  textAlign: TextAlign.left,
                  fontSize: 15.0,
                  height: 1.2,
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                onDismiss(context);
              },
              child: Text(noShowInfoText),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (context) => CampaignTutorialPage()),
                );
              },
              child: Text(showInfoText),
            ),
          ],
        );
      },
    );
  }
}
