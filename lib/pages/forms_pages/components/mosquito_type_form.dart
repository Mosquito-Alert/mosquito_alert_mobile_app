import 'package:flutter/material.dart';
import 'package:mosquito_alert_app/models/question.dart';
import 'package:mosquito_alert_app/pages/forms_pages/components/image_button_widget.dart';
import 'package:mosquito_alert_app/utils/MyLocalizations.dart';
import 'package:mosquito_alert_app/utils/Utils.dart';
import 'package:mosquito_alert_app/utils/style.dart';

class MosquitoTypeForm extends StatefulWidget {
  final Function setSkip3;
  final Map displayQuestion;
  final Function setValid, showCamera, nextPage, skipReport;

  MosquitoTypeForm(
    this.setSkip3,
    this.displayQuestion,
    this.setValid,
    this.showCamera,
    this.nextPage,
    this.skipReport,
  );
  @override
  _MosquitoTypeFormState createState() => _MosquitoTypeFormState();
}

class _MosquitoTypeFormState extends State<MosquitoTypeForm> {
  Question question = Question();

  @override
  void initState() {
    super.initState();
    question = new Question(
      question: widget.displayQuestion['question']['text'],
      question_id: widget.displayQuestion['question']['id'],
    );
    if (Utils.report != null) {
      int index = Utils.report.responses.indexWhere(
          (q) => q.question_id == widget.displayQuestion['question']['id']);
      if (index != -1) {
        question.answer = Utils.report.responses[index].answer;
        question.answer_id = Utils.report.responses[index].answer_id;
        widget.setValid(true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              margin: EdgeInsets.symmetric(horizontal: 15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  SizedBox(
                    height: 35,
                  ),
                  Style.title(MyLocalizations.of(
                      context, widget.displayQuestion['question']['text'])),
                  Container(
                    margin: EdgeInsets.only(top: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        GridView.builder(
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2, crossAxisSpacing: 10),
                            shrinkWrap: true,
                            physics: NeverScrollableScrollPhysics(),
                            itemCount: widget.displayQuestion['answers'].length,
                            itemBuilder: (ctx, index) {
                              return GestureDetector(
                                  onTap: () {
                                    onSelect(
                                        widget.displayQuestion['answers'][index]
                                            ['text'],
                                        widget.displayQuestion['answers'][index]
                                            ['id']);

                                    widget.displayQuestion['answers'][index]
                                                ['id'] ==
                                            63
                                        ? widget.skipReport(true)
                                        : widget.nextPage();

                                    widget.displayQuestion['answers'][index]
                                                ['id'] ==
                                            61
                                        ? widget.setSkip3(true)
                                        : widget.setSkip3(false);
                                  },
                                  // child: ImageQuestionOption(
                                  //   question.answer_id ==
                                  //           (widget.displayQuestion['answers'][index]
                                  //               ['id'])
                                  //       ? true
                                  //       : false,
                                  //   MyLocalizations.of(
                                  //       context,
                                  //       widget.displayQuestion['answers'][index]
                                  //           ['text']),
                                  //   widget.displayQuestion['answers'][index]['img'],
                                  //   disabled: question.answer_id != null &&
                                  //       widget.displayQuestion['answers'][index]
                                  //               ['id'] !=
                                  //           question.answer_id,
                                  // ),
                                  child: CustomImageButton(
                                    selected: question.answer_id ==
                                            (widget.displayQuestion['answers']
                                                [index]['id'])
                                        ? true
                                        : false,
                                    title: MyLocalizations.of(
                                        context,
                                        widget.displayQuestion['answers'][index]
                                            ['text']),
                                    img: widget.displayQuestion['answers']
                                        [index]['img'],
                                  ));
                            })
                      ],
                    ),
                  ),
                  // Padding(
                  //   padding: const EdgeInsets.symmetric(vertical: 10.0),
                  //   child: Divider(),
                  // ),
                  // AddPhotoButton(),
                  // Style.bottomOffset,
                  // Flexible(
                  //   child: Container(
                  //     // margin: EdgeInsets.only(top: 20),
                  //     child: Image.asset(
                  //       'assets/img/ic_bottom_main.png',
                  //       width: double.infinity,
                  //       fit: BoxFit.fitWidth,
                  //       alignment: Alignment.bottomCenter,
                  //     ),
                  //   ),
                  // ),
                ],
              ),
            ),

            //TODO: fix image position
            Container(
              // margin: EdgeInsets.only(top: 20),
              alignment: Alignment.bottomCenter,
              child: Image.asset(
                'assets/img/ic_bottom_main.png',
                width: double.infinity,
                fit: BoxFit.fitWidth,
                alignment: Alignment.bottomCenter,
              ),
            ),
          ],
        ),
      ),
    );
  }

  onSelect(answer, answerId) {
    setState(() {
      question.answer = answer;
      question.answer_id = answerId;
    });
    // widget.setValid(true);

    if (question.answer_id != 61) {
      Utils.report.responses.removeWhere((element) => element.question_id == 7);
    }
    Utils.addResponse(question);
  }
}
