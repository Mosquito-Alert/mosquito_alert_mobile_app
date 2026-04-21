import 'package:mosquito_alert_app/features/fixes/data/fixes_repository.dart';
import 'package:mosquito_alert_app/features/fixes/services/location_sender.dart';
import 'package:mosquito_alert_app/features/fixes/services/permissions_manager.dart';
import 'package:mosquito_alert_app/features/fixes/services/task_scheduler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

class TrackingService {
  static final TrackingService _instance = TrackingService._internal();
  factory TrackingService() => _instance;
  TrackingService._internal();

  static String _isEnabledPrefsKey = 'trackingEnabled';
  static late SharedPreferences _prefs;

  static const dailyTaskCount = 5;

  static bool _initialized = false;
  static void _setIsEnabled(bool value) {
    _prefs.setBool(_isEnabledPrefsKey, value);
  }

  static bool get isEnabled => _prefs.getBool(_isEnabledPrefsKey) ?? false;

  static late LocationSender _locationSender;

  static Future<void> configure({required FixesRepository repository}) async {
    if (_initialized) return;

    _prefs = await SharedPreferences.getInstance();

    await PermissionsManager.init();
    await TaskScheduler.init();

    _locationSender = await LocationSender.create(repository: repository);

    _initialized = true;
  }

  static Future<void> start({bool runImmediately = false}) async {
    if (!await PermissionsManager.checkPermissions()) {
      print('Tracking permissions denied');
      await stop();
      return;
    }

    _setIsEnabled(true);

    int launchedTasks = 0;
    if (runImmediately) {
      await sendLocationNow();
      launchedTasks++;
    }

    await TaskScheduler.scheduleTasksForToday(
      tasksPerDay: dailyTaskCount - launchedTasks,
    );

    // Start background tracking at next midnight
    DateTime now = DateTime.now();
    DateTime nextMidnight = DateTime(now.year, now.month, now.day + 1);
    Duration timeUntilMidnight = nextMidnight.difference(now);

    // Register the periodic task, being schedule every night
    print(
      "Nightly scheduler for background tracking starting at ${nextMidnight} (in ${timeUntilMidnight})",
    );
    await Workmanager().registerPeriodicTask(
      'scheduleDailyTasks',
      'scheduleDailyTasks', // ignored on iOS where you should use [uniqueName]
      frequency: Duration(days: 1),
      initialDelay: timeUntilMidnight + Duration(minutes: 5),
    );
  }

  static Future<void> scheduleDailyTasks({
    int numTasks = dailyTaskCount,
  }) async {
    if (!isEnabled) return;
    await TaskScheduler.scheduleTasksForToday(tasksPerDay: numTasks);
  }

  static Future<void> stop() async {
    _setIsEnabled(false);
    await TaskScheduler.clear();
    await Workmanager().cancelByUniqueName('scheduleDailyTasks');
  }

  static Future<void> sendLocationNow() async {
    // Check location permission
    if (!await PermissionsManager.checkPermissions()) {
      throw Exception("Location permission is not set to 'always'.");
    }

    // Ensure background tracking is enabled
    if (!isEnabled) {
      throw Exception("Background tracking is disabled.");
    }

    await _locationSender.sendLocation();
  }

  static Future<List<DateTime>> getScheduledTasks() async {
    return TaskQueue.getAll();
  }
}
