class Session {
  int? id;
  int? session_ID;
  String? user;
  String? session_start_time;
  String? session_end_time;

  Session({
    this.id,
    this.session_ID,
    this.user,
    this.session_start_time,
    this.session_end_time,
  });

  Session.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    session_ID = json['session_ID'];
    user = json['user'];
    session_start_time = json['session_start_time'];
    session_end_time = json['session_end_time'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = Map<String, dynamic>();
    data['id'] = id;
    data['session_ID'] = session_ID;
    data['user'] = user;
    data['session_start_time'] = session_start_time;
    data['session_end_time'] = session_end_time;
    return data;
  }
}
