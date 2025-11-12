import 'package:flutter/material.dart';
import 'package:mosquito_alert_app/pages/settings_pages/location_consent_screen/permissions_explanation.dart';
import 'package:mosquito_alert_app/utils/MyLocalizations.dart';
import 'package:mosquito_alert_app/utils/style.dart';

class LocationConsentScreen extends StatelessWidget {
  const LocationConsentScreen({super.key});

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
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top text section
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
                style: TextStyle(
                  fontSize: 16,
                  color: theme.textTheme.bodyMedium?.color,
                ),
              ),
              const SizedBox(height: 16),

              // Expanded image fills remaining space
              Expanded(
                child: Center(
                  child: Image.asset(
                    'assets/img/location/grid_aid.png',
                    width: MediaQuery.of(context).size.width * 0.8,
                    fit: BoxFit.contain,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Fixed bottom buttons
              Row(
                children: [
                  Expanded(
                    child: Style.outlinedButton(
                      MyLocalizations.of(context, "no_show_info"),
                      () {
                        Navigator.pop(context);
                      },
                      key: Key("rejectBackgroundTrackingBtn"),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Style.button(
                      MyLocalizations.of(context, 'continue_txt'),
                      () async {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const BackgroundTrackingInfoScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
