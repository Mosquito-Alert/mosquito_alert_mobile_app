import 'dart:typed_data';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:mosquito_alert/mosquito_alert.dart';
import 'package:mosquito_alert_app/features/breeding_sites/data/models/breeding_site_report_request.dart';
import 'package:mosquito_alert_app/features/breeding_sites/domain/models/breeding_site_report.dart';
import 'package:mosquito_alert_app/features/reports/domain/models/photo.dart';
import 'package:mosquito_alert_app/core/widgets/select_button.dart';
import 'package:mosquito_alert_app/core/widgets/step_page.dart';
import 'package:mosquito_alert_app/features/breeding_sites/presentation/state/breeding_site_provider.dart';
import 'package:mosquito_alert_app/features/reports/presentation/pages/report_create_page.dart';
import 'package:mosquito_alert_app/features/reports/presentation/widgets/report_creation_notes_step.dart';
import 'package:mosquito_alert_app/features/reports/presentation/widgets/report_creation_photo_selection.dart';
import 'package:mosquito_alert_app/features/reports/presentation/widgets/location_selector.dart';
import 'package:mosquito_alert_app/features/settings/presentation/state/settings_provider.dart';
import 'package:mosquito_alert_app/core/localizations/MyLocalizations.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

class BreedingSiteCreatePage extends StatefulWidget {
  @override
  _BreedingSiteCreatePageState createState() => _BreedingSiteCreatePageState();
}

class _BreedingSiteCreatePageState extends State<BreedingSiteCreatePage> {
  String title = '';

  final createdAt = DateTime.now().toUtc();
  final localId = Uuid().v4();

  static const Map<String, Object> analyticsParameters = {
    'report_type': 'breeding_site',
  };

  LocationRequest? location;
  String? notes;
  List<Uint8List> photos = [];
  BreedingSiteSiteTypeEnum? siteType;
  bool? hasWater;
  bool? hasLarvae;

  bool _isLocationLoading = false;

  Future<BreedingSiteReport> _handleSubmit(BuildContext context) async {
    final provider = context.read<BreedingSiteProvider>();
    final userTags = context.read<SettingsProvider>().hashtags;

    List<MemoryPhoto> memoryPhotos = [];
    for (final photo in photos) {
      memoryPhotos.add(MemoryPhoto(photo));
    }

    final breedingSite = await provider.createBreedingSite(
      request: BreedingSiteCreateRequest(
        localId: localId,
        createdAt: createdAt,
        location: location!,
        photos: memoryPhotos,
        note: notes,
        tags: userTags,
        siteType: siteType!,
        hasWater: hasWater,
        hasLarvae: hasWater == true ? hasLarvae : null,
      ),
    );
    return breedingSite;
  }

