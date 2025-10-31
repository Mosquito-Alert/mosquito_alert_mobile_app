import 'package:built_collection/built_collection.dart';
import 'package:dio/dio.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:mosquito_alert/mosquito_alert.dart';
import 'package:mosquito_alert_app/pages/reports/adult/widgets/dialogs.dart';
import 'package:mosquito_alert_app/pages/reports/shared/pages/location_selection_page.dart';
import 'package:mosquito_alert_app/pages/reports/shared/pages/notes_and_submit_page.dart';
import 'package:mosquito_alert_app/pages/reports/shared/pages/photo_selection_page.dart';
import 'package:mosquito_alert_app/pages/reports/shared/utils/report_dialogs.dart';
import 'package:mosquito_alert_app/pages/reports/shared/widgets/progress_indicator.dart';
import 'package:mosquito_alert_app/utils/UserManager.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import 'models/adult_report_data.dart';
import 'pages/environment_question_page.dart';

/// Main controller for the adult report workflow
/// Uses PageView slider architecture for step-by-step progression
class AdultReportController extends StatefulWidget {
  @override
  _AdultReportControllerState createState() => _AdultReportControllerState();
}

class _AdultReportControllerState extends State<AdultReportController> {
  late PageController _pageController;
  late AdultReportData _reportData;
  late ObservationsApi _observationsApi;
  late CampaignsApi _campaignsApi;

  int _currentStep = 0;
  bool _isSubmitting = false;

  // Define the events to log
  final List<String> _pageEvents = [
    'report_add_photo',
    'report_add_location',
    'report_add_environment',
    'report_add_note',
  ];

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
    final apiClient = Provider.of<MosquitoAlert>(context, listen: false);
    _observationsApi = apiClient.getObservationsApi();
    _campaignsApi = apiClient.getCampaignsApi();

    _logAnalyticsEvent('start_report');
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// Navigate to next step
  Future<void> _nextStep() async {
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

  void _onPageChanged(int index) async {
    // Check if the index is valid and log the event
    if (index >= 0 && index < _pageEvents.length) {
      await _logAnalyticsEvent(_pageEvents[index]);
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

  /// Submit the adult report via API
  Future<void> _submitReport() async {
    if (!_reportData.isValid || _isSubmitting) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      await _logAnalyticsEvent('submit_report');

      // Step 1: Create location request
      final locationRequest = LocationRequest((b) => b
        ..source_ = _reportData.locationSource
        ..point.latitude = _reportData.latitude!
        ..point.longitude = _reportData.longitude!);

      // Step 3: Process photos
      final List<MultipartFile> photos = [];
      final uuid = Uuid();
      for (final photo in _reportData.photos) {
        photos.add(await MultipartFile.fromBytes(photo,
            filename:
                '${uuid.v4()}.jpg', // NOTE: Filename is required by the API
            contentType: DioMediaType('image', 'jpeg')));
      }
      final photosRequest = BuiltList<MultipartFile>(photos);

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
        photos: photosRequest,
        note: notes,
        eventEnvironment: _reportData.environmentAnswer ?? '',
        eventMoment: _reportData.eventMoment ?? 'now',
        tags: tags,
      );

      if (response.statusCode == 201) {
        ReportDialogs.showSuccessDialog(
          context,
          onOkPressed: () async {
            Navigator.pop(context); // close the success dialog
            Country? country = response.data?.location.country;
            if (country == null) {
              Navigator.of(context).popUntil((route) => route.isFirst);
              return;
            }

            try {
              final campaignsResponse = await _campaignsApi.list(
                countryId: country.id,
                isActive: true,
                pageSize: 1,
                orderBy: ['-start_date'].build(),
              );
              final Campaign? campaign =
                  campaignsResponse.data?.results?.firstOrNull;
              if (campaign != null) {
                Dialogs.showAlertCampaign(
                  context,
                  campaign,
                  (context) => Navigator.of(context).popUntil((route) => route.isFirst),
                );
              } else {
                Navigator.of(context).popUntil((route) => route.isFirst);
              }
            } catch (e) {
              Navigator.of(context).popUntil((route) => route.isFirst);
            }
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

  Future<void> _logAnalyticsEvent(String eventName) async {
    await FirebaseAnalytics.instance.logEvent(
      name: eventName,
      parameters: {'type': 'adult'},
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
              onPageChanged: _onPageChanged,
              physics:
                  NeverScrollableScrollPhysics(), // Disable swipe navigation
              children: [
                PhotoSelectionPage(
                  photos: _reportData.photos,
                  onPhotosChanged: _onPhotosChanged,
                  onNext: _nextStep,
                  // No onPrevious for adult reports (first step)
                  maxPhotos: 3,
                  minPhotos: 1,
                  titleKey: 'bs_info_adult_title',
                  subtitleKey: 'ensure_single_mosquito_photos',
                  infoBadgeTextKey: 'one_mosquito_reminder_badge',
                ),
                LocationSelectionPage(
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
                EnvironmentQuestionPage(
                  reportData: _reportData,
                  onNext: _nextStep,
                  onPrevious: _previousStep,
                ),
                NotesAndSubmitPage(
                  initialNotes: _reportData.notes,
                  onNotesChanged: _onNotesChanged,
                  onSubmit: _submitReport,
                  onPrevious: _previousStep,
                  isSubmitting: _isSubmitting,
                  submitLoadingText: '(HC) Submitting your mosquito report...',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
