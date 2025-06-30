import 'dart:io';
import 'dart:math';

import 'package:battery_plus/battery_plus.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mosquito_alert/mosquito_alert.dart';
import 'package:mosquito_alert_app/api/api.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:workmanager/workmanager.dart';

class BackgroundTracking {
  static String _scheduledTasksPrefsKey = 'scheduledTrackingEpochs';
  static String _isEnabledPrefsKey = 'trackingEnabled';
  static int tasksPerDay = 5;

  static Future<void> start(
      {bool shouldRun = false, bool requestPermissions = true}) async {
    bool hasPermissions = await BackgroundTracking._checkPermissions(
        requestPermissions: requestPermissions);
    if (!hasPermissions) {
      print('Location Always permission denied. Tracking not enabled.');
      await BackgroundTracking.stop();
      return;
    }

    var prefs = await SharedPreferences.getInstance();
    prefs.setBool(BackgroundTracking._isEnabledPrefsKey, true);

    int alreadyRunTasks = 0;
    if (shouldRun) {
      try {
        await BackgroundTracking.sendLocationUpdate();
        alreadyRunTasks++;
      } catch (e) {
        print(e);
      }
    }

    // Schedule tasks now.
    try {
      await BackgroundTracking.scheduleDailyTrackingTask(
          numScheduledTasks: alreadyRunTasks);
    } catch (e) {
      print(e);
    }

    // Start background tracking at next midnight
    DateTime now = DateTime.now();
    DateTime nextMidnight = DateTime(now.year, now.month, now.day + 1);
    Duration timeUntilMidnight = nextMidnight.difference(now);

    // Register the periodic task, being schedule every night
    print(
        "Nightly scheduler for background tracking starting at ${nextMidnight} (in ${timeUntilMidnight})");
    await Workmanager().registerPeriodicTask(
      'scheduleDailyTasks',
      'scheduleDailyTasks', // ignored on iOS where you should use [uniqueName]
      tag: 'scheduleDailyTasks',
      frequency: Duration(days: 1),
      initialDelay: timeUntilMidnight + Duration(minutes: 5),
    );
  }

  static Future<void> stop() async {
    var prefs = await SharedPreferences.getInstance();
    prefs.setBool(BackgroundTracking._isEnabledPrefsKey, false);

    if (Platform.isAndroid) {
      await Workmanager()
          .cancelByTag('trackingTask'); // Method available only for Android
      await Workmanager().cancelByTag('scheduleDailyTasks');
    } else if (Platform.isIOS) {
      await Workmanager().cancelAll();
    }

    BackgroundTracking._clearSchedulerTaskQueue();
  }

  static Future<bool> isEnabled() async {
    var prefs = await SharedPreferences.getInstance();
    return prefs.getBool(BackgroundTracking._isEnabledPrefsKey) ?? false;
  }

  static Future<bool> _hasLocationAlwaysPermission() async {
    PermissionStatus permStatus = await Permission.locationAlways.status;
    return permStatus.isGranted;
  }

  static Future<bool> _checkPermissions(
      {bool requestPermissions = true}) async {
    if (!requestPermissions) {
      return await BackgroundTracking._hasLocationAlwaysPermission();
    }

    // Step 1: Check the status of locationWhenInUse permission and request if necessary.
    if (!await Permission.locationWhenInUse.request().isGranted) {
      await openAppSettings(); // Open app settings for the user to manually enable the permission
    }

    if (await Permission.locationWhenInUse.request().isGranted) {
      // The locationAlways permission can not be requested directly, the user
      // has to request the locationWhenInUse permission first. Accepting this
      // permission by clicking on the 'Allow While Using App' gives the user
      // the possibility to request the locationAlways permission.
      if (!await Permission.locationAlways.request().isGranted) {
        await openAppSettings();
      }

      return await BackgroundTracking._hasLocationAlwaysPermission();
    }

    return false;
  }

  static List<TimeOfDay> _getRandomTimes(int numSamples,
      {TimeOfDay? minTime, TimeOfDay? maxTime}) {
    // Default values if minTime or maxTime are not provided
    minTime ??= TimeOfDay(hour: 0, minute: 0);
    maxTime ??= TimeOfDay(hour: 23, minute: 59);

    // Convert minTime and maxTime to minutes since midnight
    int minMinutes = minTime.hour * 60 + minTime.minute;
    int maxMinutes = maxTime.hour * 60 + maxTime.minute;

    var random = Random();
    var randomTimes = <TimeOfDay>[];
    for (var i = 0; i < numSamples; i++) {
      int randomMinutes =
          random.nextInt(maxMinutes - minMinutes + 1) + minMinutes;
      int randomHour = randomMinutes ~/ 60;
      int randomMinute = randomMinutes % 60;

      randomTimes.add(TimeOfDay(hour: randomHour, minute: randomMinute));
    }

    return randomTimes;
  }

