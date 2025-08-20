import 'dart:async';

import 'package:built_collection/built_collection.dart';
import 'package:dio/dio.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:mosquito_alert/mosquito_alert.dart';
import 'package:mosquito_alert_app/models/report.dart';
import 'package:mosquito_alert_app/pages/forms_pages/biting_report_page.dart';
import 'package:mosquito_alert_app/pages/forms_pages/components/add_other_report_form.dart';
import 'package:mosquito_alert_app/pages/forms_pages/components/add_photo_button_widget.dart';
import 'package:mosquito_alert_app/pages/forms_pages/components/could_see_form.dart';
import 'package:mosquito_alert_app/pages/forms_pages/components/questions_breeding_form.dart';
import 'package:mosquito_alert_app/pages/settings_pages/campaign_tutorial_page.dart';
import 'package:mosquito_alert_app/utils/MyLocalizations.dart';
import 'package:mosquito_alert_app/utils/Utils.dart';
import 'package:mosquito_alert_app/utils/style.dart';
import 'package:provider/provider.dart';

import 'components/location_form.dart';

class AdultReportPage extends StatefulWidget {
  @override
  _AdultReportPageState createState() => _AdultReportPageState();
}

class _AdultReportPageState extends State<AdultReportPage> {
  PageController? _pagesController;
  List<Widget>? _formsReport;
  List<Widget>? _initialformsReport;
  StreamController<bool> loadingStream = StreamController<bool>.broadcast();
  StreamController<bool> validStream = StreamController<bool>.broadcast();
  StreamController<bool> skipParts = StreamController<bool>.broadcast();
  StreamController<double> percentStream = StreamController<double>.broadcast();
  double? index;
  late CampaignsApi campaignsApi;

  // Define the events to log
  final List<Map<String, dynamic>> _pageEvents = [
    {
      'name': 'report_add_photo',
      'parameters': {'type': 'adult'}
    },
    {
      'name': 'report_add_location',
      'parameters': {'type': 'adult'}
    },
    {
      'name': 'report_add_environment',
      'parameters': {'type': 'adult'}
    },
    {
      'name': 'report_add_bitten',
      'parameters': {'type': 'adult'}
    },
    {
      'name': 'report_add_note',
      'parameters': {'type': 'adult'}
    }
  ];

  List<Map> displayQuestions = [
    {
      'question': {'id': 13, 'text': 'question_13'},
      'answers': [
        {'id': 131, 'text': 'question_13_answer_131'},
        {'id': 132, 'text': 'question_13_answer_132'},
        {'id': 133, 'text': 'question_13_answer_133'},
      ]
    },
    {
      'question': {'id': 8, 'text': 'question_8'},
      'answers': [
        {'id': 82, 'text': 'question_8_answer_82'},
        {'id': 81, 'text': 'question_8_answer_81'},
      ]
    },
  ];

  bool addBiting = false;
  bool showCamera = false;
  String? otherReport;
  late Report toEditReport;
  bool _atLeastOnePhotoAttached = false;

  @override
  void initState() {
    super.initState();
    MosquitoAlert apiClient =
        Provider.of<MosquitoAlert>(context, listen: false);
    campaignsApi = apiClient.getCampaignsApi();
    _logFirebaseAnalytics();
    _pagesController = PageController();
    index = 0.0;
    _initialformsReport = [
      AddPhotoButton(true, true, _checkAtLeastOnePhotoAttached,
          'ensure_single_mosquito_photos', 'one_mosquito_reminder_badge'),
      LocationForm(setValid, displayQuestions.elementAt(0)['question']['text']),
      QuestionsBreedingForm(
          displayQuestions.elementAt(0), setValid, false, null, ''),
      CouldSeeForm(
          addBitingReport, displayQuestions.elementAt(1), setValid, goNextPage),
      AddOtherReportPage(_createReport, setValid, percentStream),
    ];

    _formsReport = _initialformsReport;
  }

  Future<void> _logFirebaseAnalytics() async {
    await FirebaseAnalytics.instance
        .logEvent(name: 'start_report', parameters: {'type': 'adult'});
  }

