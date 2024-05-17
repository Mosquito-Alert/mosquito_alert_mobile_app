import 'dart:math';

import 'package:battery_plus/battery_plus.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mosquito_alert_app/api/api.dart';
import 'package:mosquito_alert_app/utils/UserManager.dart';
import 'package:workmanager/workmanager.dart';


class BackgroundTracking{
  static List<TimeOfDay> getRandomTimes(int numSamples) {
    var random = Random();
    var randomTimes = <TimeOfDay>[];

    for (var i = 0; i < numSamples; i++) {
      var hour = random.nextInt(24); // Random hour between 00 and 23
      var minute = random.nextInt(60); // Random minute between 00 and 59
      var time = TimeOfDay(hour: hour, minute: minute);
      randomTimes.add(time);
    }

    return randomTimes;
  }

  static Future<void> scheduleMultipleTrackingTask(int numTasks) async {
    var permission = await Geolocator.checkPermission();
    var isBgTrackingEnabled = await UserManager.getTracking();

    if (permission != LocationPermission.always || !isBgTrackingEnabled){
      return Future.value(true);
    }

    var randomTimes = getRandomTimes(numTasks);

    randomTimes.asMap().forEach((index, time) async {
      await Workmanager().registerOneOffTask(
        'tracking_task_$index',
        'trackingTask',
        initialDelay: Duration(hours: time.hour, minutes: time.minute),
        tag: 'trackingTask',
        constraints: Constraints(networkType: NetworkType.connected),
      );
    });
  }

  static Future<void> trackingTask() async {
    var permission = await Geolocator.checkPermission();
    var isBgTrackingEnabled = await UserManager.getTracking();

    if (permission != LocationPermission.always || !isBgTrackingEnabled){
      return Future.value(true);
    }

    var position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    var battery = Battery();
    await ApiSingleton().sendFixes(position.latitude,
                                   position.longitude,
                                   DateTime.now().toUtc().toIso8601String(),
                                   await battery.batteryLevel);
  }
}
