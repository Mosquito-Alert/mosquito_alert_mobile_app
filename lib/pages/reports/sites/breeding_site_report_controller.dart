import 'package:built_collection/built_collection.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:mosquito_alert/mosquito_alert.dart' as api;
import 'package:mosquito_alert_app/pages/reports/shared/pages/location_selection_page.dart';
import 'package:mosquito_alert_app/pages/reports/shared/pages/notes_and_submit_page.dart';
import 'package:mosquito_alert_app/pages/reports/shared/pages/photo_selection_page.dart';
import 'package:mosquito_alert_app/pages/reports/shared/widgets/progress_indicator.dart';
import 'package:mosquito_alert_app/utils/MyLocalizations.dart';
import 'package:mosquito_alert_app/utils/UserManager.dart';
import 'package:provider/provider.dart';

import 'models/breeding_site_report_data.dart';
import 'pages/site_type_selection_page.dart';
import 'pages/water_question_page.dart';

/// Main controller for the breeding site report workflow
/// Uses PageView slider architecture for step-by-step progression
class BreedingSiteReportController extends StatefulWidget {
  @override
  _BreedingSiteReportControllerState createState() =>
      _BreedingSiteReportControllerState();
}

class _BreedingSiteReportControllerState
    extends State<BreedingSiteReportController> {
  late PageController _pageController;
  late BreedingSiteReportData _reportData;
  late api.ObservationsApi _observationsApi;

  int _currentStep = 0;
  bool _isSubmitting = false;

  List<String> get _stepTitles => [
        '(HC) Site Type',
        '(HC) Take Photos',
        '(HC) Water Status',
        '(HC) Select Location',
        '(HC) Notes & Submit'
      ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _reportData = BreedingSiteReportData();

    // Initialize API
    final apiClient = Provider.of<api.MosquitoAlert>(context, listen: false);
    _observationsApi = apiClient.getObservationsApi();

    _logAnalyticsEvent('breeding_site_report_started');
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

  /// Handle location selection callback
  void _onLocationSelected(double latitude, double longitude,
      api.LocationRequestSource_Enum source) {
    setState(() {
      _reportData.latitude = latitude;
      _reportData.longitude = longitude;
      _reportData.locationSource = source;
    });
  }

  /// Handle photo selection callback
  void _onPhotosChanged() {
    setState(() {
      // Trigger rebuild to update any photo-dependent UI
    });
  }

  /// Handle notes changes callback
  void _onNotesChanged(String? notes) {
    setState(() {
      _reportData.notes = notes;
    });
  }

  /// Submit the breeding site report via API
  Future<void> _submitReport() async {
    if (!_reportData.isValid || _isSubmitting) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      await _logAnalyticsEvent('breeding_site_report_submit_attempt');

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

      // Step 5: Tags
      final userTags = await UserManager.getHashtags();
      final tags = userTags != null ? BuiltList<String>(userTags) : null;

      // Step 6: Make API call
      // Note: This assumes ObservationsApi can handle breeding sites too
      // You may need to adapt this based on the actual API structure
      // TODO: Add breeding site specific fields (siteType, hasWater) to API call
      final response = await _observationsApi.create(
        createdAt: _reportData.createdAt.toUtc(),
        sentAt: DateTime.now().toUtc(),
        location: locationRequest,
        photos: photos,
        note: notes,
        // Add breeding site specific fields
        tags: tags,
        // TODO: Map breeding site specific fields to API parameters
        // This may need adjustment based on actual API schema
      );

      if (response.statusCode == 201) {
        await _logAnalyticsEvent('breeding_site_report_submit_success');
        _showSuccessDialog();
      } else {
        await _logAnalyticsEvent('breeding_site_report_submit_error',
            parameters: {
              'status_code': response.statusCode?.toString() ?? 'unknown'
            });
        _showErrorDialog('Server error: ${response.statusCode}');
      }
    } catch (e) {
      await _logAnalyticsEvent('breeding_site_report_submit_error',
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
          ReportProgressIndicator(
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
                SiteTypeSelectionPage(
                  reportData: _reportData,
                  onNext: _nextStep,
                ),
                PhotoSelectionPage(
                  photos: _reportData.photos,
                  onPhotosChanged: _onPhotosChanged,
                  onNext: _nextStep,
                  onPrevious: _previousStep,
                  maxPhotos: 3,
                  minPhotos: 1,
                  titleKey: 'bs_info_adult_title',
                  subtitleKey: 'camera_info_breeding_txt_01',
                  infoBadgeTextKey: 'camera_info_breeding_txt_02',
                ),
                WaterQuestionPage(
                  reportData: _reportData,
                  onNext: _nextStep,
                  onPrevious: _previousStep,
                ),
                LocationSelectionPage(
                  title: MyLocalizations.of(context, 'question_16'),
                  subtitle:
                      '(HC) Please indicate where the breeding site is located:',
                  initialLatitude: _reportData.latitude,
                  initialLongitude: _reportData.longitude,
                  onLocationSelected: _onLocationSelected,
                  onNext: _nextStep,
                  onPrevious: _previousStep,
                  canProceed: _reportData.latitude != null &&
                      _reportData.longitude != null,
                  locationDescription: _reportData.locationDescription,
                  locationSource: _reportData.locationSource,
                ),
                NotesAndSubmitPage(
                  initialNotes: _reportData.notes,
                  onNotesChanged: _onNotesChanged,
                  onSubmit: _submitReport,
                  onPrevious: _previousStep,
                  isSubmitting: _isSubmitting,
                  notesHint:
                      '(HC) e.g., "Large container", "Near construction site", "Visible mosquito larvae"...',
                  submitLoadingText:
                      '(HC) Submitting your breeding site report...',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
