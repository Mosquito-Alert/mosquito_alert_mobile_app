import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:mosquito_alert/mosquito_alert.dart';
import 'package:mosquito_alert_app/features/bites/data/models/bite_report_request.dart';
import 'package:mosquito_alert_app/features/bites/domain/models/bite_report.dart';
import 'package:mosquito_alert_app/core/widgets/step_page.dart';
import 'package:mosquito_alert_app/features/bites/presentation/state/bite_provider.dart';
import 'package:mosquito_alert_app/features/bites/presentation/widgets/bite_creation_eventmoment_step.dart';
import 'package:mosquito_alert_app/features/reports/presentation/pages/report_create_page.dart';
import 'package:mosquito_alert_app/features/reports/presentation/widgets/report_creation_environment_step.dart';
import 'package:mosquito_alert_app/features/reports/presentation/widgets/report_creation_notes_step.dart';
import 'package:mosquito_alert_app/features/reports/presentation/widgets/location_selector.dart';
import 'package:mosquito_alert_app/features/settings/presentation/state/settings_provider.dart';
import 'package:mosquito_alert_app/core/localizations/MyLocalizations.dart';
import 'package:provider/provider.dart';
import 'package:mosquito_alert_app/features/bites/presentation/widgets/bite_stickman.dart';
import 'package:mosquito_alert_app/features/bites/domain/models/body_part.dart';
import 'package:uuid/uuid.dart';

class BiteCreatePage extends StatefulWidget {
  @override
  _BiteCreatePageState createState() => _BiteCreatePageState();
}

class _BiteCreatePageState extends State<BiteCreatePage> {
  String title = '';

  final createdAt = DateTime.now().toUtc();
  final localId = Uuid().v4();

  static const Map<String, Object> analyticsParameters = {
    'report_type': 'bite',
  };

  LocationRequest? location;
  BiteRequestEventEnvironmentEnum? eventEnvironment;
  BiteRequestEventMomentEnum? eventMoment;
  Map<BodyPartEnum, int> bites = {
    BodyPartEnum.head: 0,
    BodyPartEnum.chest: 0,
    BodyPartEnum.leftHand: 0,
    BodyPartEnum.rightHand: 0,
    BodyPartEnum.leftLeg: 0,
    BodyPartEnum.rightLeg: 0,
  };
  String? notes;

  bool _isLocationLoading = false;

  Future<BiteReport> _handleSubmit(BuildContext context) async {
    final provider = context.read<BiteProvider>();
    final userTags = context.read<SettingsProvider>().hashtags;

    final newBite = await provider.createBite(
      request: BiteCreateRequest(
        localId: localId,
        location: location!,
        createdAt: createdAt,
        eventEnvironment: eventEnvironment!,
        eventMoment: eventMoment!,
        counts: BiteCountsRequest(
          (b) => b
            ..head = bites[BodyPartEnum.head] ?? 0
            ..chest = bites[BodyPartEnum.chest] ?? 0
            ..leftArm = bites[BodyPartEnum.leftHand] ?? 0
            ..rightArm = bites[BodyPartEnum.rightHand] ?? 0
            ..leftLeg = bites[BodyPartEnum.leftLeg] ?? 0
            ..rightLeg = bites[BodyPartEnum.rightLeg] ?? 0,
        ),
        note: notes,
        tags: userTags,
      ),
    );
    return newBite;
  }

  Future<void> _logAnalyticsEvent(String eventName) async {
    await FirebaseAnalytics.instance.logEvent(
      name: eventName,
      parameters: analyticsParameters,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ReportCreatePage<BiteReport>(
      title: title,
      analyticsParameters: analyticsParameters,
      stepPages: [
        // Step 1: Bite questions
        StepPage(
          canContinue: ValueNotifier<bool>(
            bites.values.any((count) => count > 0),
          ),
          onDisplay: () {
            _logAnalyticsEvent('report_add_bites');
            setState(() {
              title = MyLocalizations.of(context, 'biting_report_txt');
            });
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                MyLocalizations.of(context, 'question_2'),
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              BiteStickMan(
                headBites: bites[BodyPartEnum.head] ?? 0,
                chestBites: bites[BodyPartEnum.chest] ?? 0,
                leftHandBites: bites[BodyPartEnum.leftHand] ?? 0,
                rightHandBites: bites[BodyPartEnum.rightHand] ?? 0,
                leftLegBites: bites[BodyPartEnum.leftLeg] ?? 0,
                rightLegBites: bites[BodyPartEnum.rightLeg] ?? 0,
                onChanged: (bodyPart, newCount) {
                  setState(() {
                    bites[bodyPart] = newCount;
                  });
                },
              ),
            ],
          ),
        ),
        // Step 2: Environment questions
        StepPage(
          canContinue: ValueNotifier<bool>(eventEnvironment != null),
          onDisplay: () {
            _logAnalyticsEvent('report_add_environment');
            setState(() {
              title = MyLocalizations.of(context, 'select_environment');
            });
          },
          child: ReportCreationEnvironmentStep(
            initialEnvironmentName: eventEnvironment != null
                ? eventEnvironment!.name
                : null,
            title: MyLocalizations.of(context, "question_4"),
            allowNullOption: true,
            onChanged: (value) {
              setState(() {
                eventEnvironment = value != null
                    ? BiteRequestEventEnvironmentEnum.valueOf(value)
                    : null;
              });
            },
          ),
        ),
        // Step 3: Moment questions
        StepPage(
          canContinue: ValueNotifier<bool>(eventMoment != null),
          onDisplay: () {
            _logAnalyticsEvent('report_add_moment');
            setState(() {
              title = MyLocalizations.of(context, 'select_environment');
            });
          },
          child: BiteCreationEventmomentStep(
            onChange: (value) {
              setState(() {
                eventMoment = value;
              });
            },
          ),
        ),
        // Step 4: Location selection
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
        // Step 5: Notes and submit
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
