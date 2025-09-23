import 'package:flutter/material.dart';
import 'package:mosquito_alert_app/pages/reports/adult/models/adult_report_data.dart';
import 'package:mosquito_alert_app/pages/reports/adult/widgets/photo_selector.dart';
import 'package:mosquito_alert_app/utils/MyLocalizations.dart';

class PhotoSelectionPage extends StatefulWidget {
  final AdultReportData reportData;
  final VoidCallback onNext;

  const PhotoSelectionPage({
    Key? key,
    required this.reportData,
    required this.onNext,
  }) : super(key: key);

  @override
  _PhotoSelectionPageState createState() => _PhotoSelectionPageState();
}

class _PhotoSelectionPageState extends State<PhotoSelectionPage> {
  void _onPhotosChanged() {
    setState(() {
      // Trigger rebuild to update the continue button state
    });
  }

  bool get _canProceed => widget.reportData.photos.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Photo selector component
        Expanded(
          child: PhotoSelector(
            selectedPhotos: widget.reportData.photos,
            onPhotosChanged: _onPhotosChanged,
            maxPhotos: 3,
            minPhotos: 1,
            titleKey: 'bs_info_adult_title',
            subtitleKey: 'ensure_single_mosquito_photos',
            infoBadgeTextKey: 'one_mosquito_reminder_badge',
          ),
        ),

        // Continue button
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(16),
          child: ElevatedButton(
            onPressed: _canProceed ? widget.onNext : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 16),
              disabledBackgroundColor: Colors.grey[300],
            ),
            child: Text(
              MyLocalizations.of(context, 'continue_txt'),
              style: TextStyle(fontSize: 16),
            ),
          ),
        ),
      ],
    );
  }
}
