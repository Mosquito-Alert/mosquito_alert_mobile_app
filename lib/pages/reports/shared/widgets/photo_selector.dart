import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:mosquito_alert_app/pages/reports/shared/widgets/camera_whatsapp.dart';
import 'package:mosquito_alert_app/utils/MyLocalizations.dart';
import 'package:mosquito_alert_app/utils/style.dart';

class PhotoSelector extends StatefulWidget {
  final List<Uint8List> selectedPhotos;
  final VoidCallback onPhotosChanged;
  final int maxPhotos;
  final int minPhotos;
  final String? thumbnailText;
  final String? infoBadgeTextKey;

  const PhotoSelector({
    Key? key,
    required this.selectedPhotos,
    required this.onPhotosChanged,
    this.maxPhotos = 3,
    this.minPhotos = 1,
    this.thumbnailText,
    this.infoBadgeTextKey,
  }) : super(key: key);

  @override
  _PhotoSelectorState createState() => _PhotoSelectorState();
}

class _PhotoSelectorState extends State<PhotoSelector> {
  bool _hasRequestedInitialPhoto = false;
  int? _previewedPhotoIndex; // Index of the photo being displayed in preview

  @override
  void initState() {
    super.initState();
    // Auto-open camera when component loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_hasRequestedInitialPhoto && widget.selectedPhotos.isEmpty) {
        _pickPhoto();
      }
    });
    if (widget.selectedPhotos.isNotEmpty) {
      _previewedPhotoIndex = 0;
    }
  }

  Future<void> _pickPhoto() async {
    // Mark as requested if this is the initial photo request
    if (!_hasRequestedInitialPhoto && widget.selectedPhotos.isEmpty) {
      setState(() {
        _hasRequestedInitialPhoto = true;
      });
    }

    final List<Uint8List>? newFiles = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WhatsappCamera(
          multiple: false,
          infoBadgeTextKey: widget.infoBadgeTextKey,
        ),
      ),
    );

    if (newFiles != null && newFiles.isNotEmpty) {
      _addPhotos(newFiles);
    }
  }

  void _addPhotos(List<Uint8List> newFiles) {
    final availableSlots = widget.maxPhotos - widget.selectedPhotos.length;
    final photosToAdd = newFiles.take(availableSlots).toList();

    setState(() {
      widget.selectedPhotos.addAll(photosToAdd);
      // Update preview to show the last added photo
      if (photosToAdd.isNotEmpty) {
        _previewedPhotoIndex = widget.selectedPhotos.length - 1;
      }
    });

    widget.onPhotosChanged();
  }

  void _removePhoto(int index) {
    setState(() {
      widget.selectedPhotos.removeAt(index);
      // Adjust preview index if needed
      if (widget.selectedPhotos.isEmpty) {
        _previewedPhotoIndex = null;
      } else {
        _previewedPhotoIndex = widget.selectedPhotos.length - 1;
      }
    });

    widget.onPhotosChanged();
  }

  void _selectPreviewPhoto(int index) {
    setState(() {
      _previewedPhotoIndex = index;
    });
  }

  bool get _canAddMore => widget.selectedPhotos.length < widget.maxPhotos;

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(
        children: [
          // Image preview
          Expanded(
            flex: 1,
            child: Container(
              margin: EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                color: Colors.grey[200],
              ),
              child: _previewedPhotoIndex != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Image.memory(
                        widget.selectedPhotos[_previewedPhotoIndex!],
                        fit: BoxFit.contain,
                      ),
                    )
                  : Center(
                      child: Text(
                        MyLocalizations.of(context, 'no-photo-selected'),
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ),
            ),
          ),
          if (widget.thumbnailText != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 6.0),
              child: Text(
                widget.thumbnailText!, // safe because we checked != null
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
                textAlign: TextAlign.start,
              ),
            ),

          // Image thumbnails
          Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.center,
            children: [
              ...widget.selectedPhotos.map((photo) {
                int index = widget.selectedPhotos.indexOf(photo);
                bool isSelected =
                    index == _previewedPhotoIndex; // selected index

                return _buildThumbnailWidget(
                    photo: photo,
                    isSelected: isSelected,
                    onTap: () => _selectPreviewPhoto(index),
                    onRemoveTap: () => _removePhoto(index));
              }).toList(),
              if (_canAddMore)
                // Add photo button
                _buildAddPhotoWidget(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildThumbnailWidget({
    required Uint8List photo,
    required bool isSelected,
    required void Function() onTap,
    required void Function() onRemoveTap,
  }) {
    return GestureDetector(
        onTap: onTap,
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            // Thumbnail image
            Container(
              width: 80, // set item width
              height: 80,
              decoration: BoxDecoration(
                border: isSelected
                    ? Border.all(color: Style.colorPrimary, width: 3)
                    : null,
                borderRadius: BorderRadius.circular(15),
                image: DecorationImage(
                  image: MemoryImage(photo),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            // Remove button
            Container(
              margin: EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.9),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 3,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
              child: InkWell(
                onTap: onRemoveTap,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 18,
                  height: 18,
                  child: Icon(Icons.close, color: Colors.white, size: 12),
                ),
              ),
            ),
          ],
        ));
  }

  Widget _buildAddPhotoWidget() {
    return GestureDetector(
      onTap: _pickPhoto,
      child: SizedBox(
        width: 80,
        height: 80, // ensures square
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[400]!, width: 2),
            borderRadius: BorderRadius.circular(15),
            color: Colors.grey[50],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(Icons.add_a_photo, size: 30, color: Colors.grey[600]),
            ],
          ),
        ),
      ),
    );
  }
}
