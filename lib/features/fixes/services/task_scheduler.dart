import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

class TaskQueue {
  static const _key = 'trackingQueue';

  static List<DateTime> _tasks = [];
  static late SharedPreferences _prefs;

  static final _controller = StreamController<List<DateTime>>.broadcast();
  static Stream<List<DateTime>> get stream => _controller.stream;

  static List<DateTime> getAll() => List.unmodifiable(_tasks);

  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;
    _prefs = await SharedPreferences.getInstance();
    _tasks = _loadQueue();
    _initialized = true;

    _controller.add(getAll());
  }

  static List<DateTime> _loadQueue() {
    final list = _prefs.getStringList(_key) ?? [];
    return list
        .map((s) => DateTime.fromMillisecondsSinceEpoch(int.parse(s)))
        .toList();
  }

  static Future<void> _saveQueue() async {
    final encoded = _tasks
        .map((d) => d.millisecondsSinceEpoch.toString())
        .toList();
    await _prefs.setStringList(_key, encoded);

    if (_initialized) {
      _controller.add(List.unmodifiable(_tasks)); // emit change
    }
  }

  static Future<void> clear() async {
    _tasks.clear();
    await _saveQueue();
  }

  static Future<void> add(DateTime task) async {
    if (!_tasks.any((t) => t.isAtSameMomentAs(task))) {
      _tasks.add(task);
      await _saveQueue();
    }
  }

  static Future<void> removeTask(DateTime task) async {
    _tasks.removeWhere((t) => t.isAtSameMomentAs(task));
    await _saveQueue();
  }

  static bool contains(DateTime task) {
    return _tasks.any((t) => t.isAtSameMomentAs(task));
  }

  static List<DateTime> filterByDay(DateTime day) {
    return _tasks.where((task) {
      return task.year == day.year &&
          task.month == day.month &&
          task.day == day.day;
    }).toList();
  }

  static void dispose() {
    _controller.close();
  }
}

class TaskScheduler {
  static const taskTag = 'trackingTask';

  static Future<void> init() async {
    await TaskQueue.init();
  }

  static Future<void> scheduleTasksForToday({required int tasksPerDay}) async {
    final now = DateTime.now();

    final pendingDailyTasks = TaskQueue.filterByDay(now);
    final tasksRemaining = tasksPerDay - pendingDailyTasks.length;

    if (tasksRemaining <= 0) return;

    // Calculate the fraction of the day remaining
    final startOfDay = DateTime(now.year, now.month, now.day);
    final secondsElapsed = now.difference(startOfDay).inSeconds.toDouble();
    final fractionElapsed = secondsElapsed / Duration.secondsPerDay;
    final fractionRemaining = (1 - fractionElapsed).clamp(0.0, 1.0);

    // Only schedule the fraction of tasks for the remaining day length.
    final numToSchedule = max(1, (tasksRemaining * fractionRemaining).ceil());

    final randomTimes = _getRandomTimes(
      numToSchedule,
      minTime: TimeOfDay.now(),
    );

    for (var t in randomTimes) {
      final scheduled = DateTime(
        now.year,
        now.month,
        now.day,
        t.hour,
        t.minute,
      );

      await _scheduleTask(scheduled);
    }
  }

  static Future<void> _scheduleTask(DateTime time) async {
    DateTime now = DateTime.now();
    final diff = time.difference(now);

    await Workmanager().registerOneOffTask(
      'tracking_task_${time.millisecondsSinceEpoch}',
      'trackingTask',
      initialDelay: diff.isNegative ? Duration.zero : diff,
      tag: taskTag,
    );
    await TaskQueue.add(time);
  }

  static Future<void> clear() async {
    if (Platform.isAndroid) {
      // Method cancelByTag available only for Android
      await Workmanager().cancelByTag(taskTag);
    } else if (Platform.isIOS) {
      await Workmanager().cancelAll();
    }
    await TaskQueue.clear();
  }

  static List<TimeOfDay> _getRandomTimes(
    int count, {
    TimeOfDay? minTime,
    TimeOfDay? maxTime,
  }) {
    // Default values if minTime or maxTime are not provided
    minTime ??= TimeOfDay(hour: 0, minute: 0);
    maxTime ??= TimeOfDay(hour: 23, minute: 59);

    // Convert minTime and maxTime to minutes since midnight
    int minMins = minTime.hour * 60 + minTime.minute;
    int maxMins = maxTime.hour * 60 + maxTime.minute;

    final rng = Random();
    return List.generate(count, (_) {
      int mins = rng.nextInt(maxMins - minMins + 1) + minMins;
      return TimeOfDay(hour: mins ~/ 60, minute: mins % 60);
    });
  }
}
