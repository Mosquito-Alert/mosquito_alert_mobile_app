import 'package:flutter/material.dart';
import 'package:mosquito_alert_app/core/widgets/step_page.dart';
import 'package:mosquito_alert_app/core/localizations/MyLocalizations.dart';

class StepPageContainer extends StatelessWidget {
  final StepPage child;
  final String? buttonText;
  final VoidCallback onContinue;

  const StepPageContainer({
    required this.child,
    required this.onContinue,
    this.buttonText,
  });

  @override
  Widget build(BuildContext context) {
    final continueButton = ValueListenableBuilder<bool>(
      valueListenable: child.canContinue,
      builder: (_, value, __) => FilledButton(
        child: Text(buttonText ?? MyLocalizations.of(context, 'continue_txt')),
        onPressed: value ? onContinue : null,
      ),
    );

    if (!child.fullScreen) {
      return SafeArea(
        child: Column(
          children: [
            Expanded(
              child: child.allowScroll
                  ? SingleChildScrollView(child: child)
                  : child,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: SizedBox(width: double.infinity, child: continueButton),
            ),
          ],
        ),
      );
    }
    // If fullscreen → overlay button on top of content
    return SafeArea(
      child: Stack(
        children: [
          Positioned.fill(child: child),

          // Positioned button at bottom
          Positioned(left: 16, right: 16, bottom: 16, child: continueButton),
        ],
      ),
    );
  }
}
