import 'package:flutter/material.dart';
import 'package:language_pickers/language_picker_dialog.dart';
import 'package:language_pickers/languages.dart';
import 'package:mosquito_alert_app/api/api.dart';
import 'package:mosquito_alert_app/pages/auth/login_main_page.dart';
import 'package:mosquito_alert_app/pages/info_pages/info_page.dart';
import 'package:mosquito_alert_app/pages/main/main_vc.dart';
import 'package:mosquito_alert_app/pages/settings_pages/components/settings_menu_widget.dart';
import 'package:mosquito_alert_app/pages/settings_pages/gallery_page.dart';
import 'package:mosquito_alert_app/pages/settings_pages/tutorial_page.dart';
import 'package:mosquito_alert_app/utils/Application.dart';
import 'package:mosquito_alert_app/utils/MyLocalizations.dart';
import 'package:mosquito_alert_app/utils/UserManager.dart';
import 'package:mosquito_alert_app/utils/Utils.dart';
import 'package:mosquito_alert_app/utils/style.dart';
import 'package:flutter_background_geolocation/flutter_background_geolocation.dart'
as bg;
import 'package:package_info/package_info.dart';

class CountriesInvolvedPage extends StatefulWidget {
  CountriesInvolvedPage();

  @override
  _CountriesInvolvedPageState createState() => _CountriesInvolvedPageState();
}

class _CountriesInvolvedPageState extends State<CountriesInvolvedPage> {
  bool enableTracking = false;
  var packageInfo;

  @override
  void initState() {
    super.initState();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        centerTitle: true,
        title: Style.title('countries_involved',
            fontSize: 16),
      ),
      body: SingleChildScrollView(
        child: Container(
          margin: EdgeInsets.all(15),
          child:
          Column(crossAxisAlignment: CrossAxisAlignment.center, children: <
              Widget>[
            SizedBox(
              height: 17,
            ),
            Style.body('thank_to_involved_countries', textAlign: TextAlign.center),
            SizedBox(
              height: 17,
            ),
            Container(
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(5),
                  color: Colors.white,
                  border: Border.all(color: Colors.black.withOpacity(0.1))),
              child: ListTile(
                onTap: () {
                  MaterialPageRoute(builder: (context)
                  =>
                      GalleryPage());
                },
                leading: Icon(Icons.flag),
                title: Text('country_involved_1',
                  maxLines: 2,
                  textAlign: TextAlign.left,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    height: 1.2,
                    color: Style.textColor,
                    fontSize: 14,
                    fontWeight: FontWeight.bold
                  ),
                ),
                subtitle: Style.body('country_involved_1_description'),
                trailing: Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.black,
                  size: 18,
                ),
              ),
            ),
            SizedBox(height: 10,),
            Container(
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(5),
                  color: Colors.white,
                  border: Border.all(color: Colors.black.withOpacity(0.1))),
              child: ListTile(
                onTap: () {
                  MaterialPageRoute(builder: (context)
                  =>
                      GalleryPage());
                },
                leading: Icon(Icons.flag),
                title: Text('country_involved_1',
                  maxLines: 2,
                  textAlign: TextAlign.left,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      height: 1.2,
                      color: Style.textColor,
                      fontSize: 14,
                      fontWeight: FontWeight.bold
                  ),
                ),
                subtitle: Style.body('country_involved_1_description'),
                trailing: Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.black,
                  size: 18,
                ),
              ),
            )


          ]),
        ),
      ),
    );
  }
}
