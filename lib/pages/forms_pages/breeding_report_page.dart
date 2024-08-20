import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mosquito_alert_app/models/report.dart';
import 'package:mosquito_alert_app/pages/forms_pages/adult_report_page.dart';
import 'package:mosquito_alert_app/pages/forms_pages/biting_report_page.dart';
import 'package:mosquito_alert_app/pages/forms_pages/components/add_other_report_form.dart';
import 'package:mosquito_alert_app/pages/forms_pages/components/add_photo_button_widget.dart';
import 'package:mosquito_alert_app/pages/forms_pages/components/biting_location_form.dart';
import 'package:mosquito_alert_app/pages/forms_pages/components/questions_breeding_form.dart';
import 'package:mosquito_alert_app/utils/MyLocalizations.dart';
import 'package:mosquito_alert_app/utils/Utils.dart';
import 'package:mosquito_alert_app/utils/style.dart';

class BreedingReportPage extends StatefulWidget {
  final Report? editReport;
  final Function? loadData;

  BreedingReportPage({this.editReport, this.loadData});

  @override
  _BreedingReportPageState createState() => _BreedingReportPageState();
}

class _BreedingReportPageState extends State<BreedingReportPage> {
  PageController? _pagesController;
  late List<Widget> _formsRepot, _initialFormsReport;
  StreamController<bool> loadingStream = StreamController<bool>.broadcast();
  StreamController<bool> validStream = StreamController<bool>.broadcast();
  StreamController<double> percentStream =
      StreamController<double>.broadcast();

  List<Map> displayQuestions = [
    {
      'question': {'id': 12, 'text': 'question_12'},
      'answers': [
        {
          'img': 'assets/img/ic_imbornal.png',
          'id': 121,
          'text': 'question_12_answer_121'
        },
        {
          'img': 'assets/img/ic_other_site.png',
          'id': 122,
          'text': 'question_12_answer_122'
        }
      ]
    },
    {
      'question': {'id': 10, 'text': 'question_10'},
      'answers': [
        {'id': 101, 'text': 'question_10_answer_101'},
        {'id': 81, 'text': 'question_10_answer_102'}
      ]
    },
    {
      'question': {'id': 17, 'text': 'question_17'},
      'answers': [
        {'id': 101, 'text': 'question_10_answer_101'},
        {'id': 81, 'text': 'question_10_answer_102'}
      ]
    },
    {
      'question': {'id': 16, 'text': 'question_16'},
    },
  ];

  bool showCamera = false;
  bool touched = false;
  String? otherReport;
  late Report toEditReport;

  double index = 1.0;
  double displayContinue = 1.0;
  bool _atLeastOnePhotoAttached = false;

  void _initializeReport() async {
    if (widget.editReport != null) {
      toEditReport = await Report.fromJsonAsync(widget.editReport!.toJson());
      Utils.setEditReport(toEditReport);
    }
  }

  @override
  void initState() {
    super.initState();
    _initializeReport();
    _pagesController = PageController();

    _formsRepot = [
      QuestionsBreedingForm(
        displayQuestions.elementAt(0),
        setValid,
        true,
        goNextPage,
        'assets/img/bottoms/breeding_1.png'),
      AddPhotoButton(true, true, _checkAtLeastOnePhotoAttached, null, null),
      QuestionsBreedingForm(
        displayQuestions.elementAt(1),
        setValid,
        false,
        goNextPage,
        'assets/img/bottoms/breeding_2.png',
        skipPage3: skipPage3,
      ),
      QuestionsBreedingForm(displayQuestions.elementAt(2), setValid, false,
          goNextPage, 'assets/img/bottoms/breeding_3.png'),
      BitingLocationForm(
          setValid, displayQuestions.elementAt(3)['question']['text']),
      AddOtherReportPage(_createReport, setValid, percentStream),
    ];
    _initialFormsReport = List.from(_formsRepot);
  }

  void skipPage3(skip) {
    var list = List<Widget>.from(_initialFormsReport);
    if (skip) {
      list.removeAt(3);
      setState(() {
        _formsRepot = list;
        displayContinue = 2.0;
      });
    } else {
      setState(() {
        _formsRepot = List.from(_initialFormsReport);
        displayContinue = 3.0;
      });
    }
  }

