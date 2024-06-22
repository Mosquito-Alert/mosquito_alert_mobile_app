import 'dart:io';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';

enum ImageType { file, network, asset }

class ViewImage extends StatefulWidget {
  ///
  /// image path: network url, file path or asset
  ///
  final String image;

  ///
  /// define the image type
  ///
  final ImageType imageType;
  const ViewImage({
    key,
    required this.image,
    this.imageType = ImageType.file,
  });

  @override
  State<ViewImage> createState() => _ViewImageState();
}

class _ViewImageState extends State<ViewImage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
      ),
      backgroundColor: Colors.black,
      body: PhotoView(
        enablePanAlways: true,
        imageProvider: imageProvider,
        maxScale: 3.0,
      ),
    );
  }

  ImageProvider get imageProvider {
    if (widget.imageType == ImageType.file) {
      return FileImage(File(widget.image));
    } else if (widget.imageType == ImageType.network) {
      return NetworkImage(widget.image);
    } else {
      return AssetImage(widget.image);
    }
  }
}