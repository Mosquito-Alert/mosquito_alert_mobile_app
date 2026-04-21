import 'package:flutter/material.dart';
import 'package:mosquito_alert_app/features/reports/domain/models/photo.dart';

CarouselView buildPhotoCarousel({required List<BasePhoto> photos}) {
  return CarouselView(
    scrollDirection: Axis.horizontal,
    itemExtent: double.infinity,
    itemSnapping: true,
    padding: EdgeInsets.zero,
    shape: const BeveledRectangleBorder(),
    children: List<Widget>.generate(photos.length, (int index) {
      final photo = photos[index];
      return photo.buildWidget(size: double.infinity);
    }),
  );
}

Widget buildThumbnailImage({required BasePhoto? photo, double size = 40.0}) {
  Widget placeholderIcon(IconData icon) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      border: Border.all(color: Colors.grey[400]!, width: 2),
      borderRadius: BorderRadius.circular(8),
      color: Colors.grey[50],
    ),
    alignment: Alignment.center,
    child: Icon(icon, size: 20, color: Colors.grey[600]),
  );

  if (photo == null) {
    // Fallback to default icon
    return placeholderIcon(Icons.hide_image);
  }

  // Use the first photo from the report
  return ClipRRect(
    borderRadius: BorderRadius.circular(8),
    child: photo.buildWidget(size: 40.0),
  );
}
