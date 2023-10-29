class MyNotification {
  int? id;
  String? report_id;
  String? user_id;
  int? expert_id;
  String? expert_html;
  String? expert_comment;
  String? date_comment;
  bool? acknowledged;
  bool? public;
  // NotificationContent notificationContent;

  MyNotification({
    this.id,
    this.report_id,
    this.user_id,
    this.expert_id,
    this.date_comment,
    this.acknowledged,
    // this.notificationContent,
  });

  MyNotification.fromJson(Map<dynamic, dynamic> json) {
    id = json['id'];
    report_id = json['report_id'];
    user_id = json['user_id'];
    expert_id = json['expert_id'];
    expert_html = json['expert_html'];
    expert_comment = json['expert_comment'];
    date_comment = json['date_comment'];
    acknowledged = json['acknowledged'];
    public = json['piblic'];
    // notificationContent =
    //     NotificationContent.fromJson(json['notificationContent']);
  }
}
