import 'package:flutter/material.dart';
import 'package:mosquito_alert_app/utils/MyLocalizations.dart';

// Mock MyLocalizations for testing
class MockMyLocalizations extends MyLocalizations {
  MockMyLocalizations() : super(const Locale('en'));

  @override
  String translate(String? key) {
    switch (key) {
      case 'notifications_title':
        return 'Notifications';
      case 'no_notifications_yet_txt':
        return 'No notifications yet';
      case 'no_reports_yet_txt':
        return 'No registered reports';
      case 'single_bite':
        return 'Bite';
      case 'plural_bite':
        return 'Bites';
      case 'no_bites':
        return 'No bites';
      case 'bite_report_bodypart_head':
        return 'Head';
      case 'bite_report_bodypart_chest':
        return 'Chest';
      case 'bite_report_bodypart_leftarm':
        return 'Left arm';
      case 'bite_report_bodypart_rightarm':
        return 'Right arm';
      case 'bite_report_bodypart_leftleg':
        return 'Left leg';
      case 'bite_report_bodypart_rightleg':
        return 'Right leg';
      case 'continue_txt':
        return 'Continue';
      case 'current_location_txt':
        return 'Current Location';
      case 'select_location_txt':
        return 'Select Location';
      case 'send_report_txt':
        return 'Send Report';
      case 'save_report_ok_txt':
        return 'Report saved successfully';
      case 'save_report_ko_txt':
        return 'Error saving report';
      case 'delete_report_title':
        return 'Delete Report';
      case 'delete_report_txt':
        return 'Are you sure you want to delete this report?';
      case 'delete':
        return 'Delete';
      case 'yes':
        return 'Yes';
      case 'no':
        return 'No';
      case 'app_name':
        return 'Mosquito Alert';
      case 'gallery_info_01':
        return 'Welcome to the Mosquito Guide - Slide 1';
      case 'gallery_info_02':
        return 'Mosquito Identification - Slide 2';
      case 'gallery_info_03':
        return 'Breeding Sites - Slide 3';
      case 'gallery_info_04':
        return 'Prevention Tips - Slide 4';
      case 'gallery_info_05':
        return 'Reporting Process - Slide 5';
      case 'gallery_info_06':
        return 'Photo Guidelines - Slide 6';
      case 'gallery_info_07':
        return 'Location Accuracy - Slide 7';
      case 'gallery_info_08':
        return 'Community Impact - Slide 8';
      case 'gallery_info_09':
        return 'Thank You - Slide 9';
      default:
        return key ?? '';
    }
  }

  static MockMyLocalizations of(BuildContext context) {
    return MockMyLocalizations();
  }
}

class MockMyLocalizationsDelegate
    extends LocalizationsDelegate<MyLocalizations> {
  const MockMyLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<MyLocalizations> load(Locale locale) async {
    return MockMyLocalizations();
  }

  @override
  bool shouldReload(MockMyLocalizationsDelegate old) => false;
}
