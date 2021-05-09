class Topic {
  int id;
  String user;
  int topic;
  String topicCode;

  Topic({this.id, this.user, this.topic, this.topicCode});

  Topic.fromJson(Map<String, dynamic> json) {
    print(json);
    id = json['id'];
    user = json['user'];
    topic = json['topic'];
    topicCode = json['topic_code'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['user'] = this.user;
    data['topic'] = this.topic;
    data['topic_code'] = this.topicCode;
    return data;
  }
}