import 'package:flutter/material.dart';
import 'package:mosquito_alert_app/utils/style.dart';

class QuestionOption extends StatelessWidget {
  final bool selected, disabled;
  final String text;
  final String img;

  QuestionOption(this.selected, this.text, this.img, {this.disabled = false});
  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: disabled ? 0.5 : 1,
      child: Card(
        color: selected ? Style.colorPrimary : Colors.white,
        margin: EdgeInsets.symmetric(vertical: 5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        elevation: 2,
        child: Container(
          padding: EdgeInsets.all(5),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Container(
                margin: EdgeInsets.only(left: 10),
                child: Image.asset(
                  img,
                  height: 40,
                  width: 40,
                ),
              ),
              Center(
                child: Style.body(
                  text,
                  color: selected ? Colors.white : Style.textColor,
                ),
              ),
              SizedBox(width: 40),
            ],
          ),
        ),
      ),
    );
  }
}
