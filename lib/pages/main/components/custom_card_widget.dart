import 'package:flutter/material.dart';
import 'package:mosquito_alert_app/utils/MyLocalizations.dart';

class CustomCard extends StatelessWidget {
  final String text, image_path, color;
  final dynamic reportFunction;
  CustomCard({required this.text, required this.image_path, required this.color, required this.reportFunction});

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 5.0,
      borderRadius: BorderRadius.circular(100),
      child: Container(
        height: 70.0,
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(100),
        ),
        child: InkWell(
          onTap: () {
            reportFunction();
          },
          child: Row(
            children: <Widget>[
              CircleAvatar(
                radius: 35,
                backgroundColor: Color(int.parse(color, radix: 16)),
                child: ClipOval(
                  child: Image.asset(image_path, fit: BoxFit.cover, width: 65, height: 65),
                ),
              ),
              SizedBox(width: 15),
              Expanded(
                child: Text(
                  MyLocalizations.of(context, text),
                  style: TextStyle(
                    fontSize: 18,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
