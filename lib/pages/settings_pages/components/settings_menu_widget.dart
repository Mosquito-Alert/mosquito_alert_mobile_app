import 'package:flutter/material.dart';
import 'package:mosquito_alert_app/utils/style.dart';

class SettingsMenuWidget extends StatelessWidget {
  final String? text;
  final Function onTap;

  SettingsMenuWidget(this.text, this.onTap);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(5),
          color: Colors.white,
          border: Border.all(color: Colors.black.withOpacity(0.1))),
      child: ListTile(
        onTap: () {
          onTap();
        },
        title: Style.body(text),
        trailing: Icon(
          Icons.arrow_forward_ios,
          color: Colors.black,
          size: 18,
        ),
      ),
    );
  }
}
