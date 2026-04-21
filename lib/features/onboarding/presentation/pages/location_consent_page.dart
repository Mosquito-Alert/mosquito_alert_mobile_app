import 'package:flutter/material.dart';
import 'package:mosquito_alert_app/features/onboarding/presentation/pages/location_info_consent_page.dart';
import 'package:mosquito_alert_app/core/localizations/MyLocalizations.dart';
import 'package:mosquito_alert_app/core/utils/style.dart';

class LocationConsentPage extends StatelessWidget {
  final Future<void> Function()? onCompleted;

  const LocationConsentPage({super.key, this.onCompleted});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        title: Style.title(
          MyLocalizations.of(context, 'enable_background_tracking'),
          fontSize: 16,
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            spacing: 16,
            children: [
              Expanded(
                flex: 1,
                child: OutlinedButton(
                  child: Text(MyLocalizations.of(context, "no_show_info")),
                  onPressed: () async => await onCompleted?.call(),
                  key: const Key("rejectBackgroundTrackingBtn"),
                ),
              ),
              Expanded(
                flex: 2,
                child: FilledButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            LocationInfoConsentPage(onCompleted: onCompleted),
                      ),
                    );
                  },
                  child: Text(MyLocalizations.of(context, 'continue_txt')),
                ),
              ),
            ],
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                MyLocalizations.of(context, 'tutorial_title_13'),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: theme.primaryColorDark,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                MyLocalizations.of(context, 'tutorial_info_13'),
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              Center(
                child: Image.asset(
                  'assets/img/location/grid_aid.png',
                  width: MediaQuery.of(context).size.width * 0.8,
                  fit: BoxFit.contain,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
