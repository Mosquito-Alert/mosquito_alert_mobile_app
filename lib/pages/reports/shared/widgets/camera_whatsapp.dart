import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sliding_up_panel/flutter_sliding_up_panel.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mosquito_alert_app/utils/MyLocalizations.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:photo_manager/photo_manager.dart';

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
  var images = <AssetEntity>[];

  Future<void> loadRecentGalleryImages(BuildContext context) async {
    if (!(await isRecentPhotosFeatureEnabled(context))) {
      images.clear();
      notifyListeners();
      return;
    }

    final result = await PhotoManager.requestPermissionExtend();
    if (!result.hasAccess) return;

    try {
      final List<AssetPathEntity> albums = await PhotoManager.getAssetPathList(
        type: RequestType.image,
        onlyAll: true,
      );

      if (albums.isEmpty) return;

      final recentAlbum = albums.first;
      final List<AssetEntity> recentAssets =
          await recentAlbum.getAssetListRange(
        start: 0,
        end: 10,
      );

      images = recentAssets;
      notifyListeners();
    } catch (e) {
      print('Error loading gallery images: $e');
      images.clear();
      notifyListeners();
    }
  }

  Future<bool> isRecentPhotosFeatureEnabled(BuildContext context) async {
    return true;
  }

  Future<void> openGallery() async {
    final picker = ImagePicker();
    List<XFile> pickedImages = [];
    if (multiple) {
      pickedImages = await picker.pickMultiImage();
    } else {
      final singleImage = await picker.pickImage(source: ImageSource.gallery);
      if (singleImage != null) pickedImages.add(singleImage);
    }
    for (var xfile in pickedImages) {
      selectedImages.add(File(xfile.path));
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
  final panel = SlidingUpPanelController();
  bool _isCameraPermissionGranted = false;
  List<CameraDescription> _cameras = [];
  CameraController? _cameraController;
  Future<void>? _initializeControllerFuture;

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraController?.dispose();
    controller.dispose();
    panel.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _handlePermissionsOnResume();
    }
  }

  Future<void> _handlePermissionsOnResume() async {
    if (!mounted) return;

    final status = await Permission.camera.status;
    if (status.isGranted != _isCameraPermissionGranted && mounted) {
      setState(() {
        _isCameraPermissionGranted = status.isGranted;
      });
      if (status.isGranted && mounted) {
        await _initializeCamera();
        controller.loadRecentGalleryImages(context);
      }
    }
    if (mounted) {
      await _loadRecentPhotosIfPermissionGranted();
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    controller = _WhatsAppCameraController(multiple: widget.multiple);
    _requestCameraPermission();

    // Delay the photo loading slightly to ensure proper initialization
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadRecentPhotosIfPermissionGranted();
    });

    panel.addListener(() {
      if (panel.status.name == 'hidden') {
        controller.selectedImages.clear();
      }
    });
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      final backCamera = _cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => _cameras.first,
      );

      _cameraController = CameraController(
        backCamera,
        ResolutionPreset.high,
        enableAudio: false,
      );

      _initializeControllerFuture = _cameraController!
          .initialize()
          .timeout(const Duration(seconds: 3), onTimeout: () {
        print("Error: _initializeCamera timed out before it could initialize.");
        Navigator.pop(context);
      });
      setState(() {});
    } catch (e) {
      print('Camera error: $e');
    }
  }

  Future<void> _requestCameraPermission() async {
    final status = await Permission.camera.request();
    if (mounted) {
      setState(() {
        _isCameraPermissionGranted = status.isGranted;
      });
      if (status.isGranted) {
        await _initializeCamera();
        controller.loadRecentGalleryImages(context);
      }
    }
  }

  Future<void> _loadRecentPhotosIfPermissionGranted() async {
    if (!mounted) return;

    final result = await PhotoManager.requestPermissionExtend();
    if (result.hasAccess) {
      if (mounted) {
        controller.loadRecentGalleryImages(context);
        // Trigger a rebuild to show the recent photos strip immediately
        setState(() {});
      }
    }
  }

  Widget _buildCameraPermissionDeniedScreen() {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned(
            top: 40,
            left: 16,
            child: IconButton(
              icon: Icon(Icons.close, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  MyLocalizations.of(context, 'camera_permission_required'),
                  style: TextStyle(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () async {
                    if (await openAppSettings()) {
                      // Check permission status when returning from settings
                      if (mounted) {
                        await _handlePermissionsOnResume();
                      }
                    }
                  },
                  child: Text(MyLocalizations.of(context, 'open_settings')),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isCameraPermissionGranted) {
      return _buildCameraPermissionDeniedScreen();
    }

    if (_initializeControllerFuture == null) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          FutureBuilder<void>(
            future: _initializeControllerFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done) {
                return CameraPreview(_cameraController!);
              } else {
                return Center(child: CircularProgressIndicator());
              }
            },
          ),
          onlyOneMosquitoBadge(context, widget),
          closeButton(context),
          recentPhotosStrip(context, controller),
          cameraAndGalleryButtons(context, controller),
        ],
      ),
    );
  }

  Widget cameraAndGalleryButtons(
      BuildContext context, _WhatsAppCameraController controller) {
    return Positioned(
        bottom: 32 + MediaQuery.of(context).padding.bottom,
        left: 0,
        right: 0,
        child: Row(
          children: [
            Expanded(child: SizedBox()), // empty on the left
            captureImageButton(),
            Expanded(
              child: Align(
                alignment: Alignment.center,
                child: galleryButton(context, controller),
              ),
            ),
          ],
        ));
  }

  Widget captureImageButton() {
    return GestureDetector(
      onTap: _captureImage,
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
        ),
        child: Icon(Icons.camera_alt, color: Colors.black, size: 28),
      ),
    );
  }

  Future<void> _captureImage() async {
    try {
      await _initializeControllerFuture;
      final image = await _cameraController!.takePicture();

      final file = File(image.path);
      controller.captureImage(file);
      Navigator.pop(context, controller.selectedImages);
    } catch (e) {
      print('Error capturing image: $e');
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
                child: Text(
                    MyLocalizations.of(context, widget.infoBadgeTextKey),
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
    return GestureDetector(
      onTap: () async {
        final result = await PhotoManager.requestPermissionExtend();
        if (!result.hasAccess) {
          await openAppSettings();
          return;
        }

        if (result.hasAccess && mounted) {
          // Trigger a rebuild to show recent photos strip if it wasn't visible before
          setState(() {});
        }

        await controller.openGallery().then((_) {
          if (controller.selectedImages.isNotEmpty && mounted) {
            Navigator.pop(context, controller.selectedImages);
          }
        });
      },
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
        ),
        child: Icon(Icons.photo_library, color: Colors.black, size: 24),
      ),
    );
  }

  Widget recentPhotosStrip(
      BuildContext context, _WhatsAppCameraController controller) {
    return Positioned(
      bottom: 120 + MediaQuery.of(context).padding.bottom,
      left: 0,
      right: 0,
      child: Container(
        height: 90,
        child: AnimatedBuilder(
          animation: controller,
          builder: (context, _) {
            if (controller.images.isEmpty) {
              return Container();
            }
            return ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: controller.images.length,
              itemBuilder: (context, index) {
                final asset = controller.images[index];
                return FutureBuilder<Widget>(
                  future: _buildImage(context, controller, asset),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.done &&
                        snapshot.hasData) {
                      return snapshot.data!;
                    }
                    return Container();
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }

  Future<Widget> _buildImage(BuildContext context,
      _WhatsAppCameraController controller, AssetEntity asset) async {
    final Uint8List? thumbnailData = await asset.thumbnailDataWithSize(
      ThumbnailSize(200, 200),
      quality: 80,
    );

    if (thumbnailData == null) {
      return Container();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: GestureDetector(
        onTap: () async {
          final file = await asset.file;
          if (file != null) {
            controller.captureImage(file);
            Navigator.pop(context, controller.selectedImages);
          }
        },
        child: Container(
          width: 70,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white38, width: 1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.memory(
              thumbnailData,
              width: 70,
              height: 70,
              fit: BoxFit.cover,
            ),
          ),
        ),
      ),
    );
  }
}
