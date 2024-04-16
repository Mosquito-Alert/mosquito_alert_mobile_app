import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mosquito_alert_app/utils/MyLocalizations.dart';
import 'package:mosquito_alert_app/utils/Utils.dart';
import 'package:mosquito_alert_app/utils/style.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';

class AddOtherReportPage extends StatefulWidget {
  final Function addReport;
  final Function setValid;
  final StreamController<double> percent;

  AddOtherReportPage(this.addReport, this.setValid, this.percent);

  @override
  _AddOtherReportPageState createState() => _AddOtherReportPageState();
}

class _AddOtherReportPageState extends State<AddOtherReportPage> {
  final TextEditingController _commentsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (Utils.report!.note != null && Utils.report!.note != '') {
      _commentsController.text = Utils.report!.note!;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            SizedBox(
              height: 35,
            ),
            Container(
              width: double.infinity,
              child: StreamBuilder(
                stream: widget.percent.stream,
                initialData: 0.0,
                builder: (context, AsyncSnapshot<double> snapshot) {
                  return LinearPercentIndicator(
                    lineHeight: 15.0,
                    percent: snapshot.data!,
                    animateFromLastPercent: true,
                    animation: true,
                    backgroundColor: Colors.grey.withOpacity(0.3),
                    progressColor: Style.colorPrimary,
                  );
                },
              ),
            ),
            SizedBox(
              height: 20,
            ),
            Style.title(MyLocalizations.of(context, 'add_comments_question')),
            SizedBox(
              height: 12,
            ),
            Style.textField(MyLocalizations.of(context, 'comments_txt'),
                _commentsController, context,
                keyboardType: TextInputType.multiline, maxLines: 4, expands: false, handleChange: (text) {
              Utils.report!.note = text;
            }),
            Style.bottomOffset,
          ],
        ),
      ),
    );
  }
}
