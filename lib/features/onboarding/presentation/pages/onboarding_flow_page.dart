import 'package:flutter/material.dart';
import 'package:mosquito_alert_app/features/onboarding/presentation/pages/location_consent_page.dart';
import 'package:mosquito_alert_app/features/onboarding/presentation/pages/terms_page.dart';
import 'package:provider/provider.dart';

import '../state/onboarding_provider.dart';

class OnboardingFlowPage extends StatelessWidget {
  final Future<void> Function()? onCompleted;

  const OnboardingFlowPage({super.key, this.onCompleted});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OnboardingProvider>();

    if (provider.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (provider.isCompleted) {
      // Already completed
      return const SizedBox.shrink();
    }

    // ====== BEGIN ONBOARDING FLOW ======

    return Navigator(
      onGenerateRoute: (_) {
        return MaterialPageRoute(
          builder: (navigatorContext) => TermsPage(
            onAccepted: () async {
              Navigator.push(
                navigatorContext,
                MaterialPageRoute(
                  builder: (navigatorContext) => LocationConsentPage(
                    onCompleted: () async {
                      try {
                        await onCompleted?.call();
                      } catch (e) {
                        ScaffoldMessenger.of(navigatorContext).showSnackBar(
                          SnackBar(
                            content: Text(e.toString()),
                            backgroundColor: Colors.red,
                            duration: const Duration(seconds: 4),
                          ),
                        );
                        return;
                      }
                      await provider.completeOnboarding();
                    },
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
