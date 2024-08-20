import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:mosquito_alert_app/pages/forms_pages/adult_report_page.dart';
import 'package:mosquito_alert_app/pages/forms_pages/biting_report_page.dart';
import 'package:mosquito_alert_app/pages/forms_pages/breeding_report_page.dart';
import 'package:mosquito_alert_app/pages/main/components/custom_card_widget.dart';
import 'package:mosquito_alert_app/pages/map/public_map.dart';
import 'package:mosquito_alert_app/utils/MyLocalizations.dart';
import 'package:mosquito_alert_app/utils/Utils.dart';
import 'package:mosquito_alert_app/utils/style.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  StreamController<bool> loadingStream = StreamController<bool>.broadcast();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    loadingStream.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        Scaffold(
          body: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints viewportConstraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: viewportConstraints.maxHeight,
                  ),
                  child: IntrinsicHeight(
                    child: Stack(
                      children: <Widget>[
                        Container(
                          alignment: Alignment.bottomCenter,
                          child: Image.asset(
                            'assets/img/bottoms/bottom_main.png',
                            width: double.infinity,
                            fit: BoxFit.fitWidth,
                            alignment: Alignment.bottomCenter,
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: SingleChildScrollView(
                            child: Column(
                              children: <Widget>[
                                SizedBox(
                                  height: 24,
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: <Widget>[
                                    Expanded(
                                      flex: 2,
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: <Widget>[
                                          Style.body(
                                              MyLocalizations.of(context, getRandomWhatToDoText()),
                                              fontSize: 16),
                                        ]),
                                    )                                      
                                  ]
                                ),
                                SizedBox(height: 30),
                                CustomCard(
                                  text: 'single_mosquito',
                                  image_path: 'assets/img/ic_mosquito_report.png',
                                  color: '40DFD458',
                                  reportFunction: _createAdultReport
                                ),
                                SizedBox(height: 10),
                                CustomCard(
                                  text: 'single_bite',
                                  image_path: 'assets/img/ic_bite_report.png',
                                  color: '40D28A73',
                                  reportFunction: _createBiteReport
                                ),
                                SizedBox(height: 10),
                                CustomCard(
                                  text: 'single_breeding_site',
                                  image_path: 'assets/img/ic_breeding_report.png',
                                  color: '407D9393',
                                  reportFunction: _createSiteReport
                                ),
                                SizedBox(height: 30),
                                Material(
                                  elevation: 5.0,
                                  borderRadius: BorderRadius.circular(100),
                                  child: Container(
                                    height: 60.0,
                                    decoration: BoxDecoration(
                                      color: Colors.transparent,
                                      borderRadius: BorderRadius.circular(100),
                                    ),
                                    child: InkWell(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(builder: (context) => PublicMap()),
                                        );
                                      },
                                      child: Row(
                                        children: <Widget>[
                                          Padding(
                                            padding: EdgeInsets.only(left: 10.0),
                                            child: SvgPicture.asset('assets/img/maps/public-map-icon.svg', width: 50,),
                                          ),
                                          SizedBox(width: 15),
                                          Expanded(
                                            child: Text(
                                              MyLocalizations.of(context, 'public_map_tab'),
                                              style: TextStyle(
                                                fontSize: 18,
                                                color: Colors.grey[600]
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                )
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          )
        ),
        Positioned.fill(
          child: StreamBuilder<bool>(
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
          ),
        )
      ],
    );
  }

  String getRandomWhatToDoText() {
    var rnd = Random();
    var i = rnd.nextInt(5) + 1;
    return 'what_to_do_txt_$i';
  }

  Future<void> _createBiteReport() async {
    var createReport = await Utils.createNewReport('bite');
    loadingStream.add(false);
    if (createReport) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => BitingReportPage()),
      );
    } else {
      print('Bite report was not created');
      loadingStream.add(false);
    }
  }

  Future<void> _createAdultReport() async {
    var createReport = await Utils.createNewReport('adult');
    loadingStream.add(false);
    if (createReport) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => AdultReportPage()),
      );
    } else {
      print('Adult report was not created');
      loadingStream.add(false);
    }
  }

  Future<void> _createSiteReport() async {
    var createReport = await Utils.createNewReport('site');
    loadingStream.add(false);
    if (createReport) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => BreedingReportPage()),
      );
    } else {
      print('Site report was not created');
      loadingStream.add(false);
    }
  }
}