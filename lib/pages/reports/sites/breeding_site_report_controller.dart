import 'package:built_collection/built_collection.dart';
import 'package:dio/dio.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:mosquito_alert/mosquito_alert.dart';
import 'package:mosquito_alert_app/pages/reports/shared/pages/location_selection_page.dart';
import 'package:mosquito_alert_app/pages/reports/shared/pages/notes_and_submit_page.dart';
import 'package:mosquito_alert_app/pages/reports/shared/pages/photo_selection_page.dart';
import 'package:mosquito_alert_app/pages/reports/shared/utils/report_dialogs.dart';
import 'package:mosquito_alert_app/pages/reports/shared/widgets/progress_indicator.dart';
import 'package:mosquito_alert_app/utils/UserManager.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import 'models/breeding_site_report_data.dart';
import 'pages/larvae_question_page.dart';
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
  late BreedingSiteReportData _reportData;
  late BreedingSitesApi _breedingSitesApi;

  int _currentStep = 0;
  bool _isSubmitting = false;

  /// Gets the current step titles based on water status
  List<String> get _stepTitles {
    final titles = <String>[
      '(HC) Site Type',
      '(HC) Take Photos',
      '(HC) Water Status',
    ];

    // Add larvae step only if water is present
    if (_reportData.hasWater == true) {
      titles.add('(HC) Larvae Check');
    }

    // Always add final steps
    titles.addAll(['(HC) Select Location', '(HC) Notes & Submit']);

    return titles;
  }

  @override
  void initState() {
    super.initState();
    _reportData = BreedingSiteReportData();

    // Initialize API
    final apiClient = Provider.of<MosquitoAlert>(context, listen: false);
    _breedingSitesApi = apiClient.getBreedingSitesApi();

    _logAnalyticsEvent('start_report');
  }

  @override
  void dispose() {
    super.dispose();
  }

  /// Navigate to next step
  void _nextStep() {
    if (_currentStep < _stepTitles.length - 1) {
      setState(() {
        _currentStep++;
      });
    }
  }

  /// Navigate to next step after water question, handling conditional larvae question
  void _nextStepAfterWater() {
    if (_reportData.hasWater == false) {
      // Clear any larvae response if water is not present
      _reportData.hasLarvae = null;
    }

    setState(() {
      _currentStep++;
    });
  }

  /// Navigate to previous step
  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
    }
  }

  /// Handle location selection callback
  void _onLocationSelected(
      double latitude, double longitude, LocationRequestSource_Enum source) {
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
    await _logAnalyticsEvent('submit_report');

    try {
      // Step 1: Create location request
      final locationRequest = LocationRequest((b) => b
        ..source_ = _reportData.locationSource
        ..point.latitude = _reportData.latitude!
        ..point.longitude = _reportData.longitude!);

      // Step 2: Process photos
      final List<MultipartFile> photos = [];
      final uuid = Uuid();
      for (final photo in _reportData.photos) {
        photos.add(await MultipartFile.fromBytes(photo,
            filename:
                '${uuid.v4()}.jpg', // NOTE: Filename is required by the API
            contentType: DioMediaType('image', 'jpeg')));
      }
      final photosRequest = BuiltList<MultipartFile>(photos);

      // Step 3: Tags
      final userTags = await UserManager.getHashtags();
      final tags = userTags != null ? BuiltList<String>(userTags) : null;

      // Step 4: Make API call using BreedingSitesApi
      final response = await _breedingSitesApi.create(
        createdAt: _reportData.createdAt.toUtc(),
        sentAt: DateTime.now().toUtc(),
        location: locationRequest,
        photos: photosRequest,
        note: _reportData.notes,
        tags: tags,
        siteType: _reportData.siteType,
        hasWater: _reportData.hasWater,
        hasLarvae: _reportData.hasLarvae,
      );

      if (response.statusCode == 201) {
        ReportDialogs.showSuccessDialog(
          context,
          onOkPressed: () {
            Navigator.of(context).popUntil((route) => route.isFirst);
          },
        );
      } else {
        ReportDialogs.showErrorDialog(
            context, 'Server error: ${response.statusCode}');
      }
    } catch (e) {
      ReportDialogs.showErrorDialog(context, 'Failed to submit report: $e');
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  Future<void> _logAnalyticsEvent(
    String eventName,
  ) async {
    await FirebaseAnalytics.instance.logEvent(
      name: eventName,
      parameters: {'type': 'breeding_site'},
    );
  }

  /// Gets the current page widget based on the current step
  Widget get _currentPage {
    // Step numbers are consistent:
    // 0: Site Type
    // 1: Photos
    // 2: Water
    // 3: Larvae (only if hasWater == true) OR Location (if hasWater == false)
    // 4: Location (if hasWater == true) OR Notes (if hasWater == false)
    // 5: Notes (only if hasWater == true)

    switch (_currentStep) {
      case 0:
        return SiteTypeSelectionPage(
          reportData: _reportData,
          onNext: _nextStep,
        );
      case 1:
        _logAnalyticsEvent('report_add_photo');
        return PhotoSelectionPage(
          photos: _reportData.photos,
          onPhotosChanged: _onPhotosChanged,
          onNext: _nextStep,
          onPrevious: _previousStep,
          maxPhotos: 3,
          minPhotos: 1,
          infoBadgeTextKey: 'camera_info_breeding_txt_02',
          thumbnailText:
              '(HC) Photos of the same breeding site from different angles.',
        );
      case 2:
        _logAnalyticsEvent('report_add_has_water');
        return WaterQuestionPage(
          reportData: _reportData,
          onNext: _nextStepAfterWater,
          onPrevious: _previousStep,
        );
      case 3:
        // This step depends on water status
        if (_reportData.hasWater == true) {
          // Show larvae question
          _logAnalyticsEvent('report_add_has_larvae');
          return LarvaeQuestionPage(
            reportData: _reportData,
            onNext: _nextStep,
            onPrevious: _previousStep,
          );
        } else {
          // Skip to location
          return _getLocationPage();
        }
      case 4:
        if (_reportData.hasWater == true) {
          // Location page after larvae
          return _getLocationPage();
        } else {
          // Notes page (final step when no water)
          return _getNotesPage();
        }
      case 5:
        // Notes page (final step when water is present)
        return _getNotesPage();
      default:
        return Container();
    }
  }

  Widget _getLocationPage() {
    _logAnalyticsEvent('report_add_location');
    return LocationSelectionPage(
      initialLatitude: _reportData.latitude,
      initialLongitude: _reportData.longitude,
      onLocationSelected: _onLocationSelected,
      onNext: _nextStep,
      onPrevious: _previousStep,
      canProceed: _reportData.latitude != null && _reportData.longitude != null,
      locationDescription: _reportData.locationDescription,
      locationSource: _reportData.locationSource,
    );
  }

  Widget _getNotesPage() {
    _logAnalyticsEvent('report_add_note');
    return NotesAndSubmitPage(
      initialNotes: _reportData.notes,
      onNotesChanged: _onNotesChanged,
      onSubmit: _submitReport,
      onPrevious: _previousStep,
      isSubmitting: _isSubmitting,
      submitLoadingText: '(HC) Submitting your breeding site report...',
    );
  }

  @override
  Widget build(BuildContext context) {
    final stepTitles = _stepTitles;
    final currentTitle = _currentStep < stepTitles.length
        ? stepTitles[_currentStep]
        : stepTitles.last;

    return Scaffold(
      appBar: AppBar(
        title: Text(currentTitle),
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
            totalSteps: stepTitles.length,
            stepTitles: stepTitles,
          ),

          // Main content
          Expanded(
            child: _currentPage,
          ),
        ],
      ),
    );
  }
}
