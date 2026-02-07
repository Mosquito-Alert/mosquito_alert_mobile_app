import 'package:flutter/material.dart';
import 'package:mosquito_alert_app/features/onboarding/presentation/pages/location_consent_page.dart';
import 'package:mosquito_alert_app/features/onboarding/presentation/pages/terms_page.dart';
import 'package:mosquito_alert_app/features/auth/data/auth_repository.dart';
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
                      bool createdGuest = false;
                      try {
                        await onCompleted?.call();
                        createdGuest = true;
                      } catch (_) {
                        // Allow onboarding to complete offline and retry later.
                        await AuthRepository.setNeedsGuestAccount(true);
                      }

                      if (createdGuest) {
                        await AuthRepository.setNeedsGuestAccount(false);
                      } else {
                        ScaffoldMessenger.of(navigatorContext).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Offline. We will finish setup when you are online.',
                            ),
                            duration: Duration(seconds: 4),
                          ),
                        );
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