  Future<void> _logAnalyticsEvent(String eventName) async {
    await FirebaseAnalytics.instance.logEvent(
      name: eventName,
      parameters: analyticsParameters,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ReportCreatePage<BreedingSiteReport>(
      title: title,
      analyticsParameters: analyticsParameters,
      stepPages: [
        // Step 1: Breeding site question
        StepPage(
          canContinue: ValueNotifier<bool>(
            siteType != null &&
                (hasWater == false || (hasWater == true && hasLarvae != null)),
          ),
          onDisplay: () {
            _logAnalyticsEvent('report_add_site_type');
            setState(() {
              title = MyLocalizations.of(context, 'single_breeding_site');
            });
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Site type question
              Text(
                MyLocalizations.of(context, 'question_12'),
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              SelectButton<BreedingSiteSiteTypeEnum>(
                options: [
                  SelectButtonOptions(
                    value: BreedingSiteSiteTypeEnum.stormDrain,
                    title: MyLocalizations.of(
                      context,
                      'question_12_answer_121',
                    ),
                    icon: Image.asset(
                      'assets/img/ic_imbornal.webp',
                      fit: BoxFit.cover,
                      height: 100,
                    ),
                  ),
                  SelectButtonOptions(
                    value: BreedingSiteSiteTypeEnum.other,
                    title: MyLocalizations.of(
                      context,
                      'question_12_answer_122',
                    ),
                    icon: Image.asset(
                      'assets/img/ic_other_site.webp',
                      fit: BoxFit.cover,
                      height: 100,
                    ),
                  ),
                ],
                onChanged: (BreedingSiteSiteTypeEnum value) {
                  setState(() {
                    siteType = value;
                  });
                },
                initialSelection: siteType,
              ),
              // Has water question
              const SizedBox(height: 16),
              Text(
                MyLocalizations.of(context, 'question_10'),
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              SelectButton<bool>(
                options: [
                  SelectButtonOptions(
                    value: true,
                    title: MyLocalizations.of(
                      context,
                      'question_10_answer_101',
                    ),
                    icon: Icon(Icons.water_drop, size: 32, color: Colors.blue),
                  ),
                  SelectButtonOptions(
                    value: false,
                    title: MyLocalizations.of(
                      context,
                      'question_10_answer_102',
                    ),
                    icon: Icon(
                      Icons.water_drop_outlined,
                      size: 32,
                      color: Colors.grey,
                    ),
                  ),
                ],
                onChanged: (bool value) {
                  setState(() {
                    hasWater = value;
                    if (hasWater == false) {
                      hasLarvae = null;
                    }
                  });
                },
                initialSelection: hasWater,
              ),
              if (hasWater == true) ...[
                // Has larvae question
                const SizedBox(height: 16),
                Text(
                  MyLocalizations.of(context, 'question_17'),
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                SelectButton<bool>(
                  options: [
                    SelectButtonOptions(
                      value: true,
                      title: MyLocalizations.of(
                        context,
                        'question_10_answer_101',
                      ),
                      icon: Icon(Icons.grain, size: 32, color: Colors.red),
                    ),
                    SelectButtonOptions(
                      value: false,
                      title: MyLocalizations.of(
                        context,
                        'question_10_answer_102',
                      ),
                      icon: Icon(
                        Icons.grain_outlined,
                        size: 32,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                  onChanged: (bool value) {
                    setState(() {
                      hasLarvae = value;
                    });
                  },
                  initialSelection: hasLarvae,
                ),
              ],
            ],
          ),
        ),
        // Step 2: Photo selection
        StepPage(
          canContinue: ValueNotifier<bool>(photos.length >= 1),
          onDisplay: () {
            _logAnalyticsEvent('report_add_photos');
            setState(() {
              title = MyLocalizations.of(context, 'photos');
            });
          },
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          allowScroll: false,
          child: ReportCreationPhotoSelection(
            photos: photos,
            onPhotosChanged: (newPhotos) {
              setState(() {
                photos = newPhotos;
              });
            },
            maxPhotos: 3,
            infoBadgeTextKey: 'camera_info_breeding_txt_02',
            thumbnailText: MyLocalizations.of(
              context,
              'photos-of-same-breeding-site',
            ),
          ),
        ),
        // Step 3: Location selection
        StepPage(
          canContinue: ValueNotifier<bool>(
            !_isLocationLoading && location != null,
          ),
          onDisplay: () {
            _logAnalyticsEvent('report_add_location');
            setState(() {
              title = MyLocalizations.of(context, 'select-location');
            });
          },
          fullScreen: true,
          child: LocationSelector(
            initialLatitude: location?.point.latitude,
            initialLongitude: location?.point.longitude,
            onLocationChanged: (latitude, longitude, source) {
              setState(() {
                if (latitude == null || longitude == null || source == null) {
                  location = null;
                  return;
                }
                location = LocationRequest(
                  (b) => b
                    ..point.latitude = latitude
                    ..point.longitude = longitude
                    ..source_ = source,
                );
              });
            },
            onLoadingChanged: (isLoading) {
              setState(() {
                _isLocationLoading = isLoading;
              });
            },
          ),
        ),
        // Step 4: Notes and submit
        StepPage(
          canContinue: ValueNotifier<bool>(true),
          onDisplay: () {
            _logAnalyticsEvent('report_add_note');
            setState(() {
              title = MyLocalizations.of(context, 'notes');
            });
          },
          child: ReportCreationNotesStep(
            initialNotes: notes,
            onChange: (String? newNotes) {
              setState(() {
                notes = (newNotes?.trim().isEmpty ?? true)
                    ? null
                    : newNotes!.trim();
              });
            },
          ),
        ),
      ],
      onSubmit: (context) => _handleSubmit(context),
    );
  }
}
