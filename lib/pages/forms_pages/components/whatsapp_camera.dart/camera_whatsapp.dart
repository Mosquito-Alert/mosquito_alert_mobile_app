import 'dart:async';
import 'dart:io';

import 'package:camera_camera/camera_camera.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sliding_up_panel/flutter_sliding_up_panel.dart';
import 'package:mosquito_alert_app/pages/forms_pages/components/whatsapp_camera.dart/view_image.dart';
import 'package:mosquito_alert_app/utils/MyLocalizations.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:photo_gallery/photo_gallery.dart';
import 'package:file_picker/file_picker.dart';


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

  Future<bool> handlerPermissions() async {
    final status = await Permission.storage.request();
    if (Platform.isIOS) {
      await Permission.photos.request();
      await Permission.mediaLibrary.request();
    }
    return status.isGranted;
  }

  bool imageIsSelected(String? fileName) {
    final index =
        selectedImages.indexWhere((e) => e.path.split('/').last == fileName);
    return index != -1;
  }

  _timer() {
    Timer.periodic(const Duration(seconds: 2), (t) async {
      await Permission.camera.isGranted.then((value) {
        if (value) {
          getPhotosToGallery();
          t.cancel();
        }
      });
    });
  }

  Future<void> getPhotosToGallery() async {
    final permission = await handlerPermissions();
    if (permission) {
      final albums = await PhotoGallery.listAlbums(
        mediumType: MediumType.image,
      );
      final res = await Future.wait(albums.map((e) => e.listMedia()));
      final index = res.indexWhere((e) => e.album.name == 'All');
      if (index != -1) images.addAll(res[index].items);
      if (index == -1) {
        for (var e in res) {
          images.addAll(e.items);
        }
      }
      notifyListeners();
    }
  }

  Future<void> initialize() async {
    _timer();
  }

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

  Future<void> selectImage(Medium image) async {
    if (multiple) {
      final index = selectedImages
          .indexWhere((e) => e.path.split('/').last == image.filename);
      if (index != -1) {
        selectedImages.removeAt(index);
      } else {
        final file = await image.getFile();
        selectedImages.add(file);
      }
    } else {
      selectedImages.clear();
      final file = await image.getFile();
      selectedImages.add(file);
    }
    notifyListeners();
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          SizedBox(
            width: MediaQuery.of(context).size.width,
            child: CameraCamera(
              enableZoom: false,
              resolutionPreset: ResolutionPreset.high,
              cameraSide: CameraSide.front,
              onFile: (file) {
                controller.captureImage(file);
                Navigator.pop(context, controller.selectedImages);
              },
            ),
          ),
          Visibility(
            visible: widget.infoBadgeTextKey != null,
            child:Align(
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
                  )
                ),
              ),
            ),
          ),
          Padding(
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
          ),
          Align(
            alignment: Alignment.bottomRight,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 32, right: 64),
              child: CircleAvatar(
                radius: 20,
                backgroundColor: Colors.black.withOpacity(0.6),
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
          Positioned(
            bottom: 96,
            left: 0.0,
            right: 0.0,
            child: GestureDetector(
              dragStartBehavior: DragStartBehavior.down,
              onVerticalDragStart: (details) => painel.expand(),
              child: SizedBox(
                height: 120,
                child: AnimatedBuilder(
                    animation: controller,
                    builder: (context, child) {
                      return Column(
                        children: [
                          if (controller.images.isNotEmpty)
                            const RotatedBox(
                              quarterTurns: 1,
                              child: Icon(
                                Icons.arrow_back_ios,
                                color: Colors.white,
                              ),
                            ),
                          Expanded(
                            child: ListView.builder(
                              itemCount: controller.images.length,
                              physics: const BouncingScrollPhysics(),
                              scrollDirection: Axis.horizontal,
                              itemBuilder: (context, index) {
                                return InkWell(
                                  onTap: () async {
                                    await controller
                                        .selectImage(controller.images[index])
                                        .then((value) {
                                      Navigator.pop(
                                        context,
                                        controller.selectedImages,
                                      );
                                    });
                                  },
                                  child: Container(
                                    height: 100,
                                    width: 100,
                                    margin: const EdgeInsets.symmetric(
                                        horizontal: 5),
                                    decoration: BoxDecoration(
                                      image: DecorationImage(
                                        fit: BoxFit.cover,
                                        isAntiAlias: true,
                                        filterQuality: FilterQuality.high,
                                        image: ThumbnailProvider(
                                          highQuality: true,
                                          mediumId: controller.images[index].id,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      );
                    }
                  ),
              ),
            ),
          ),
          Center(
            child: SlidingUpPanelWidget(
              controlHeight: 0,
              panelController: painel,
              child: AnimatedBuilder(
                  animation: controller,
                  builder: (context, child) {
                    return _ImagesPage(
                      controller: controller,
                      close: () {
                        painel.hide();
                      },
                      done: () {
                        if (controller.selectedImages.isNotEmpty) {
                          Navigator.pop(context, controller.selectedImages);
                        } else {
                          painel.hide();
                        }
                      },
                    );
                  }),
            ),
          )
        ],
      ),
    );
  }
}

class _ImagesPage extends StatefulWidget {
  final _WhatsAppCameraController controller;

  ///
  /// close action
  /// how use:
  /// ```dart
  /// close: () {
  ///   //pop painel
  /// }
  /// ```
  ///
  final void Function()? close;

  ///
  /// done action
  /// how use:
  /// ```dart
  /// done: () {
  ///   //send images
  /// }
  /// ```
  ///
  final void Function()? done;

  ///
  ///
  /// this is thi page of swipe to up
  /// and show the images of gallery
  /// don`t is necessary your implementation by the final programmer
  ///
  ///
  const _ImagesPage({
    required this.controller,
    required this.close,
    required this.done,
  });

  @override
  State<_ImagesPage> createState() => __ImagesPageState();
}

class __ImagesPageState extends State<_ImagesPage> {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      height: MediaQuery.of(context).size.height - 40,
      child: Column(
        children: [
          Container(
            height: 40,
            decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(15),
                  topRight: Radius.circular(15),
                )),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: widget.close?.call,
                  icon: const Icon(Icons.close),
                ),
                if (widget.controller.multiple)
                  Text(widget.controller.selectedImages.length.toString()),
                IconButton(
                  onPressed: widget.done?.call,
                  icon: const Icon(Icons.check),
                )
              ],
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 5),
              itemCount: widget.controller.images.length,
              physics: const BouncingScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisExtent: 140,
                crossAxisSpacing: 5,
                mainAxisSpacing: 5,
                childAspectRatio: MediaQuery.of(context).size.width /
                    (MediaQuery.of(context).size.height / 4),
              ),
              itemBuilder: (context, index) {
                return InkWell(
                  onTap: () => widget.controller
                      .selectImage(widget.controller.images[index]),
                  child: _ImageItem(
                    selected: widget.controller.imageIsSelected(
                      widget.controller.images[index].filename,
                    ),
                    image: widget.controller.images[index],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ImageItem extends StatelessWidget {
  ///
  /// medium image
  /// is formatter usage for package: photo_gallery
  /// this package list all images of device
  ///
  final Medium image;

  ///
  /// where selected is true, apply a check in the image
  ///
  final bool selected;

  ///
  ///this widget is usage how itemBuilder of painel: _ImagesPage
  ///
  const _ImageItem({required this.image, required this.selected});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      child: Stack(
        children: [
          Hero(
            tag: image.id,
            child: Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  fit: BoxFit.cover,
                  filterQuality: FilterQuality.high,
                  image: ThumbnailProvider(
                    mediumId: image.id,
                    highQuality: true,
                    height: 150,
                    width: 150,
                    mediumType: MediumType.image,
                  ),
                ),
              ),
            ),
          ),
          if (selected)
            Container(
              color: Colors.grey.withOpacity(.3),
              child: Center(
                child: Stack(
                  children: [
                    const Icon(
                      Icons.done,
                      size: 52,
                      color: Colors.white,
                    ),
                    Icon(
                      Icons.done,
                      size: 50,
                      color: Theme.of(context).primaryColor,
                    ),
                  ],
                ),
              ),
            ),
          Align(
            alignment: Alignment.topRight,
            child: IconButton(
              color: Colors.white,
              icon: const Icon(Icons.zoom_out_map_outlined),
              onPressed: () async {
                await image.getFile().then((value) {
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) {
                      return Hero(
                        tag: image.id,
                        child: ViewImage(image: value.path),
                      );
                    },
                  ));
                });
              },
            ),
          )
        ],
      ),
    );
  }
}