  void _onPageChanged(int index) async {
    // Check if the index is valid and log the event
    if (index >= 0 && index < _pageEvents.length) {
      final event = _pageEvents[index];
      await FirebaseAnalytics.instance.logEvent(
        name: event['name'],
        parameters: event['parameters'],
      );
    }
  }

  void setShowCamera(data) {
    setState(() {
      showCamera = data;
    });
  }

  void addBitingReport(addReport) {
    setState(() {
      addBiting = addReport;
    });
  }

  void addOtherReport(String? reportType) {
    setState(() {
      otherReport = reportType;
    });
  }

  void setValid(isValid) {
    validStream.add(isValid);
  }

  void goNextPage() {
    if (addBiting) {
      Utils.addOtherReport('bite', context);
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => BitingReportPage()),
      );
    } else {
      _pagesController!
          .nextPage(duration: Duration(microseconds: 300), curve: Curves.ease);
      setState(() {
        index = _pagesController!.page! + 1;
      });
    }
  }

  void _createReport() async {
    setState(() {
      percentStream.add(0.8);
    });
    loadingStream.add(true);
    await FirebaseAnalytics.instance
        .logEvent(name: 'submit_report', parameters: {'type': 'adult'});
    var res = await Utils.createReport(); // TODO: Replace with issue #400

    if (!res!) {
      _showAlertKo();
      return;
    }

    if (Utils.savedAdultReport == null) {
      return showSuccess();
    }

    Campaign? activeCampaign = null;
    try {
      Response<PaginatedCampaignList> response = await campaignsApi.list(
        countryId: Utils.savedAdultReport!.country,
        isActive: true,
        orderBy: BuiltList<String>.of(["-start_date"]),
        pageSize: 1,
      );
      activeCampaign = response.data!.results!.first;
    } catch (e, stackTrace) {
      print('Failed to fetch campaigns: $e');
      debugPrintStack(stackTrace: stackTrace);
    }

    showSuccess();

    if (activeCampaign != null) {
      await Utils.showAlertCampaign(
        context,
        (ctx) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => CampaignTutorialPage(fromReport: true),
            ),
          );
        },
      );
    }
  }

  void showSuccess() {
    _showAlertOk();
    Utils.resetReport();
    setState(() {
      percentStream.add(1.0);
    });
  }

  @override
  void dispose() {
    _pagesController!.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        _onWillPop();
        return false;
      },
      child: Stack(
        children: <Widget>[
          Scaffold(
            appBar: AppBar(
              backgroundColor: Colors.white,
              centerTitle: true,
              leading: IconButton(
                icon: Style.iconBack,
                onPressed: () {
                  var currentPage = _pagesController!.page;

                  if (currentPage == 0.0) {
                    setState(() {
                      index = currentPage! - 1;
                    });
                    _onWillPop();
                  } else {
                    if (currentPage == 2.0 &&
                        !Utils.report!.responses!
                            .any((element) => element!.answer_id == 61)) {
                      setState(() {
                        index = 0;
                      });
                      _pagesController!
                          .animateToPage(0,
                              duration: Duration(microseconds: 300),
                              curve: Curves.ease)
                          .then((value) {
                        setValid(true);
                        addOtherReport(null);
                      });
                    } else if (currentPage == 4.0) {
                      addBitingReport(false);
                      _pagesController!.previousPage(
                          duration: Duration(microseconds: 300),
                          curve: Curves.ease);
                      setState(() {
                        index = currentPage! - 1;
                      });
                    } else {
                      setState(() {
                        index = currentPage! - 1;
                      });
                      _pagesController!
                          .previousPage(
                              duration: Duration(microseconds: 300),
                              curve: Curves.ease)
                          .then((value) {
                        setValid(true);
                        addOtherReport(null);
                      });
                    }
                  }
                },
              ),
              title: Style.title(
                  MyLocalizations.of(context, 'adult_report_title'),
                  fontSize: 16),
            ),
            body: Stack(
              alignment: Alignment.bottomCenter,
              children: <Widget>[
                PageView(
                  controller: _pagesController,
                  onPageChanged: _onPageChanged,
                  physics: NeverScrollableScrollPhysics(),
                  children: _formsReport!,
                ),
                index! < 1.0
                    ? continueButtonPhotos()
                    : index != _formsReport!.length.toDouble() - 1
                        ? SafeArea(
                            child: Align(
                            alignment: Alignment.bottomCenter,
                            child: StreamBuilder<bool>(
                                stream: validStream.stream,
                                initialData: false,
                                builder: (BuildContext ctxt,
                                    AsyncSnapshot<bool> snapshot) {
                                  return snapshot.data!
                                      ? continueButton(index)
                                      : Container(
                                          width: double.infinity,
                                          height: 54,
                                          margin: EdgeInsets.symmetric(
                                              vertical: 6, horizontal: 12),
                                          child: Style.button(
                                              MyLocalizations.of(
                                                  context, 'continue_txt'),
                                              null),
                                        );
                                }),
                          ))
                        : SafeArea(
                            child: _formsReport!.length == 2
                                ? Container(
                                    width: double.infinity,
                                    height: 54,
                                    margin: EdgeInsets.symmetric(
                                        vertical: 6, horizontal: 12),
                                    child: Style.button(
                                      MyLocalizations.of(
                                          context, 'understand_txt'),
                                      () {
                                        Navigator.pop(context);
                                        Utils.resetReport();
                                        Utils.imagePath = null;
                                      },
                                    ),
                                  )
                                : Container(
                                    width: double.infinity,
                                    height: 54,
                                    margin: EdgeInsets.symmetric(
                                        vertical: 6, horizontal: 12),
                                    child: Style.button(
                                      MyLocalizations.of(context, 'send_data'),
                                      () {
                                        _createReport();
                                      },
                                    ),
                                  ),
                          ),
              ],
            ),
          ),
          StreamBuilder<bool>(
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
          )
        ],
      ),
    );
  }

  void _checkAtLeastOnePhotoAttached() {
    setState(() {
      _atLeastOnePhotoAttached = true;
    });
  }

  Widget continueButtonPhotos() {
    if (!_atLeastOnePhotoAttached) {
      return Container();
    }

    return Container(
        width: double.infinity,
        height: 54,
        margin: EdgeInsets.symmetric(vertical: 6, horizontal: 12),
        child: Style.button(MyLocalizations.of(context, 'continue_txt'), () {
          goNextPage();
        }));
  }

  Widget continueButton(double? index) {
    return Container(
        width: double.infinity,
        height: 54,
        margin: EdgeInsets.symmetric(vertical: 6, horizontal: 12),
        child: Style.button(MyLocalizations.of(context, 'continue_txt'), () {
          var currentPage = _pagesController!.page;

          if (currentPage == 3.0 && addBiting) {
            Utils.addOtherReport('bite', context);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => BitingReportPage()),
            );
          } else {
            setState(() {
              index = currentPage! + 1;
            });

            _pagesController!.nextPage(
                duration: Duration(microseconds: 300), curve: Curves.ease);
          }
        }));
  }

  void _showAlertOk() {
    loadingStream.add(false);

    Utils.showAlert(
      MyLocalizations.of(context, 'app_name'),
      MyLocalizations.of(context, 'save_report_ok_txt'),
      context,
      onPressed: () {
        Navigator.pop(context);
        Navigator.of(context).popUntil((r) => r.isFirst);
        Utils.resetReport();
        Utils.requestInAppReview();
      },
      barrierDismissible: false,
    );
  }

  void _showAlertKo() {
    loadingStream.add(false);
    Utils.showAlert(
      MyLocalizations.of(context, 'app_name'),
      MyLocalizations.of(context, 'save_report_ko_txt'),
      context,
      onPressed: () {
        Navigator.pop(context);
        Navigator.of(context).popUntil((r) => r.isFirst);
        Utils.resetReport();
      },
      barrierDismissible: false,
    );
  }

  void _onWillPop() {
    var responses = Utils.report?.responses ?? [];
    if (responses.isNotEmpty) {
      Utils.showAlertYesNo(MyLocalizations.of(context, 'app_name'),
          MyLocalizations.of(context, 'close_report_no_save_txt'), () {
        if (Utils.reportsList != null && Utils.reportsList!.isNotEmpty) {
          Utils.deleteLastReport();
        } else {
          Utils.resetReport();
          Utils.imagePath = null;
        }
        Navigator.pop(context);
      }, context);
    } else {
      Navigator.pop(context);
    }
  }
}
