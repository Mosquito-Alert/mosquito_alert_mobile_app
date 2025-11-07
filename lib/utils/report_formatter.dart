import 'package:flutter/material.dart';
import 'package:mosquito_alert/mosquito_alert.dart';
import 'package:mosquito_alert_app/utils/MyLocalizations.dart';

class ObservationWidgets {
  final Observation observation;
  final BuildContext context;

  ObservationWidgets(this.context, this.observation);

  Text buildTitleText() {
    final title = _getTitleText(observation);
    final isItalic =
        observation.identification?.result?.taxon?.italicize ?? false;

    return Text(
      title,
      style: TextStyle(
        fontStyle: isItalic ? FontStyle.italic : FontStyle.normal,
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  String? getLocationEnvironment() {
    switch (observation.eventEnvironment) {
      case ObservationEventEnvironmentEnum.vehicle:
        return MyLocalizations.of(context, 'question_13_answer_131');
      case ObservationEventEnvironmentEnum.indoors:
        return MyLocalizations.of(context, 'question_13_answer_132');
      case ObservationEventEnvironmentEnum.outdoors:
        return MyLocalizations.of(context, 'question_13_answer_133');
      default:
        return null;
    }
  }

  String _getTitleText(Observation observation) {
    if (observation.identification == null) {
      return MyLocalizations.of(context, 'non_identified_specie');
    }

    // Navigate through nested nullable fields
    final identification = observation.identification;
    final result = identification?.result;
    final taxon = result?.taxon;
    final nameValue = taxon?.nameValue;

    if (nameValue == null || nameValue.isEmpty) {
      return MyLocalizations.of(context, 'non_identified_specie');
    }

    return nameValue;
  }
}

class BiteWidgets {
  final Bite bite;
  final BuildContext context;

  BiteWidgets(this.context, this.bite);

  Text buildTitleText() {
    final totalBites = bite.counts.total;
    String text;

    if (totalBites == 0) {
      text = MyLocalizations.of(context, 'no_bites');
    } else if (totalBites == 1) {
      text = '1 ${MyLocalizations.of(context, 'single_bite').toLowerCase()}';
    } else {
      text =
          '$totalBites ${MyLocalizations.of(context, 'plural_bite').toLowerCase()}';
    }

    return Text(text);
  }

  String? getLocationEnvironment() {
    switch (bite.eventEnvironment) {
      case BiteEventEnvironmentEnum.vehicle:
        return MyLocalizations.of(context, 'question_13_answer_131');
      case BiteEventEnvironmentEnum.indoors:
        return MyLocalizations.of(context, 'question_13_answer_132');
      case BiteEventEnvironmentEnum.outdoors:
        return MyLocalizations.of(context, 'question_13_answer_133');
      default:
        return null;
    }
  }

  String? getEventMoment() {
    switch (bite.eventMoment) {
      case BiteEventMomentEnum.now:
        return MyLocalizations.of(context, 'question_5_answer_51');
      case BiteEventMomentEnum.lastMorning:
        return MyLocalizations.of(context, 'question_3_answer_31');
      case BiteEventMomentEnum.lastMidday:
        return MyLocalizations.of(context, 'question_3_answer_32');
      case BiteEventMomentEnum.lastAfternoon:
        return MyLocalizations.of(context, 'question_3_answer_33');
      case BiteEventMomentEnum.lastNight:
        return MyLocalizations.of(context, 'question_3_answer_34');
      default:
        return null;
    }
  }
}

class BreedingSiteWidgets {
  final BreedingSite breedingSite;
  final BuildContext context;

  BreedingSiteWidgets(this.context, this.breedingSite);

  Text buildTitleText() {
    return Text(MyLocalizations.of(context, 'single_breeding_site'));
  }
}
