import 'package:flutter/material.dart';
import 'package:mosquito_alert_app/utils/style.dart';

class CustomImageButton extends StatelessWidget {
  final String img, title;
  final bool selected, disabled;
  CustomImageButton({this.img, this.title, this.selected, this.disabled});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size.height;
    return Opacity(
      opacity: disabled == true ? 0.5 : 1,
      child: Container(
        height: size * 0.1,
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
                    ? Expanded(
                        flex: 3,
                        child: Image.asset(
                          img,
                          // height: 120,
                          // width: 120,
                          // fit: BoxFit.fitHeight,
                        ),
                      )
                    : SizedBox(
                        height: 140,
                      ),
                Expanded(
                  flex: MediaQuery.of(context).textScaleFactor < 1.23 ? 1 : 2,
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
