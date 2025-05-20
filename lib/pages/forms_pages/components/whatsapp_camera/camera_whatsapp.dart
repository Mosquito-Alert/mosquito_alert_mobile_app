import 'dart:async';
import 'dart:io';

import 'package:camera_camera/camera_camera.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sliding_up_panel/flutter_sliding_up_panel.dart';
import 'package:mosquito_alert_app/utils/MyLocalizations.dart';
import 'package:photo_gallery/photo_gallery.dart';

class _WhatsAppCameraController extends ChangeNotifier {
  ///
  /// don't necessary to use this class
  /// this is the class to controller the actions
  ///
  _WhatsAppCameraController({this.multiple = true});

  /// permission to select multiple images
  ///
  /// multiple => default is true
  ///
  ///
  ///
  final bool multiple;
  final selectedImages = <File>[];
  var images = <Medium>[];

  Future<void> openGallery() async {
    final res = await FilePicker.platform.pickFiles(
      allowMultiple: multiple,
      type: FileType.image,
    );
    if (res != null) {
      for (var element in res.files) {
        if (element.path != null) selectedImages.add(File(element.path!));
      }
    }
  }

  void captureImage(File file) {
    selectedImages.add(file);
  }
}

class WhatsappCamera extends StatefulWidget {
  /// permission to select multiple images
  ///
  /// multiple => default is true
  ///
  ///
  ///how use:
  ///```dart
  ///List<File>? res = await Navigator.push(
  /// context,
  /// MaterialPageRoute(
  ///   builder: (context) => const WhatsappCamera()),
  ///);
  ///
  ///```
  ///
  final bool multiple;
  final String? infoBadgeTextKey;

  /// how use:
  ///```dart
  ///List<File>? res = await Navigator.push(
  /// context,
  /// MaterialPageRoute(
  ///   builder: (context) => const WhatsappCamera()),
  ///);
  ///
  ///```
  ///
  const WhatsappCamera({key, this.multiple = true, this.infoBadgeTextKey = ''});

  @override
  State<WhatsappCamera> createState() => _WhatsappCameraState();
}

class _WhatsappCameraState extends State<WhatsappCamera>
    with WidgetsBindingObserver {
  late _WhatsAppCameraController controller;
  final painel = SlidingUpPanelController();

  @override
  void dispose() {
    controller.dispose();
    painel.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      Navigator.pop(context);
    }
  }

  @override
  void initState() {
    super.initState();
    controller = _WhatsAppCameraController(multiple: widget.multiple);
    painel.addListener(() {
      if (painel.status.name == 'hidden') {
        controller.selectedImages.clear();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          CameraCamera(
            enableZoom: false,
            resolutionPreset: ResolutionPreset.high,
            cameraSide: CameraSide.front,
            onFile: (file) {
              controller.captureImage(file);
              Navigator.pop(context, controller.selectedImages);
            },
          ),
          onlyOneMosquitoBadge(context, widget),
          closeButton(context),
          galleryButton(context, controller),
        ],
      ),
    );
  }
}

Widget onlyOneMosquitoBadge(BuildContext context, dynamic widget) {
  return Visibility(
    visible: widget.infoBadgeTextKey != null,
    child: Align(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: const EdgeInsets.only(top: 70),
        child: Container(
            width: 0.5 * MediaQuery.of(context).size.width,
            decoration: BoxDecoration(
              color: Colors.orange.shade300,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              heightFactor: 1.5,
              child: Text(MyLocalizations.of(context, widget.infoBadgeTextKey),
                  style: TextStyle(color: Colors.white)),
            )),
      ),
    ),
  );
}

Widget closeButton(BuildContext context) {
  return Padding(
    padding: const EdgeInsets.only(top: 30),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          color: Colors.white,
          onPressed: (() => Navigator.pop(context)),
          icon: const Icon(Icons.close),
        ),
      ],
    ),
  );
}

Widget galleryButton(
    BuildContext context, _WhatsAppCameraController controller) {
  return SafeArea(
    minimum: const EdgeInsets.only(bottom: 0),
    child: Align(
      alignment: Alignment.bottomRight,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 32, right: 64),
        child: CircleAvatar(
          radius: 20,
          backgroundColor: Colors.black.withValues(alpha: 0.6),
          child: IconButton(
            color: Colors.white,
            onPressed: () async {
              await controller.openGallery().then((value) {
                if (controller.selectedImages.isNotEmpty) {
                  Navigator.pop(context, controller.selectedImages);
                }
              });
            },
            icon: const Icon(Icons.image),
          ),
        ),
      ),
    ),
  );
}
