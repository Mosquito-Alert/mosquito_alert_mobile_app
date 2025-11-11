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
import 'package:mosquito_alert_app/utils/MyLocalizations.dart';
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

class PageParameter {
  final String titleKey;
  final String logEvent;
  final VoidCallback onPrevious;
  final bool Function() isShown;
  final Widget widget;

  PageParameter({
    required this.titleKey,
    required this.logEvent,
    required this.onPrevious,
    required this.isShown,
    required this.widget,
  });
}

class _BreedingSiteReportControllerState
    extends State<BreedingSiteReportController> {
  late PageController _pageController;
  late BreedingSiteReportData _reportData;
  late BreedingSitesApi _breedingSitesApi;

  int _currentStep = 0;
  bool _isSubmitting = false;

  List<PageParameter> get _pageParameters {
    return [
      PageParameter(
        titleKey: 'single_breeding_site',
        logEvent: 'report_add_site_type',
        onPrevious: () => null,
        isShown: () => true,
        widget: SiteTypeSelectionPage(
          reportData: _reportData,
          onNext: _nextStep,
        ),
      ),
      PageParameter(
        titleKey: 'photos',
        logEvent: 'report_add_photo',
        onPrevious: () => null,
        isShown: () => true,
        widget: PhotoSelectionPage(
          photos: _reportData.photos,
          onPhotosChanged: _onPhotosChanged,
          onNext: _nextStep,
          onPrevious: _previousStep,
          maxPhotos: 3,
          minPhotos: 1,
          infoBadgeTextKey: 'camera_info_breeding_txt_02',
          thumbnailText:
              MyLocalizations.of(context, 'photos-of-same-breeding-site'),
        ),
      ),
      PageParameter(
        titleKey: 'water-check',
        logEvent: 'report_add_has_water',
        onPrevious: () => null,
        isShown: () => true,
        widget: WaterQuestionPage(
          reportData: _reportData,
          onNext: _nextStep,
          onPrevious: _previousStep,
        ),
      ),
      PageParameter(
        titleKey: 'larvae-check',
        logEvent: 'report_add_has_larvae',
        onPrevious: () => _reportData.hasLarvae = null,
        isShown: () => _reportData.hasWater == true,
        widget: LarvaeQuestionPage(
          reportData: _reportData,
          onNext: _nextStep,
          onPrevious: _previousStep,
        ),
      ),
      PageParameter(
        titleKey: 'select-location',
        logEvent: 'report_add_location',
        onPrevious: () => null,
        isShown: () => true,
        widget: LocationSelectionPage(
          initialLatitude: _reportData.latitude,
          initialLongitude: _reportData.longitude,
          onLocationSelected: _onLocationSelected,
          onNext: _nextStep,
          onPrevious: _previousStep,
          canProceed:
              _reportData.latitude != null && _reportData.longitude != null,
          locationSource: _reportData.locationSource,
        ),
      ),
      PageParameter(
        titleKey: 'notes',
        logEvent: 'report_add_note',
        onPrevious: () => null,
        isShown: () => true,
        widget: NotesAndSubmitPage(
          initialNotes: _reportData.notes,
          onNotesChanged: _onNotesChanged,
          onSubmit: _submitReport,
          onPrevious: _previousStep,
          isSubmitting: _isSubmitting,
        ),
      ),
    ];
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _reportData = BreedingSiteReportData();

    // Initialize API
    final apiClient = Provider.of<MosquitoAlert>(context, listen: false);
    _breedingSitesApi = apiClient.getBreedingSitesApi();

    _logAnalyticsEvent('start_report');
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _nextStep() async {
    if (_currentStep < _pageParameters.length - 1) {
      setState(() {
        _currentStep++;
      });
      await _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  /// Navigate to previous step
  Future<void> _previousStep() async {
    if (_currentStep > 0) {
      _pageParameters[_currentStep].onPrevious();
      setState(() {
        _currentStep--;
      });
      await _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _onPageChanged(int index) async {
    // Update current step to match the page
    setState(() {
      _currentStep = index;
    });

    // Check if the index is valid and log the event
    if (index >= 0 && index < _pageParameters.length) {
      await _logAnalyticsEvent(_pageParameters[index].logEvent);
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

    try {
      await _logAnalyticsEvent('submit_report');

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

  void _handleBackPressed() {
    if (_currentStep > 0) {
      _previousStep();
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final _pages = _pageParameters.where((param) => param.isShown()).toList();
    final titles = _pages
        .map<String>((param) => MyLocalizations.of(context, param.titleKey))
        .toList();
    final widgets = _pages.map<Widget>((param) => param.widget).toList();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (!didPop) {
          _handleBackPressed();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(titles[_currentStep]),
          leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: _handleBackPressed,
          ),
          bottom: PreferredSize(
            child: ReportProgressIndicator(
              currentStep: _currentStep,
              totalSteps: titles.length,
            ),
            preferredSize: Size.fromHeight(0),
          ),
        ),
        body: PageView(
          controller: _pageController,
          onPageChanged: _onPageChanged,
          physics: NeverScrollableScrollPhysics(), // Disable swipe navigation
          children: widgets,
        ),
      ),
    );
  }
}
