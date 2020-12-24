import 'package:mosquito_alert_app/models/question.dart';

class Report {
  String version_UUID;
  int version_number;
  String user;
  String report_id;
  String phone_upload_time;
  String creation_time;
  String version_time;
  String type;
  String location_choice;
  double current_location_lon;
  double current_location_lat;
  double selected_location_lon;
  double selected_location_lat;
  String note;
  String package_name;
  int package_version;
  int session;
  List<Photo> photos;
  List<Question> responses;
  String device_manufacturer;
  String device_model;
  String os;
  String os_version;
  String os_language;
  String app_language;
  String displayCity;
  int country;

  Report(
      {this.version_UUID,
      this.version_number,
      this.user,
      this.report_id,
      this.phone_upload_time,
      this.creation_time,
      this.version_time,
      this.type,
      this.location_choice,
      this.current_location_lon,
      this.current_location_lat,
      this.selected_location_lon,
      this.selected_location_lat,
      this.note,
      this.package_name,
      this.package_version,
      this.session,
      this.responses,
      this.device_manufacturer,
      this.device_model,
      this.os,
      this.os_language,
      this.os_version,
      this.app_language,
      this.displayCity,
      this.country});

  Report.fromJson(Map<dynamic, dynamic> json) {
    version_UUID = json['version_UUID'].toString();
    version_number = json['version_number'];
    user = json['user'].toString();
    report_id = json['report_id'].toString();
    phone_upload_time = json['phone_upload_time'].toString();
    creation_time = json['creation_time'].toString();
    version_time = json['version_time'].toString();
    type = json['type'].toString();
    location_choice = json['location_choice'].toString();
    current_location_lon = json['current_location_lon'];
    current_location_lat = json['current_location_lat'];
    selected_location_lon = json['selected_location_lon'];
    selected_location_lat = json['selected_location_lat'];
    note = json['note'].toString();
    package_name = json['package_name'].toString();
    package_version = json['package_version'];
    session = json['session'];

    if (json['photos'] != null) {
      photos = <Photo>[];
      json['photos'].forEach((p) {
        var ph = new Photo.fromJson(p);
        photos.add(ph);
      });
    }

    if (json['responses'] != null) {
      responses = <Question>[];
      json['responses'].forEach((q) {
        responses.add(new Question.fromJson(q));
      });
    }

    device_manufacturer = json['device_manufacturer'];
    device_model = json['device_model'];
    os = json['os'];
    os_version = json['os_version'];
    os_language = json['os_language'];
    app_language = json['app_language'];
    country = json['country'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['version_UUID'] = this.version_UUID;
    data['version_number'] = this.version_number;
    data['user'] = this.user;
    data['report_id'] = this.report_id;
    data['phone_upload_time'] = this.phone_upload_time;
    data['creation_time'] = this.creation_time;
    data['version_time'] = this.version_time;
    data['type'] = this.type;
    data['location_choice'] = this.location_choice;
    data['current_location_lon'] = this.current_location_lon;
    data['current_location_lat'] = this.current_location_lat;
    data['selected_location_lon'] = this.selected_location_lon;
    data['selected_location_lat'] = this.selected_location_lat;
    data['note'] = this.note;
    data['package_name'] = this.package_name;
    data['package_version'] = this.package_version;
    data['session'] = this.session;

    if (this.responses != null) {
      data['responses'] = this.responses.map((r) => r.toJson()).toList();
    }

    if (this.photos != null) {
      data['photos'] = this.photos.map((r) => r.toJson()).toList();
    }

    data['device_manfacturer'] = this.device_manufacturer;
    data['device_model'] = this.device_model;
    data['os'] = this.os;
    data['os_version'] = this.os_version;
    data['os_language'] = this.os_language;
    data['app_language'] = this.app_language;
    return data;
  }
}

class Photo {
  int id;
  String photo;
  String uuid;

  Photo({
    this.id,
    this.photo,
    this.uuid,
  });

  Photo.fromJson(Map<dynamic, dynamic> json) {
    id = json['id'];
    photo = json['photo'];
    uuid = json['uuid'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['photo'] = this.photo;
    data['uuid'] = this.uuid;
    return data;
  }
}
