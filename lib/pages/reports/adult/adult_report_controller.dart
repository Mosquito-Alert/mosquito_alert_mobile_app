import 'package:built_collection/built_collection.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:mosquito_alert/mosquito_alert.dart' as api;
import 'package:mosquito_alert_app/pages/reports/adult/pages/photo_selection_page.dart';
import 'package:mosquito_alert_app/utils/MyLocalizations.dart';
import 'package:mosquito_alert_app/utils/UserManager.dart';
import 'package:provider/provider.dart';

import 'models/adult_report_data.dart';
import 'pages/environment_question_page.dart';
import 'pages/location_selection_page.dart';
import 'pages/notes_and_submit_page.dart';
import 'widgets/progress_indicator.dart';

/// Main controller for the adult report workflow
/// Uses PageView slider architecture for step-by-step progression
class AdultReportController extends StatefulWidget {
  @override
  _AdultReportControllerState createState() => _AdultReportControllerState();
}

class _AdultReportControllerState extends State<AdultReportController> {
  late PageController _pageController;
  late AdultReportData _reportData;
  late api.ObservationsApi _observationsApi;

  int _currentStep = 0;
  bool _isSubmitting = false;

  List<String> get _stepTitles => [
        '(HC) Take Photos',
        '(HC) Select Location',
        '(HC) Environment',
        '(HC) Notes & Submit'
      ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _reportData = AdultReportData();

    // Initialize API
    final apiClient = Provider.of<api.MosquitoAlert>(context, listen: false);
    _observationsApi = apiClient.getObservationsApi();

    _logAnalyticsEvent('adult_report_started');
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

  /// Submit the adult report via API
  Future<void> _submitReport() async {
    if (!_reportData.isValid || _isSubmitting) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      await _logAnalyticsEvent('adult_report_submit_attempt');

      // Step 1: Create location point
      final locationPoint = api.LocationPoint((b) => b
        ..latitude = _reportData.latitude!
        ..longitude = _reportData.longitude!);

      // Step 2: Create location request
      final locationRequest = api.LocationRequest((b) => b
        ..source_ = _reportData.locationSource
        ..point.replace(locationPoint));

      // Step 3: Process photos
      final List<api.SimplePhotoRequest> photoRequests = [];
      for (final photo in _reportData.photos) {
        if (await photo.exists()) {
          final bytes = await photo.readAsBytes();
          photoRequests.add(api.SimplePhotoRequest((b) => b..file = bytes));
        }
      }
      final photos = BuiltList<api.SimplePhotoRequest>(photoRequests);

      // Step 4: Prepare notes
      final notes =
          _reportData.notes?.isNotEmpty == true ? _reportData.notes! : '';

      // Steo 5: Tags
      final userTags = await UserManager.getHashtags();
      final tags = userTags != null ? BuiltList<String>(userTags) : null;

      // Step 6: Make API call
      final response = await _observationsApi.create(
        createdAt: _reportData.createdAt.toUtc(),
        sentAt: DateTime.now().toUtc(),
        location: locationRequest,
        photos: photos,
        note: notes,
        eventEnvironment: _reportData.environmentAnswer ?? '',
        eventMoment: _reportData.eventMoment ?? 'now',
        tags: tags,
      );

      if (response.statusCode == 201) {
        await _logAnalyticsEvent('adult_report_submit_success');
        _showSuccessDialog();
      } else {
        await _logAnalyticsEvent('adult_report_submit_error', parameters: {
          'status_code': response.statusCode?.toString() ?? 'unknown'
        });
        _showErrorDialog('Server error: ${response.statusCode}');
      }
    } catch (e) {
      await _logAnalyticsEvent('adult_report_submit_error',
          parameters: {'error': e.toString()});
      _showErrorDialog('Failed to submit report: $e');
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

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
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(); // Return to home
            },
            child: Text(MyLocalizations.of(context, 'ok')),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(MyLocalizations.of(context, 'app_name')),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(MyLocalizations.of(context, 'ok')),
          ),
        ],
      ),
    );
  }

  Future<void> _logAnalyticsEvent(String eventName,
      {Map<String, Object>? parameters}) async {
    await FirebaseAnalytics.instance.logEvent(
      name: eventName,
      parameters: parameters ?? {},
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_stepTitles[_currentStep]),
        leading: _currentStep > 0
            ? IconButton(
                icon: Icon(Icons.arrow_back),
                onPressed: _previousStep,
              )
            : IconButton(
                icon: Icon(Icons.arrow_back),
                onPressed: () => Navigator.of(context).pop(),
              ),
      ),
      body: Column(
        children: [
          // Progress indicator
          AdultReportProgressIndicator(
            currentStep: _currentStep,
            totalSteps: _stepTitles.length,
            stepTitles: _stepTitles,
          ),

          // Main content
          Expanded(
            child: PageView(
              controller: _pageController,
              physics:
                  NeverScrollableScrollPhysics(), // Disable swipe navigation
              children: [
                PhotoSelectionPage(
                  reportData: _reportData,
                  onNext: _nextStep,
                ),
                LocationSelectionPage(
                  reportData: _reportData,
                  onNext: _nextStep,
                  onPrevious: _previousStep,
                ),
                EnvironmentQuestionPage(
                  reportData: _reportData,
                  onNext: _nextStep,
                  onPrevious: _previousStep,
                ),
                NotesAndSubmitPage(
                  reportData: _reportData,
                  onSubmit: _submitReport,
                  onPrevious: _previousStep,
                  isSubmitting: _isSubmitting,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
