import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:mosquito_alert_app/features/reports/presentation/widgets/photo_selector.dart';

/// Shared photo selection page that can be used by any report workflow
/// Configurable PhotoSelector properties and navigation through callbacks
class ReportCreationPhotoSelection extends StatefulWidget {
  final List<Uint8List> photos;
  final Function(List<Uint8List>) onPhotosChanged;
  final VoidCallback?
  onPrevious; // Optional for workflows that don't need back button
  final int maxPhotos;
  final String? infoBadgeTextKey;
  final String? thumbnailText;

  const ReportCreationPhotoSelection({
    super.key,
    required this.photos,
    required this.onPhotosChanged,
    this.onPrevious,
    this.maxPhotos = 3,
    this.infoBadgeTextKey,
    this.thumbnailText,
  });

  @override
  State<ReportCreationPhotoSelection> createState() =>
      _ReportCreationPhotoSelectionState();
}

class _ReportCreationPhotoSelectionState
    extends State<ReportCreationPhotoSelection> {
  @override
  Widget build(BuildContext context) {
    return PhotoSelector(
      selectedPhotos: widget.photos,
      onPhotosChanged: widget.onPhotosChanged,
      maxPhotos: widget.maxPhotos,
      infoBadgeTextKey: widget.infoBadgeTextKey,
      thumbnailText: widget.thumbnailText,
    );
  }
}
