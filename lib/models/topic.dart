class Topic {
  int? id;
  String? user;
  int? topic;
  String? topicCode;

  Topic({this.id, this.user, this.topic, this.topicCode});

  Topic.fromJson(Map<String, dynamic> json) {
    print(json);
    id = json['id'];
    user = json['user'];
    topic = json['topic'];
    topicCode = json['topic_code'];
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    data['id'] = id;
    data['user'] = user;
    data['topic'] = topic;
    data['topic_code'] = topicCode;
    return data;
  }
}
