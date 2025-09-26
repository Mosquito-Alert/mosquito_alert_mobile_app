import 'package:flutter/material.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:mosquito_alert/mosquito_alert.dart' as sdk;
import 'package:provider/provider.dart';

import '../../../../utils/UserManager.dart';

class InAppReviewManager {
  static void requestInAppReview(BuildContext context) async {
    const int minimumReportsForReview = 3;

    try {
      // TODO: Get a single api endpoint to retrieve report count?
      final totalReports =
          await _getTotalReportCount(context, minimumReportsForReview);
      await _processReviewRequest(totalReports, minimumReportsForReview);
    } catch (e) {
      print('Error in requestInAppReview: $e');
    }
  }

  static Future<int> _getTotalReportCount(
      BuildContext context, int minimumRequired) async {
    final apiClient = Provider.of<sdk.MosquitoAlert>(context, listen: false);

    final apiFetchers = [
      (
        'observations',
        () => apiClient.getObservationsApi().listMine(pageSize: 4)
      ),
      ('bites', () => apiClient.getBitesApi().listMine(pageSize: 4)),
      (
        'breeding_sites',
        () => apiClient.getBreedingSitesApi().listMine(pageSize: 4)
      ),
    ];

    int totalReports = 0;

    for (final (apiName, fetcher) in apiFetchers) {
      try {
        final response = await fetcher();
        final data = response.data;
        if (data == null) continue;

        final count = (data as dynamic).count as int;

        if (count > 0) {
          totalReports += count;

          if (totalReports >= minimumRequired) {
            break;
          }
        }
      } catch (e) {
        print('Error fetching $apiName: $e');
      }
    }

    return totalReports;
  }

  static Future<void> _processReviewRequest(
      int numReports, int minimumReports) async {
    if (numReports < minimumReports) {
      return;
    }

    final now = DateTime.now().millisecondsSinceEpoch;
    final lastReportCount = await UserManager.getLastReportCount() ?? 0;
    final lastReviewRequest = await UserManager.getLastReviewRequest() ?? 0;

    var shouldRequestReview = (numReports == minimumReports ||
        numReports == minimumReports + 1 ||
        numReports >= lastReportCount + minimumReports ||
        now - lastReviewRequest >= 14 * 24 * 60 * 60 * 1000);

    if (!shouldRequestReview) {
      return;
    }

    final inAppReview = InAppReview.instance;

    if (await inAppReview.isAvailable()) {
      await inAppReview.requestReview();

      await UserManager.setLastReviewRequest(now);
      await UserManager.setLastReportCount(numReports);
    }
  }
}
