import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:mosquito_alert_app/features/bites/domain/models/bite_report.dart';
import 'package:mosquito_alert_app/features/reports/domain/models/report_detail_field.dart';
import 'package:mosquito_alert_app/features/bites/presentation/widgets/bite_stickman.dart';
import 'package:mosquito_alert_app/features/reports/presentation/pages/report_detail_page.dart';
import 'package:mosquito_alert_app/features/bites/presentation/state/bite_provider.dart';
import 'package:mosquito_alert_app/features/reports/presentation/widgets/report_detail_scaffold.dart';
import 'package:provider/provider.dart';

class BiteDetailPage extends ReportDetailPage<BiteReport> {
  const BiteDetailPage({Key? key, required BiteReport bite})
    : super(key: key, item: bite);

  @override
  _BiteDetailPageState createState() => _BiteDetailPageState();
}

class _BiteDetailPageState extends State<BiteDetailPage> {
  @override
  void initState() {
    super.initState();
    _logScreenView();
  }

  Future<void> _logScreenView() async {
    if (widget.item.uuid != null) {
      await FirebaseAnalytics.instance.logSelectContent(
        contentType: 'bite_report',
        itemId: widget.item.uuid!,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final String? locationEnvironment = widget.item.getLocalizedEnvironment(
      context,
    );
    final String? eventMoment = widget.item.getEventMoment(context);
    // Build the map only if locationEnvironment is not null
    final extraFields = <ReportDetailField>[];
    if (locationEnvironment != null) {
      extraFields.add(
        ReportDetailField(
          icon: Icons.not_listed_location,
          value: locationEnvironment,
        ),
      );
    }
    if (eventMoment != null) {
      extraFields.add(
        ReportDetailField(icon: Icons.av_timer, value: eventMoment),
      );
    }

    Widget topBarBackground = LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          color: Colors.white,
          child: SafeArea(
            child: Center(
              child: FittedBox(
                fit: BoxFit.contain,
                child: BiteStickMan(
                  headBites: widget.item.counts.head ?? 0,
                  leftHandBites: widget.item.counts.leftArm ?? 0,
                  rightHandBites: widget.item.counts.rightArm ?? 0,
                  chestBites: widget.item.counts.chest ?? 0,
                  leftLegBites: widget.item.counts.leftLeg ?? 0,
                  rightLegBites: widget.item.counts.rightLeg ?? 0,
                ),
              ),
            ),
          ),
        );
      },
    );

    return ReportDetailScaffold<BiteReport>(
      report: widget.item,
      provider: context.watch<BiteProvider>(),
      extraFields: extraFields,
      topBarBackground: topBarBackground,
    );
  }
}