  static Future<bool> canScheduleAt(DateTime datetime) async {
    List<String> schedulerTaskQueue =
        await BackgroundTracking._getSchedulerTaskQueue();
    String schedulerId = await BackgroundTracking._getSchedulerId(datetime);
    return !schedulerTaskQueue.contains(schedulerId);
  }

  static Future<bool> scheduleDailyTrackingTask(
      {int numScheduledTasks = 0}) async {
    try {
      // Ensure background tracking is enabled
      if (!await BackgroundTracking.isEnabled()) {
        throw Exception('Background tracking is not enabled.');
      }

      DateTime now = DateTime.now();

      // Ensure scheduling is allowed at the current time
      if (!await BackgroundTracking.canScheduleAt(now)) {
        throw Exception('Scheduling is not allowed at this time.');
      }

      await BackgroundTracking._appendScheduledDateTimeTaskQueue(now);

      int numTaskToSchedule =
          BackgroundTracking.tasksPerDay - numScheduledTasks;
      if (numTaskToSchedule <= 0) {
        throw Exception('All tasks for today have already been scheduled.');
      }

      // Calculate the fraction of the day remaining
      DateTime startOfDay = DateTime(now.year, now.month, now.day);
      double fractionOfDayElapsed =
          now.difference(startOfDay).inSeconds / Duration.secondsPerDay;
      double remainingFractionOfDay = 1 - fractionOfDayElapsed;

      // Only schedule the fraction of tasks for the remaining day length.
      int numTasks =
          max(1, (numTaskToSchedule * remainingFractionOfDay).ceil());
      List<TimeOfDay> randomTimes =
          _getRandomTimes(numTasks, minTime: TimeOfDay.now());

      // Schedule tasks asynchronously
      randomTimes.forEach((time) async {
        DateTime scheduledTime = DateTime(
          now.year,
          now.month,
          now.day,
          time.hour,
          time.minute,
        );

        print('Scheduled new tracking task to be run at ${scheduledTime}');

        await Workmanager().registerOneOffTask(
          'tracking_task_${scheduledTime.millisecondsSinceEpoch}',
          'trackingTask',
          initialDelay: scheduledTime.difference(now),
          tag: 'trackingTask',
          constraints: Constraints(networkType: NetworkType.connected),
        );
      });

      return true;
    } catch (e) {
      return Future.error(e);
    }
  }

  static Future<bool> sendLocationUpdate() async {
    try {
      // Check location permission
      if (await Geolocator.checkPermission() != LocationPermission.always) {
        throw Exception("Location permission is not set to 'always'.");
      }

      // Ensure background tracking is enabled
      if (!await BackgroundTracking.isEnabled()) {
        throw Exception("Background tracking is disabled.");
      }

      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      int batteryLevel = await Battery().batteryLevel;
      String trackingUuid = await BackgroundTracking._getTrackingUUID();

      // Send data to API
      FixRequest fixRequest = FixRequest((b) => b
        ..coverageUuid = trackingUuid
        ..createdAt = DateTime.now().toUtc()
        ..sentAt = DateTime.now().toUtc()
        ..point.replace(FixLocationRequest((p) => p
          ..latitude = position.latitude
          ..longitude = position.longitude))
        ..power = batteryLevel / 100.0);
      final response =
          await ApiSingleton.fixesApi.create(fixRequest: fixRequest);
      return response.statusCode == 201;
    } catch (e) {
      return Future.error(e);
    }
  }

  static Future<String> _getTrackingUUID() async {
    var prefs = await SharedPreferences.getInstance();
    String? trackingUuid = prefs.getString('trackingUUID');
    if (trackingUuid == null || trackingUuid.isEmpty) {
      trackingUuid = Uuid().v4();
      await prefs.setString('trackingUUID', trackingUuid);
    }
    return trackingUuid;
  }

  static Future<List<String>> _getSchedulerTaskQueue() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    return prefs.getStringList(BackgroundTracking._scheduledTasksPrefsKey) ??
        [];
  }

  static Future<void> _clearSchedulerTaskQueue() async {
    var prefs = await SharedPreferences.getInstance();
    prefs.remove(BackgroundTracking._scheduledTasksPrefsKey);
  }

  static Future<void> _appendScheduledDateTimeTaskQueue(
      DateTime datetime) async {
    List<String> taskQueue = await BackgroundTracking._getSchedulerTaskQueue();
    String currentId = await BackgroundTracking._getSchedulerId(datetime);

    if (!taskQueue.contains(currentId)) {
      // Prevent duplicates
      taskQueue.add(currentId);

      final prefs = await SharedPreferences.getInstance();
      await prefs.reload();
      prefs.setStringList(
          BackgroundTracking._scheduledTasksPrefsKey, taskQueue);
    }
  }

  static Future<String> _getSchedulerId(DateTime datetime) async {
    DateTime date = DateTime(datetime.year, datetime.month, datetime.day);
    return date.millisecondsSinceEpoch.toString();
  }
}
