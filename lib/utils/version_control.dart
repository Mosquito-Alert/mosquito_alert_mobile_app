//
//  versioncontrol.dart
//
//  Created by Alex Tarragó on 04/02/2020.
//  Copyright © 2020 Dribba GmbH. All rights reserved.
//

import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:package_info/package_info.dart';
import 'package:url_launcher/url_launcher.dart';

enum ComparisonMode {
  none,
  soft,
  hard,
}

class Version {
  String appName;
  int version;
  ComparisonMode comparisonMode;
  String minSystemVersion;
  String title;
  String message;
  String okButtonTitle;
  String cancelButtonTitle;
  String actionURL;

  bool isComplete() {
    return appName != null &&
        version != null &&
        comparisonMode != null &&
        minSystemVersion != null &&
        title != null &&
        message != null &&
        okButtonTitle != null &&
        cancelButtonTitle != null &&
        actionURL != null;
  }
}

class VersionControl {
  String packageApiKey;
  String packageLanguageCode = 'es';
  BuildContext packageContext;

  VersionControl._internal();

  static final VersionControl _singleton = new VersionControl._internal();

  factory VersionControl() {
    return _singleton;
  }

  static VersionControl getInstance() {
    return new VersionControl();
  }

  Future<bool> checkVersion(BuildContext context) async {
    if (packageApiKey == null) {
      return true;
    }
    if (context == null) {
      return true;
    }
    packageContext = context;

    try {
      var headers = {
        'Content-Type': 'application/json',
        'x-api-key': 'hCyBylqVei3oTgYtGuz3rfF4GtOc'
      };

      final response = await http
          .post(Uri.parse('https://dribbot.drib.ba/api/public/v1/app/check'),
          headers: headers,
          body: json.encode({
            'appKey': packageApiKey,
          }))
          .timeout(const Duration(seconds: 3));

      if (response.statusCode == 418) {
        return true;
      }
      if (response.statusCode != 200) {
        return true;
      }

      var result =
      VersionData.fromJson(json.decode(utf8.decode(response.bodyBytes)));
      if (result == null) {
        return true;
      }
      Version v = processData(result);

      if (v == null) {
        return true;
      }

      return compare(v);
    } catch (c) {
      return true;
    }
  }

  Version processData(VersionData data) {
    Version remoteVersion;
    CurrentVersionConfig versionConfig;

    if (Platform.isIOS) {
      for (CurrentVersionConfig v in data._currentVersionConfig) {
        if (v._platform == 'ios') {
          versionConfig = v;
        }
      }
    } else {
      for (CurrentVersionConfig v in data._currentVersionConfig) {
        if (v._platform == 'android') {
          versionConfig = v;
        }
      }
    }
    if (versionConfig == null) {
      return null;
    }

    remoteVersion = Version();
    remoteVersion.appName = data._name;
    remoteVersion.version = versionConfig._buildVersion;
    remoteVersion.minSystemVersion = versionConfig._minSystemVersion;
    remoteVersion.actionURL = versionConfig._okButtonActionURL;

    if (versionConfig._comparisonMode == 0) {
      remoteVersion.comparisonMode = ComparisonMode.none;
    } else if (versionConfig._comparisonMode == 1) {
      remoteVersion.comparisonMode = ComparisonMode.soft;
    } else if (versionConfig._comparisonMode == 2) {
      remoteVersion.comparisonMode = ComparisonMode.hard;
    } else {
      return null;
    }

    if (packageLanguageCode == 'ca') {
      remoteVersion.title = versionConfig._title._cat;
      remoteVersion.message = versionConfig._message._cat;
      remoteVersion.okButtonTitle = versionConfig._okButtonTitle._cat;
      remoteVersion.cancelButtonTitle = versionConfig._cancelButtonTitle._cat;
    } else if (packageLanguageCode == 'es') {
      remoteVersion.title = versionConfig._title._es;
      remoteVersion.message = versionConfig._message._es;
      remoteVersion.okButtonTitle = versionConfig._okButtonTitle._es;
      remoteVersion.cancelButtonTitle = versionConfig._cancelButtonTitle._es;
    } else if (packageLanguageCode == 'en') {
      remoteVersion.title = versionConfig._title._en;
      remoteVersion.message = versionConfig._message._en;
      remoteVersion.okButtonTitle = versionConfig._okButtonTitle._en;
      remoteVersion.cancelButtonTitle = versionConfig._cancelButtonTitle._en;
    } else {
      return null;
    }

    if (remoteVersion.isComplete()) {
      return remoteVersion;
    }
    return null;
  }

