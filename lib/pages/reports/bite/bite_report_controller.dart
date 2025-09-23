import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:mosquito_alert/mosquito_alert.dart' as api;
import 'package:mosquito_alert_app/pages/reports/shared/pages/location_selection_page.dart';
import 'package:mosquito_alert_app/pages/reports/shared/pages/notes_and_submit_page.dart';
import 'package:mosquito_alert_app/pages/reports/shared/widgets/progress_indicator.dart';
import 'package:mosquito_alert_app/utils/MyLocalizations.dart';
import 'package:provider/provider.dart';

import 'models/bite_report_data.dart';
import 'pages/bite_questions_page.dart';

/// Main controller for the bite report workflow
/// Uses PageView slider architecture for step-by-step progression
class BiteReportController extends StatefulWidget {
  @override
  _BiteReportControllerState createState() => _BiteReportControllerState();
}

class _BiteReportControllerState extends State<BiteReportController> {
  late PageController _pageController;
  late BiteReportData _reportData;
  late api.BitesApi _bitesApi;

  int _currentStep = 0;
  bool _isSubmitting = false;

  List<String> get _stepTitles =>
      ['(HC) Bite Information', '(HC) Select Location', '(HC) Notes & Submit'];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _reportData = BiteReportData();

    // Initialize API
    final apiClient = Provider.of<api.MosquitoAlert>(context, listen: false);
    _bitesApi = apiClient.getBitesApi();

    _logAnalyticsEvent('bite_report_started');
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// Navigate to next step
  void _nextStep() {
    if (_currentStep < _stepTitles.length - 1) {
      setState(() {
        _currentStep++;
      });
      _pageController.nextPage(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      _logAnalyticsEvent('bite_report_step_${_currentStep + 1}');
    }
  }

  /// Navigate to previous step
  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
      _pageController.previousPage(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  /// Handle environment selection
  void _updateEnvironment(api.BiteRequestEventEnvironmentEnum environment) {
    setState(() {
      _reportData.eventEnvironment = environment;
    });
  }

  /// Handle timing selection
  void _updateTiming(api.BiteRequestEventMomentEnum moment) {
    setState(() {
      _reportData.eventMoment = moment;
    });
  }

  /// Handle location selection
  void _updateLocation(double latitude, double longitude,
      api.LocationRequestSource_Enum source) {
    setState(() {
      _reportData.latitude = latitude;
      _reportData.longitude = longitude;
      _reportData.locationSource = source;
    });
  }

  /// Handle notes update
  void _updateNotes(String? notes) {
    setState(() {
      _reportData.notes =
          (notes?.trim().isEmpty ?? true) ? null : notes!.trim();
    });
  }

  /// Check if current step is complete
  bool get _canProceed {
    switch (_currentStep) {
      case 0: // Bite questions step
        return _reportData.hasValidBiteCounts &&
            _reportData.hasValidEnvironment &&
            _reportData.hasValidTiming;
      case 1: // Location step
        return _reportData.hasValidLocation;
      case 2: // Notes step (always optional)
        return true;
      default:
        return false;
    }
  }

  /// Submit the bite report
  Future<void> _submitReport() async {
    if (!_reportData.isValid || _isSubmitting) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Create location point
      final locationPoint = api.LocationPoint((b) => b
        ..latitude = _reportData.latitude!
        ..longitude = _reportData.longitude!);

      // Create location request
      final location = api.LocationRequest((b) => b
        ..source_ = _reportData.locationSource
        ..point.replace(locationPoint));

      // Create bite counts request
      final counts = api.BiteCountsRequest((b) => b
        ..head = _reportData.headBites
        ..leftArm = _reportData.leftHandBites
        ..rightArm = _reportData.rightHandBites
        ..chest = _reportData.chestBites
        ..leftLeg = _reportData.leftLegBites
        ..rightLeg = _reportData.rightLegBites);

      // Create the bite request
      final biteRequest = api.BiteRequest((b) => b
        ..createdAt = DateTime.now().toUtc()
        ..sentAt = DateTime.now().toUtc()
        ..location.replace(location)
        ..note = _reportData.notes
        ..eventEnvironment = _reportData.eventEnvironment!
        ..eventMoment = _reportData.eventMoment!
        ..counts.replace(counts));

      // Submit the request
      final response = await _bitesApi.create(biteRequest: biteRequest);

      if (response.statusCode == 201) {
        _logAnalyticsEvent('bite_report_submitted');
        _showSuccessDialog();
      } else {
        _showErrorDialog();
      }
    } catch (e) {
      print('Error creating bite report: $e');
      _showErrorDialog();
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  /// Show success dialog
  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(MyLocalizations.of(context, 'app_name')),
        content: Text(MyLocalizations.of(context, 'save_report_ok_txt')),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Show error dialog
  void _showErrorDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(MyLocalizations.of(context, 'app_name')),
        content: Text(MyLocalizations.of(context, 'save_report_ko_txt')),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Log analytics event
  void _logAnalyticsEvent(String eventName) {
    FirebaseAnalytics.instance.logEvent(
      name: eventName,
      parameters: {'type': 'bite'},
    );
  }

  /// Handle back button/navigation
  void _handleBackPressed() {
    if (_currentStep > 0) {
      _previousStep();
    } else {
      _showExitConfirmation();
    }
  }

  /// Show exit confirmation if data exists
  void _showExitConfirmation() {
    if (_reportData.totalBites > 0) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(MyLocalizations.of(context, 'app_name')),
          content:
              Text(MyLocalizations.of(context, 'close_report_no_save_txt')),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
              child: Text('Exit'),
            ),
          ],
        ),
      );
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _reportData,
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (bool didPop, Object? result) {
          if (!didPop) {
            _handleBackPressed();
          }
        },
        child: Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: Colors.black),
              onPressed: _handleBackPressed,
            ),
            title: Text(
              MyLocalizations.of(context, 'biting_report_txt'),
              style: TextStyle(
                color: Colors.black,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            centerTitle: true,
          ),
          body: Column(
            children: [
              // Progress indicator
              ReportProgressIndicator(
                currentStep: _currentStep,
                totalSteps: _stepTitles.length,
                stepTitles: _stepTitles,
              ),

              // Page view content
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: NeverScrollableScrollPhysics(), // Disable swipe
                  children: [
                    // Step 1: Bite questions
                    BiteQuestionsPage(
                      onEnvironmentChanged: _updateEnvironment,
                      onTimingChanged: _updateTiming,
                      onNext: _canProceed ? _nextStep : null,
                      onPrevious: _previousStep,
                      canProceed: _canProceed,
                    ),

                    // Step 2: Location selection
                    LocationSelectionPage(
                      title: '(HC) Select Location',
                      subtitle: '(HC) Where did the biting occur?',
                      initialLatitude: _reportData.latitude,
                      initialLongitude: _reportData.longitude,
                      onLocationSelected: _updateLocation,
                      onNext: _nextStep,
                      onPrevious: _previousStep,
                      canProceed: _canProceed,
                      locationDescription: _reportData.locationDescription,
                      locationSource: _reportData.locationSource,
                    ),

                    // Step 3: Notes and submit
                    NotesAndSubmitPage(
                      initialNotes: _reportData.notes ?? '',
                      onNotesChanged: _updateNotes,
                      onSubmit: _submitReport,
                      onPrevious: _previousStep,
                      isSubmitting: _isSubmitting,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
