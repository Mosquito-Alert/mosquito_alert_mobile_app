import 'package:flutter/material.dart';
import 'package:mosquito_alert_app/utils/BackgroundTracking.dart';
import 'package:mosquito_alert_app/utils/MyLocalizations.dart';
import 'package:mosquito_alert_app/utils/style.dart';

class BackgroundTrackingInfoScreen extends StatelessWidget {
  const BackgroundTrackingInfoScreen({super.key});

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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildBodyText(context, theme),
              _buildEnableButton(context, theme),
            ],
          ),
        ),
      ),
    );
  }
}

Widget _buildBodyText(BuildContext context, ThemeData theme) {
  return Text(
    MyLocalizations.of(context, 'tracking_perm_view_text'),
    style: TextStyle(fontSize: 16, color: theme.textTheme.bodyMedium?.color),
  );
}

Widget _buildEnableButton(BuildContext context, ThemeData theme) {
  return Row(
    children: [
      Expanded(
        child: ElevatedButton(
          onPressed: () => _onEnableTracking(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.primaryColorDark,
            foregroundColor: Colors.white,
          ),
          child: Text(MyLocalizations.of(
            context,
            'turn_on_location_button',
          )),
        ),
      ),
    ],
  );
}

Future<void> _onEnableTracking(BuildContext context) async {
  // Show loading dialog
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => const Center(child: CircularProgressIndicator()),
  );

  // Start background tracking
  try {
    await BackgroundTracking.start(
      shouldRun: true,
      requestPermissions: true,
    );
  } finally {
    if (context.mounted) {
      Navigator.of(context, rootNavigator: true).pop();
    }
  }

  if (context.mounted) {
    // Return to home view (first in stack)
    Navigator.popUntil(context, (route) => route.isFirst);
  }
}
