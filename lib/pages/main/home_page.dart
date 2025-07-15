import 'dart:async';
import 'dart:math';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
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
  late String _suggestedActionTextId;

  @override
  void initState() {
    super.initState();
    _suggestedActionTextId = getRandomWhatToDoText();
    _logScreenView();
  }

  @override
  void dispose() {
    loadingStream.close();
    super.dispose();
  }

  Future<void> _logScreenView() async {
    await FirebaseAnalytics.instance.logScreenView(
        screenName: '/home',
        parameters: {'action_text_id': _suggestedActionTextId});
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        Scaffold(body: LayoutBuilder(
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
                          'assets/img/bottoms/bottom_main.webp',
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
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: <Widget>[
                                    Expanded(
                                      flex: 2,
                                      child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: <Widget>[
                                            Style.body(
                                                MyLocalizations.of(context,
                                                    _suggestedActionTextId),
                                                fontSize: 16),
                                          ]),
                                    )
                                  ]),
                              SizedBox(height: 30),
                              CustomCard(
                                  text: 'single_mosquito',
                                  image_path:
                                      'assets/img/ic_mosquito_report.webp',
                                  color: '40DFD458',
                                  onTap: _createAdultReport),
                              SizedBox(height: 10),
                              CustomCard(
                                  text: 'single_bite',
                                  image_path: 'assets/img/ic_bite_report.webp',
                                  color: '40D28A73',
                                  onTap: _createBiteReport),
                              SizedBox(height: 10),
                              CustomCard(
                                  text: 'single_breeding_site',
                                  image_path:
                                      'assets/img/ic_breeding_report.webp',
                                  color: '407D9393',
                                  onTap: _createSiteReport),
                              SizedBox(height: 10),
                              CustomCard(
                                  text: 'public_map_tab',
                                  image_path: 'assets/img/ic_public_map.webp',
                                  color: 'FFebf1cc',
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) => PublicMap()),
                                    );
                                  }),
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
        )),
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
    var createReport = await Utils.createNewReport('bite', context: context);
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
    var createReport = await Utils.createNewReport('adult', context: context);
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
    var createReport = await Utils.createNewReport('site', context: context);
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
