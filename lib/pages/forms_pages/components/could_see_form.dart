import 'package:flutter/material.dart';
import 'package:mosquito_alert_app/pages/forms_pages/components/small_question_option_widget.dart';
import 'package:mosquito_alert_app/utils/MyLocalizations.dart';
import 'package:mosquito_alert_app/utils/style.dart';

class CouldSeeForm extends StatefulWidget {
  final Function addReport;
  final Map displayQuestion;
  final Function setValid;
  final Function? addOtherReport;
  final Function nextPage;

  CouldSeeForm(this.addReport, this.displayQuestion, this.setValid, this.nextPage,
      {this.addOtherReport});
  @override
  _CouldSeeFormState createState() => _CouldSeeFormState();
}

class _CouldSeeFormState extends State<CouldSeeForm> {
  String? selected;

  @override
  void initState() {
    super.initState();
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
            Style.title(MyLocalizations.of(context, widget.displayQuestion['question']['text'])),
            SizedBox(
              height: 30,
            ),
            GridView.builder(
              physics: NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: widget.displayQuestion['answers'].length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 5 / 2,
                // crossAxisSpacing: 10,
              ),
              itemBuilder: (context, index) {
                String? text =
                    widget.displayQuestion['answers'][index]['text'];
                int? id = widget.displayQuestion['answers'][index]['id'];
                return Container(
                  padding: EdgeInsets.all(5),
                  child: GestureDetector(
                      onTap: () {
                        setState(() {
                          selected = text;
                        });
                        id == 82
                            ? widget.addReport(true)
                            : widget.addReport(false);
                        // widget.setValid(true);
                        widget.nextPage();
                      },
                      child: SmallQuestionOption(
                        text,
                        selected: selected == text,
                      )),
                );
              },
            ),
            Style.bottomOffset,
          ],
        ),
      ),
    );
  }
}
