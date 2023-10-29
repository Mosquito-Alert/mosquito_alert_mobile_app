class Question {
  int? question_id;
  String? question;
  int? answer_id;
  String? answer;
  String? answer_value;

  Question(
      {this.question_id,
      this.question,
      this.answer_id,
      this.answer,
      this.answer_value});

  Question.fromJson(Map<String, dynamic> json) {
    question_id = json['question_id'];
    question = json['question'];
    answer_id = json['answer_id'];
    answer = json['answer'];
    answer_value = json['answer_value'];
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    data['question_id'] = question_id;
    data['question'] = question;
    data['answer_id'] = answer_id;
    data['answer'] = answer;
    data['answer_value'] = answer_value;
    return data;
  }
}
