import 'dart:io';

import 'package:flutter/material.dart';
import 'package:mosquito_alert_app/pages/reports/shared/widgets/camera_whatsapp.dart';
import 'package:mosquito_alert_app/utils/MyLocalizations.dart';
import 'package:mosquito_alert_app/utils/style.dart';

class PhotoSelector extends StatefulWidget {
  final List<File> selectedPhotos;
  final VoidCallback onPhotosChanged;
  final int maxPhotos;
  final int minPhotos;
  final String? titleKey;
  final String? subtitleKey;
  final String? infoBadgeTextKey;

  const PhotoSelector({
    Key? key,
    required this.selectedPhotos,
    required this.onPhotosChanged,
    this.maxPhotos = 3,
    this.minPhotos = 1,
    this.titleKey = 'bs_info_adult_title',
    this.subtitleKey,
    this.infoBadgeTextKey = 'one_mosquito_reminder_badge',
  }) : super(key: key);

  @override
  _PhotoSelectorState createState() => _PhotoSelectorState();
}

class _PhotoSelectorState extends State<PhotoSelector> {
  bool _hasRequestedInitialPhoto = false;

  @override
  void initState() {
    super.initState();
    // Auto-open camera when component loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_hasRequestedInitialPhoto && widget.selectedPhotos.isEmpty) {
        _pickPhoto();
      }
    });
  }

  Future<void> _pickPhoto() async {
    // Check if we can add more photos
    if (widget.selectedPhotos.length >= widget.maxPhotos) {
      _showMaxPhotosAlert();
      return;
    }

    // Mark as requested if this is the initial photo request
    if (!_hasRequestedInitialPhoto && widget.selectedPhotos.isEmpty) {
      setState(() {
        _hasRequestedInitialPhoto = true;
      });
    }

    final List<File>? newFiles = await Navigator.push(
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

  void _addPhotos(List<File> newFiles) {
    final availableSlots = widget.maxPhotos - widget.selectedPhotos.length;
    final photosToAdd = newFiles.take(availableSlots).toList();

    setState(() {
      widget.selectedPhotos.addAll(photosToAdd);
    });

    widget.onPhotosChanged();

    if (newFiles.length > availableSlots) {
      _showMaxPhotosAlert();
    }
  }

  void _removePhoto(int index) {
    if (widget.selectedPhotos.length == widget.minPhotos) {
      _showMinPhotosAlert();
      return;
    }

    setState(() {
      widget.selectedPhotos.removeAt(index);
    });

    widget.onPhotosChanged();
  }

  void _showMaxPhotosAlert() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('(HC) Maximum ${widget.maxPhotos} photos allowed'),
        backgroundColor: Style.colorPrimary,
      ),
    );
  }

  void _showMinPhotosAlert() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('(HC) At least ${widget.minPhotos} photo required'),
        backgroundColor: Style.colorPrimary,
      ),
    );
  }

  bool get _canAddMore => widget.selectedPhotos.length < widget.maxPhotos;
  bool get _hasMinimumPhotos =>
      widget.selectedPhotos.length >= widget.minPhotos;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          if (widget.titleKey != null)
            Text(
              MyLocalizations.of(context, widget.titleKey!),
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

          // Subtitle
          if (widget.subtitleKey != null)
            Text(
              MyLocalizations.of(context, widget.subtitleKey!),
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),

          SizedBox(height: 15),

          // Photo count indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '(HC) Photos: ${widget.selectedPhotos.length}/${widget.maxPhotos}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color:
                      _hasMinimumPhotos ? Style.colorPrimary : Colors.red[700],
                ),
              ),
              if (!_hasMinimumPhotos)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '(HC) Required: ${widget.minPhotos} min',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.red[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),

          SizedBox(height: 12),

          // Photo grid
          GridView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: widget.selectedPhotos.length + (_canAddMore ? 1 : 0),
            itemBuilder: (context, index) {
              // Add photo button
              if (index == widget.selectedPhotos.length) {
                return GestureDetector(
                  onTap: _pickPhoto,
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[400]!, width: 2),
                      borderRadius: BorderRadius.circular(15),
                      color: Colors.grey[50],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_a_photo,
                          size: 30,
                          color: Colors.grey[600],
                        ),
                        SizedBox(height: 4),
                        Text(
                          '(HC) Add Photo',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              // Photo thumbnail
              final photo = widget.selectedPhotos[index];
              return Stack(
                alignment: Alignment.topRight,
                children: [
                  // Photo
                  Container(
                    height: double.infinity,
                    width: double.infinity,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: Image.file(
                        photo,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),

                  // Remove button
                  Container(
                    margin: EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 2,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                    child: IconButton(
                      onPressed: () => _removePhoto(index),
                      icon: Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 16,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: BoxConstraints(
                        minWidth: 28,
                        minHeight: 28,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),

          // Status message
          SizedBox(height: 16),
          if (widget.selectedPhotos.isEmpty)
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                border: Border.all(color: Colors.blue[200]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.camera_alt, color: Style.colorPrimary),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '(HC) Take clear photos of the mosquito (min ${widget.minPhotos}, max ${widget.maxPhotos})',
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                  ),
                ],
              ),
            )
          else if (_hasMinimumPhotos)
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green[50],
                border: Border.all(color: Colors.green[200]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: Style.colorPrimary),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '(HC) Great! You can continue or add more photos (${_canAddMore ? "${widget.maxPhotos - widget.selectedPhotos.length} more allowed" : "max reached"})',
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