  Future<bool> compare(Version version) async {
    var packageInfo = await PackageInfo.fromPlatform();

    int currentVersion = int.parse(packageInfo.buildNumber);
    if (currentVersion == null) {
      return true;
    }

    int storeVersion = version.version;
    if (storeVersion > currentVersion &&
        version.comparisonMode != ComparisonMode.none) {
      return await showAlertWith(
          version.title,
          version.message,
          version.okButtonTitle,
          version.cancelButtonTitle,
          version.actionURL,
          version.comparisonMode);
    }
    return true;
  }

  Future showAlertWith(String title, String message, String okButtonTitle,
      String cancelButtonTitle, String actionURL, ComparisonMode updateMode) {
    if (Platform.isAndroid) {
      return showDialog(
        context: packageContext,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(title),
            content: SingleChildScrollView(
              child: ListBody(
                children: <Widget>[
                  Text(message),
                ],
              ),
            ),
            actions: <Widget>[
              FlatButton(
                child: Text(okButtonTitle),
                onPressed: () async {
                  if (updateMode == ComparisonMode.soft) {
                    _launchURL(actionURL);
                    Navigator.of(context).pop(true);
                  } else {
                    await _launchURL(actionURL);
                    SystemNavigator.pop();
                  }
                },
              ),
              updateMode == ComparisonMode.soft
                  ? FlatButton(
                child: Text(cancelButtonTitle),
                onPressed: () {
                  Navigator.of(context).pop(true);
                },
              )
                  : Container()
            ],
          );
        },
      );
    } else {
      return updateMode == ComparisonMode.soft
          ? showDialog(
        barrierDismissible: false,
        context: packageContext, //
        builder: (BuildContext context) {
          return CupertinoAlertDialog(
            title: new Text(title),
            content: Column(
              children: <Widget>[
                SizedBox(
                  height: 4,
                ),
                Text(
                  message,
                )
              ],
            ),
            actions: <Widget>[
              CupertinoDialogAction(
                isDefaultAction: true,
                child: Text(okButtonTitle),
                onPressed: () {
                  _launchURL(actionURL);
                  Navigator.of(context).pop(true);
                },
              ),
              CupertinoDialogAction(
                isDefaultAction: true,
                child: Text(cancelButtonTitle),
                onPressed: () {
                  Navigator.of(context).pop(true);
                },
              )
            ],
          );
        },
      )
          : showDialog(
        barrierDismissible: false,
        context: packageContext, //
        builder: (BuildContext context) {
          return CupertinoAlertDialog(
            title: new Text(title),
            content: Column(
              children: <Widget>[
                SizedBox(
                  height: 4,
                ),
                Text(
                  message,
                )
              ],
            ),
            actions: <Widget>[
              CupertinoDialogAction(
                isDefaultAction: true,
                child: Text(okButtonTitle),
                onPressed: () async {
                  await _launchURL(actionURL);
                  await Future.delayed(const Duration(seconds: 1), () {});
                  exit(0);
                },
              ),
            ],
          );
        },
      );
    }
  }

  _launchURL(String url) async {
    if (await canLaunch(url)) {
      await launch(url, forceSafariVC: false);
    } else {
      throw 'Could not launch $url';
    }
  }
}

class VersionData {
  String _id;
  String _name;
  List<CurrentVersionConfig> _currentVersionConfig;
  String _apiKey;
  String _createdAt;
  String _updatedAt;

  VersionData(
      {String id,
        String name,
        List<CurrentVersionConfig> currentVersionConfig,
        String apiKey,
        String createdAt,
        String updatedAt}) {
    this._id = id;
    this._name = name;
    this._currentVersionConfig = currentVersionConfig;
    this._apiKey = apiKey;
    this._createdAt = createdAt;
    this._updatedAt = updatedAt;
  }

  String get id => _id;

  set id(String id) => _id = id;

  String get name => _name;

  set name(String name) => _name = name;

  List<CurrentVersionConfig> get currentVersionConfig => _currentVersionConfig;

  set currentVersionConfig(List<CurrentVersionConfig> currentVersionConfig) =>
      _currentVersionConfig = currentVersionConfig;

  String get apiKey => _apiKey;

  set apiKey(String apiKey) => _apiKey = apiKey;

  String get createdAt => _createdAt;

  set createdAt(String createdAt) => _createdAt = createdAt;

  String get updatedAt => _updatedAt;

  set updatedAt(String updatedAt) => _updatedAt = updatedAt;

