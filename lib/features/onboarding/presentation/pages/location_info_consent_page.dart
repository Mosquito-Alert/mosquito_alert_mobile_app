import 'package:flutter/material.dart';
import 'package:mosquito_alert_app/features/fixes/presentation/state/fixes_provider.dart';
import 'package:mosquito_alert_app/features/fixes/services/permissions_manager.dart';
import 'package:mosquito_alert_app/core/localizations/MyLocalizations.dart';
import 'package:mosquito_alert_app/core/utils/style.dart';
import 'package:provider/provider.dart';

class LocationInfoConsentPage extends StatefulWidget {
  final Future<void> Function()? onCompleted;

  const LocationInfoConsentPage({super.key, this.onCompleted});

  @override
  State<LocationInfoConsentPage> createState() =>
      _LocationInfoConsentPageState();
}

class _LocationInfoConsentPageState extends State<LocationInfoConsentPage> {
  bool _isLoading = false;

  Future<void> _handleButtonPressed() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await PermissionsManager.requestPermissions();
      await widget.onCompleted?.call();
      final fixesProvider = context.read<FixesProvider>();
      await fixesProvider.enableTracking(runImmediately: true);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Stack(
      children: [
        Scaffold(
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
              child: FilledButton(
                child: Text(
                  MyLocalizations.of(context, 'turn_on_location_button'),
                ),
                onPressed: _isLoading ? null : _handleButtonPressed,
              ),
            ),
          ),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    MyLocalizations.of(context, 'tracking_perm_view_text'),
                    style: TextStyle(
                      fontSize: 16,
                      color: theme.textTheme.bodyMedium?.color,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        // Loader overlay
        if (_isLoading)
          Container(
            color: Colors.black45,
            alignment: Alignment.center,
            child: const CircularProgressIndicator(),
          ),
      ],
    );
  }
}
