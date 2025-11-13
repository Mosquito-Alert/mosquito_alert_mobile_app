import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';

/// Shared widgets for report detail pages
class ReportDetailWidgets {
  /// Builds a leading image widget for report lists
  /// Shows the first photo from the report or falls back to a default asset
  static Widget buildLeadingImage({
    required dynamic report,
  }) {
    const double size = 40.0;
    final photos = report.photos;

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

    if (photos.isEmpty) {
      // Fallback to default icon
      return placeholderIcon(Icons.hide_image);
    }

    // Use the first photo from the report
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: CachedNetworkImage(
        imageUrl: photos.first.url,
        width: size,
        height: size,
        fit: BoxFit.cover,
        placeholder: (context, url) => placeholderIcon(Icons.photo_camera),
        errorWidget: (context, url, error) => placeholderIcon(Icons.hide_image),
      ),
    );
  }

  static Widget? buildPhotoCarousel({
    required dynamic report,
  }) {
    if (report.photos.isEmpty) {
      return null;
    }

    return CarouselView(
      scrollDirection: Axis.horizontal,
      itemExtent: double.infinity,
      itemSnapping: true,
      padding: EdgeInsets.zero,
      shape: const BeveledRectangleBorder(),
      children: List<Widget>.generate(report.photos.length, (int index) {
        final photo = report.photos[index];
        return CachedNetworkImage(
          imageUrl: photo.url,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          placeholder: (context, url) => Container(
            color: Colors.white.withValues(alpha: 0.2),
            child: const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
          ),
          errorWidget: (context, url, error) => Container(
            color: Colors.white.withValues(alpha: 0.2),
            child: const Center(
              child: Icon(
                Icons.error,
                size: 60,
                color: Colors.white,
              ),
            ),
          ),
        );
      }),
    );
  }
}

/// Shared utility methods for report formatting
class ReportUtils {
  static String formatLocationCoordinates(dynamic report) {
    final point = report.location.point;
    return '${point.latitude.toStringAsFixed(5)}, ${point.longitude.toStringAsFixed(5)}';
  }

  /// Format location with city name or fallback to coordinates
  static Future<String> formatLocationWithCity(dynamic report) async {
    String? cityName;
    String? countryName;

    // 1. Try using administrative boundaries first
    final admBoundaries = report.location.admBoundaries;
    if (admBoundaries.isNotEmpty) {
      try {
        // Use the most specific administrative boundary available
        final cityBoundary = admBoundaries.firstWhere(
          (adm) => adm.level == 4 && adm.code == 'NUTS',
        );
        cityName = cityBoundary.nameValue;
      } catch (_) {
        // No city-level boundary found
      }
      countryName = report.location.country?.nameEn;
      if (cityName != null && countryName != null) {
        return '$cityName, $countryName';
      }
    }

    // 2. Use displayName if available (preferred human-readable name)
    final displayName = report.location.displayName;
    if (displayName != null && displayName.isNotEmpty) {
      final parts = displayName.split(',').map((p) => p.trim()).toList();
      if (parts.isNotEmpty) cityName = parts.first;
      if (parts.length > 1) countryName = parts.last;
      if (cityName != null && countryName != null) {
        return '$cityName, $countryName';
      }
    }

    // 3. Fallback: Reverse geocoding from coordinates
    final point = report.location.point;
    try {
      final placemarks =
          await placemarkFromCoordinates(point.latitude, point.longitude);
      if (placemarks.isNotEmpty) {
        final placemark = placemarks.first;
        cityName ??= placemark.locality?.trim();
        countryName ??= placemark.country?.trim();
        if (cityName != null && countryName != null) {
          return '$cityName, $countryName';
        }
      }
    } catch (e) {
      print('Error getting city name: $e');
    }

    // 4. Final fallback: just coordinates if no name found
    if (cityName != null && countryName != null)
      return '$cityName, $countryName';
    if (cityName != null) return cityName;
    if (countryName != null) return countryName;

    return formatLocationCoordinates(report);
  }

  static String? getHashtag(dynamic report) {
    final tags = report.tags;
    if (tags == null || tags.isEmpty) {
      return null;
    }
    // Join multiple tags with spaces, adding # prefix to each
    return tags.map((tag) => '#$tag').join(' ');
  }
}
