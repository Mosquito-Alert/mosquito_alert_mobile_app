import 'dart:io';

import 'package:flutter/material.dart';
import 'package:mosquito_alert_app/pages/reports/shared/widgets/photo_selector.dart';
import 'package:mosquito_alert_app/utils/MyLocalizations.dart';

/// Shared photo selection page that can be used by any report workflow
/// Configurable PhotoSelector properties and navigation through callbacks
class PhotoSelectionPage extends StatefulWidget {
  final List<File> photos;
  final VoidCallback onPhotosChanged;
  final VoidCallback onNext;
  final VoidCallback?
      onPrevious; // Optional for workflows that don't need back button
  final int maxPhotos;
  final int minPhotos;
  final String? titleKey;
  final String? subtitleKey;
  final String? infoBadgeTextKey;

  const PhotoSelectionPage({
    Key? key,
    required this.photos,
    required this.onPhotosChanged,
    required this.onNext,
    this.onPrevious,
    this.maxPhotos = 3,
    this.minPhotos = 1,
    this.titleKey,
    this.subtitleKey,
    this.infoBadgeTextKey,
  }) : super(key: key);

  @override
  _PhotoSelectionPageState createState() => _PhotoSelectionPageState();
}

class _PhotoSelectionPageState extends State<PhotoSelectionPage> {
  bool get _canProceed => widget.photos.length >= widget.minPhotos;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Photo selector component
        Expanded(
          child: PhotoSelector(
            selectedPhotos: widget.photos,
            onPhotosChanged: widget.onPhotosChanged,
            maxPhotos: widget.maxPhotos,
            minPhotos: widget.minPhotos,
            titleKey: widget.titleKey,
            subtitleKey: widget.subtitleKey,
            infoBadgeTextKey: widget.infoBadgeTextKey,
          ),
        ),

        // Navigation buttons
        Container(
          padding: EdgeInsets.all(16),
          child: widget.onPrevious != null
              ? Row(
                  children: [
                    // Back button (only if onPrevious is provided)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: widget.onPrevious,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Theme.of(context).primaryColor,
                          side:
                              BorderSide(color: Theme.of(context).primaryColor),
                          padding: EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: Text('(HC) Back'),
                      ),
                    ),
                    SizedBox(width: 12),
                    // Continue button
                    Expanded(
                      flex: 2,
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
                )
              : SizedBox(
                  width: double.infinity,
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
        ),
      ],
    );
  }
}
