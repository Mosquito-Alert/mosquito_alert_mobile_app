import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mosquito_alert_app/features/fixes/services/task_scheduler.dart';
import 'package:mosquito_alert_app/features/fixes/services/tracking_service.dart';

class FixesProvider extends ChangeNotifier {
  bool _isEnabled = false;
  List<DateTime> _scheduledTasks = [];

  bool get isEnabled => _isEnabled;
  List<DateTime> get scheduledTasks => _scheduledTasks;

  StreamSubscription<List<DateTime>>? _taskSub;

  FixesProvider() {
    _init();
  }

  Future<void> _init() async {
    _isEnabled = await TrackingService.isEnabled;
    _scheduledTasks = await TrackingService.getScheduledTasks();
    // Listen to live updates from TaskQueue
    _taskSub = TaskQueue.stream.listen((tasks) {
      _scheduledTasks = tasks;
      notifyListeners();
    });

    notifyListeners();
  }

  /// Enable tracking
  Future<void> enableTracking({bool runImmediately = false}) async {
    _isEnabled = true;
    notifyListeners();
    try {
      await TrackingService.start(runImmediately: runImmediately);
    } catch (e) {
      print('Error configuring TrackingService: $e');
    }

    _isEnabled = await TrackingService.isEnabled;
    _scheduledTasks = await TrackingService.getScheduledTasks();
    notifyListeners();
  }

  /// Disable tracking
  Future<void> disableTracking() async {
    await TrackingService.stop();
    _isEnabled = false;
    _scheduledTasks = [];
    notifyListeners();
  }

  Future<void> sendLocationNow() async {
    try {
      await TrackingService.sendLocationNow();
    } catch (e) {
      print("Error sending location now: $e");
    }
  }

  @override
  void dispose() {
    _taskSub?.cancel();
    super.dispose();
  }
}