  void _checkAtLeastOnePhotoAttached(){
    setState(() {
      _atLeastOnePhotoAttached = true;
    });
  }

  void addOtherReport(String? reportType) {
    setState(() {
      otherReport = reportType;
    });
  }

  void setShowCamera(data) {
    setState(() {
      showCamera = data;
    });
  }

  void setValid(isValid) {
    validStream.add(isValid);
  }

  void goNextPage() {
    _pagesController!
        .nextPage(duration: Duration(microseconds: 300), curve: Curves.ease)
        .then((value) => setValid(widget.editReport != null));
    setState(() {
      index = _pagesController!.page! + 1;
    });
  }

  void navigateOtherReport() async {
    switch (otherReport) {
      case 'bite':
        Utils.addOtherReport('bite');
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => BitingReportPage()),
        );
        break;
      case 'adult':
        Utils.addOtherReport('adult');
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => AdultReportPage()),
        );
        break;
      default:
        break;
    }
  }

  void _createReport() async {
    setState(() {
      percentStream.add(0.8);
    });
    loadingStream.add(true);
    var res = await Utils.createReport();

    if (widget.editReport != null) {
      widget.loadData!();
    }
    if (!res!) {
      _showAlertKo();
    } else {
      _showAlertOk();
      setState(() {
        percentStream.add(1.0);
      });
    }
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
                    _onWillPop();
                  } else {
                    _pagesController!
                        .previousPage(
                            duration: Duration(microseconds: 300),
                            curve: Curves.ease)
                        .then((value) => addOtherReport(null));
                  }
                  setState(() {
                    index = currentPage! - 1;
                  });
                },
              ),
              title: Style.title(
                  MyLocalizations.of(context, 'breeding_report_title'),
                  fontSize: 16),
            ),
            body: Stack(
              alignment: Alignment.bottomCenter,
              children: <Widget>[
                PageView(
                  controller: _pagesController,
                  physics: NeverScrollableScrollPhysics(),
                  children: _formsRepot,
                ),
                index <= displayContinue
                  ? index == 1 && _atLeastOnePhotoAttached ?
                    Container(
                      width: double.infinity,
                      height: 54,
                      margin: EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                      child: Style.button(
                        MyLocalizations.of(context, 'continue_txt'), () {
                          goNextPage();
                        }
                      )
                    ) : Container()
                    : index != _formsRepot.length.toDouble() - 1
                        ? SafeArea(
                            child: Align(
                            alignment: Alignment.bottomCenter,
                            child: StreamBuilder<bool>(
                                stream: validStream.stream,
                                initialData: false,
                                builder: (BuildContext ctxt, AsyncSnapshot<bool> snapshot) {
                                  return snapshot.data!
                                      ? Container(
                                          width: double.infinity,
                                          height: 54,
                                          margin: EdgeInsets.symmetric(
                                            vertical: 6,
                                            horizontal: 12),
                                          child: Style.button(
                                            MyLocalizations.of(context, 'continue_txt'), () {
                                              var currentPage =_pagesController!.page;

                                              if (currentPage == 0.0) {
                                                goNextPage();
                                              } else if (currentPage == 4.0) {
                                                if (otherReport == 'adult' || otherReport == 'bite') {
                                                  navigateOtherReport();
                                                }
                                              } else {
                                                goNextPage();
                                              }
                                            }
                                          ),
                                        )
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
                            child: Container(
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

  void _showAlertOk() {
    loadingStream.add(false);
    Utils.showAlert(
      MyLocalizations.of(context, 'app_name'),
      widget.editReport == null
          ? MyLocalizations.of(context, 'save_report_ok_txt')
          : MyLocalizations.of(context, 'edited_report_ok_txt'),
      context,
      onPressed: () {
        Navigator.pop(context);
        Utils.resetReport();
        if (widget.editReport != null) {
          Navigator.pop(context);
        } else {
          Navigator.of(context).popUntil((r) => r.isFirst);
        }

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
        Utils.resetReport();
        if (widget.editReport != null) {
          Navigator.pop(context);
        } else {
          Navigator.of(context).popUntil((r) => r.isFirst);
        }
      },
      barrierDismissible: false,
    );
  }

  void _onWillPop() {
    if (Utils.report!.responses!.isNotEmpty) {
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