  VersionData.fromJson(Map<String, dynamic> json) {
    _id = json['id'];
    _name = json['name'];
    if (json['currentVersionConfig'] != null) {
      _currentVersionConfig = new List<CurrentVersionConfig>();
      json['currentVersionConfig'].forEach((v) {
        _currentVersionConfig.add(new CurrentVersionConfig.fromJson(v));
      });
    }
    _apiKey = json['apiKey'];
    _createdAt = json['createdAt'];
    _updatedAt = json['updatedAt'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this._id;
    data['name'] = this._name;
    if (this._currentVersionConfig != null) {
      data['currentVersionConfig'] =
          this._currentVersionConfig.map((v) => v.toJson()).toList();
    }
    data['apiKey'] = this._apiKey;
    data['createdAt'] = this._createdAt;
    data['updatedAt'] = this._updatedAt;
    return data;
  }
}

class CurrentVersionConfig {
  Title _title;
  Title _message;
  String _platform;
  int _buildVersion;
  Title _okButtonTitle;
  int _comparisonMode;
  String _minSystemVersion;
  Title _cancelButtonTitle;
  String _okButtonActionURL;

  CurrentVersionConfig(
      {Title title,
        Title message,
        String platform,
        int buildVersion,
        Title okButtonTitle,
        int comparisonMode,
        String minSystemVersion,
        Title cancelButtonTitle,
        String okButtonActionURL}) {
    this._title = title;
    this._message = message;
    this._platform = platform;
    this._buildVersion = buildVersion;
    this._okButtonTitle = okButtonTitle;
    this._comparisonMode = comparisonMode;
    this._minSystemVersion = minSystemVersion;
    this._cancelButtonTitle = cancelButtonTitle;
    this._okButtonActionURL = okButtonActionURL;
  }

  Title get title => _title;

  set title(Title title) => _title = title;

  Title get message => _message;

  set message(Title message) => _message = message;

  String get platform => _platform;

  set platform(String platform) => _platform = platform;

  int get buildVersion => _buildVersion;

  set buildVersion(int buildVersion) => _buildVersion = buildVersion;

  Title get okButtonTitle => _okButtonTitle;

  set okButtonTitle(Title okButtonTitle) => _okButtonTitle = okButtonTitle;

  int get comparisonMode => _comparisonMode;

  set comparisonMode(int comparisonMode) => _comparisonMode = comparisonMode;

  String get minSystemVersion => _minSystemVersion;

  set minSystemVersion(String minSystemVersion) =>
      _minSystemVersion = minSystemVersion;

  Title get cancelButtonTitle => _cancelButtonTitle;

  set cancelButtonTitle(Title cancelButtonTitle) =>
      _cancelButtonTitle = cancelButtonTitle;

  String get okButtonActionURL => _okButtonActionURL;

  set okButtonActionURL(String okButtonActionURL) =>
      _okButtonActionURL = okButtonActionURL;

  CurrentVersionConfig.fromJson(Map<String, dynamic> json) {
    _title = json['title'] != null ? new Title.fromJson(json['title']) : null;
    _message =
    json['message'] != null ? new Title.fromJson(json['message']) : null;
    _platform = json['platform'];
    _buildVersion = json['buildVersion'];
    _okButtonTitle = json['okButtonTitle'] != null
        ? new Title.fromJson(json['okButtonTitle'])
        : null;
    _comparisonMode = json['comparisonMode'];
    _minSystemVersion = json['minSystemVersion'];
    _cancelButtonTitle = json['cancelButtonTitle'] != null
        ? new Title.fromJson(json['cancelButtonTitle'])
        : null;
    _okButtonActionURL = json['okButtonActionURL'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this._title != null) {
      data['title'] = this._title.toJson();
    }
    if (this._message != null) {
      data['message'] = this._message.toJson();
    }
    data['platform'] = this._platform;
    data['buildVersion'] = this._buildVersion;
    if (this._okButtonTitle != null) {
      data['okButtonTitle'] = this._okButtonTitle.toJson();
    }
    data['comparisonMode'] = this._comparisonMode;
    data['minSystemVersion'] = this._minSystemVersion;
    if (this._cancelButtonTitle != null) {
      data['cancelButtonTitle'] = this._cancelButtonTitle.toJson();
    }
    data['okButtonActionURL'] = this._okButtonActionURL;
    return data;
  }
}

class Title {
  String _en;
  String _es;
  String _cat;

  Title({String en, String es, String cat}) {
    this._en = en;
    this._es = es;
    this._cat = cat;
  }

  String get en => _en;

  set en(String en) => _en = en;

  String get es => _es;

  set es(String es) => _es = es;

  String get cat => _cat;

  set cat(String cat) => _cat = cat;

  Title.fromJson(Map<String, dynamic> json) {
    _en = json['en'];
    _es = json['es'];
    _cat = json['cat'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['en'] = this._en;
    data['es'] = this._es;
    data['cat'] = this._cat;
    return data;
  }
}
