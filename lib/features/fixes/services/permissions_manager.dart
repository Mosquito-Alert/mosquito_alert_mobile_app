import 'package:permission_handler/permission_handler.dart';

class PermissionsManager {
  static Future<void> init() async {
    // Optional: cache any permission state
  }

  static Future<void> requestPermissions() async {
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
    }
  }

  static Future<bool> checkPermissions() async {
    if (await Permission.locationAlways.isGranted) return true;
    return false;
  }
}
