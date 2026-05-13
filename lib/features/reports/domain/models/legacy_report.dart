// This file is only needed to migrate saved reports from 4.1.0. It can be removed in a future release.
import 'package:mosquito_alert/mosquito_alert.dart';

class LegacyReport {
  String version_UUID;
  int? version_number;
  String user;
  String? report_id;
  String? phone_upload_time;
  DateTime creation_time;
  String version_time;
  String type;
  String? location_choice;
  double? current_location_lon;
  double? current_location_lat;
  double? selected_location_lon;
  double? selected_location_lat;
  String? note;
  List<LegacyPhoto>? photos;
  List<LegacyQuestion?>? responses;

  LegacyReport({
    required this.version_UUID,
    this.version_number,
    required this.user,
    this.report_id,
    this.phone_upload_time,
    required this.creation_time,
    required this.version_time,
    required this.type,
    this.location_choice,
    this.current_location_lon,
    this.current_location_lat,
    this.selected_location_lon,
    this.selected_location_lat,
    this.note,
    this.photos,
    this.responses,
  });

  Location get location {
    if (this.location_choice == 'current') {
      return Location(
        (b) => b
          ..point.latitude = current_location_lat ?? 0.0
          ..point.longitude = current_location_lon ?? 0.0
          ..source_ = LocationSource_Enum.auto,
      );
    } else if (this.location_choice == 'selected') {
      return Location(
        (b) => b
          ..point.latitude = selected_location_lat ?? 0.0
          ..point.longitude = selected_location_lon ?? 0.0
          ..source_ = LocationSource_Enum.manual,
      );
    }
    return Location(
      (b) => b
        ..point.latitude = 0.0
        ..point.longitude = 0.0
        ..source_ = LocationSource_Enum.manual,
    );
  }

  LegacyReport.fromJson(Map<String, dynamic> json)
    : version_UUID = json['version_UUID'],
      version_number = json['version_number'],
      user = json['user'],
      report_id = json['report_id'],
      phone_upload_time = json['phone_upload_time'],
      creation_time = DateTime.parse(json['creation_time']),
      version_time = json['version_time'],
      type = json['type'],
      location_choice = json['location_choice'],
      current_location_lon = (json['current_location_lon'] as num?)?.toDouble(),
      current_location_lat = (json['current_location_lat'] as num?)?.toDouble(),
      selected_location_lon = (json['selected_location_lon'] as num?)
          ?.toDouble(),
      selected_location_lat = (json['selected_location_lat'] as num?)
          ?.toDouble(),
      note = json['note'],
      photos = (json['photos'] as List<dynamic>?)
          ?.map((e) => LegacyPhoto.fromJson(e as Map<String, dynamic>))
          .toList(),
      responses = (json['responses'] as List<dynamic>?)
          ?.map(
            (e) => e != null
                ? LegacyQuestion.fromJson(e as Map<String, dynamic>)
                : null,
          )
          .toList();
}

class LegacyPhoto {
  String path;

  LegacyPhoto({required this.path});

  LegacyPhoto.fromJson(Map<String, dynamic> json) : path = json['image'];
}

class LegacyQuestion {
  int question_id;
  String? question;
  int answer_id;
  String? answer;
  String? answer_value;

  LegacyQuestion({
    required this.question_id,
    this.question,
    required this.answer_id,
    this.answer,
    this.answer_value,
  });

  LegacyQuestion.fromJson(Map<String, dynamic> json)
    : question_id = json['question_id'],
      question = json['question'],
      answer_id = json['answer_id'],
      answer = json['answer'],
      answer_value = json['answer_value'];
}
