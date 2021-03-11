import 'package:flutter/material.dart';
import 'package:mosquito_alert_app/utils/style.dart';

class CustomCard extends StatelessWidget {
  final String img, title;
  final bool selected, disabled;
  CustomCard({this.img, this.title, this.selected, this.disabled});

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: disabled == true ? 0.5 : 1,
      child: Container(
        // height: double.infinity,
        child: Card(
          color: selected == true ? Style.colorPrimary : Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: disabled == true ? 0 : 3,
          child: Padding(
            padding: const EdgeInsets.all(5.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                img != null
                    ? Padding(
                        padding: const EdgeInsets.only(top: 0.0, bottom: 0),
                        child: Image.asset(
                          img,
                          height: 130,
                          width: 130,
                          // fit: BoxFit.fitHeight,
                        ),
                      )
                    : SizedBox(
                        height: 140,
                      ),
                Expanded(
                  child: Container(
                    margin: EdgeInsets.symmetric(horizontal: 5),
                    child: Style.titleMedium(title,
                        textAlign: TextAlign.center, fontSize: 16
                        // minFontSize: 14,
                        // maxFontSize: 16,
                        // style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
                        ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
