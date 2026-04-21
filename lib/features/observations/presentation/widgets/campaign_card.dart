import 'package:flutter/material.dart';
import 'package:mosquito_alert/mosquito_alert.dart';
import 'package:mosquito_alert_app/features/observations/domain/models/observation_report.dart';
import 'package:mosquito_alert_app/screens/settings_pages/campaign_tutorial_page.dart';
import 'package:mosquito_alert_app/core/localizations/MyLocalizations.dart';
import 'package:mosquito_alert_app/core/utils/style.dart';

class CampaignCard extends StatelessWidget {
  final Campaign campaign;
  final ObservationReport observation;

  const CampaignCard({
    Key? key,
    required this.campaign,
    required this.observation,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      style: const TextStyle(fontSize: 16, color: Colors.black),
                      children: [
                        TextSpan(
                          text:
                              MyLocalizations.of(
                                context,
                                "alert_campaing_found_title",
                              ) +
                              " ",
                        ),
                        TextSpan(
                          text: observation.shortId,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    softWrap: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              campaign.postingAddress,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CampaignTutorialPage(),
                    ),
                  );
                },
                style: TextButton.styleFrom(
                  foregroundColor: Style.colorPrimary,
                ),
                child: Text(
                  MyLocalizations.of(context, "show_info"),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
