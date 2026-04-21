import 'dart:io';
import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:mosquito_alert/mosquito_alert.dart';
import 'package:mosquito_alert_app/core/converters/uint8list_converter.dart';
import 'package:uuid/uuid.dart';

import 'package:json_annotation/json_annotation.dart';
part 'photo.g.dart';

abstract class BasePhoto {
  BasePhoto();

  Widget buildWidget({required double size});

  factory BasePhoto.fromSimplePhoto(dynamic photo) {
    if (photo is SimplePhoto) {
      return RemotePhoto.fromSimplePhoto(photo);
    } else if (photo is Uint8List) {
      return MemoryPhoto(photo);
    } else if (photo is String) {
      return LocalPhoto(photo);
    } else {
      throw UnsupportedError('Unsupported photo type');
    }
  }
}

abstract class BaseUploadPhoto extends BasePhoto {
  BaseUploadPhoto();

  String get filename => '${Uuid().v4()}.jpg';
  DioMediaType get contentType => DioMediaType('image', 'jpeg');

  Future<MultipartFile> toMultipartFile();

  Map<String, dynamic> toJson();

  factory BaseUploadPhoto.fromJson(Map<String, dynamic> json) {
    switch (json['type']) {
      case 'memory':
        return MemoryPhoto.fromJson(json);
      case 'local':
        return LocalPhoto.fromJson(json);
      default:
        throw Exception('Unknown photo type');
    }
  }
}

@JsonSerializable()
class LocalPhoto extends BaseUploadPhoto {
  static const String type = 'local';

  final String path;
  LocalPhoto(this.path);

  @override
  Future<MultipartFile> toMultipartFile() async {
    return await MultipartFile.fromFile(
      path,
      filename: this.filename,
      contentType: this.contentType,
    );
  }

  factory LocalPhoto.fromJson(Map<String, dynamic> json) =>
      _$LocalPhotoFromJson(json);

  @override
  Map<String, dynamic> toJson() {
    final json = _$LocalPhotoToJson(this);
    json['type'] = type;
    return json;
  }

  @override
  Widget buildWidget({required double size}) {
    return Image.file(File(path), fit: BoxFit.cover, width: size, height: size);
  }
}

@JsonSerializable()
class MemoryPhoto extends BaseUploadPhoto {
  static const String type = 'memory';

  @Uint8ListConverter()
  final Uint8List bytes;

  MemoryPhoto(this.bytes);

  @override
  Future<MultipartFile> toMultipartFile() async {
    return MultipartFile.fromBytes(
      bytes,
      filename: this.filename,
      contentType: this.contentType,
    );
  }

  factory MemoryPhoto.fromJson(Map<String, dynamic> json) =>
      _$MemoryPhotoFromJson(json);

  @override
  Map<String, dynamic> toJson() {
    final json = _$MemoryPhotoToJson(this);
    json['type'] = type;
    return json;
  }

  @override
  Widget buildWidget({required double size}) {
    return Image.memory(bytes, fit: BoxFit.cover, width: size, height: size);
  }
}

class RemotePhoto extends BasePhoto {
  final String url;
  RemotePhoto(this.url);

  factory RemotePhoto.fromSimplePhoto(SimplePhoto photo) {
    return RemotePhoto(photo.url);
  }

  Widget buildWidget({required double size}) {
    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      width: size,
      height: size,
      placeholder: (context, url) => Container(
        color: Colors.white.withValues(alpha: 0.2),
        child: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
      ),
      errorWidget: (context, url, error) => Container(
        color: Colors.white.withValues(alpha: 0.2),
        child: const Center(child: Icon(Icons.hide_image, color: Colors.white)),
      ),
    );
  }
}
