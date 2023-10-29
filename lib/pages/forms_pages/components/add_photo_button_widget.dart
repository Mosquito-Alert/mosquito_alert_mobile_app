import 'dart:io';
import 'dart:math';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:mosquito_alert_app/utils/MyLocalizations.dart';
import 'package:mosquito_alert_app/utils/Utils.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class AddPhotoButton extends StatefulWidget {
  final bool isEditing;
  final bool photoRequired;

  AddPhotoButton(this.isEditing, this.photoRequired);

  @override
  _AddPhotoButtonState createState() => _AddPhotoButtonState();
}

class _AddPhotoButtonState extends State<AddPhotoButton> {
  List<String?> images = [];

  @override
  void initState() {
    _permissionsPath();
    super.initState();
    // _chooseTypeImage();
    _initImages();
  }

  _permissionsPath() async {
    var status = await Permission.storage.status;
    if (!status.isGranted) {
      await Permission.storage.request();
    }
  }

  _initImages() async {
    if (Utils.imagePath != null && Utils.imagePath!.isNotEmpty) {
      Utils.imagePath!.forEach((element) async {
        if (element['id'] == Utils.report!.version_UUID) {
          if (element['image'].contains('http')) {
            File file = await urlToFile(element['image']);
            images.add(file.path);
            element['image'] = file.path;
          } else {
            images.add(element['image']);
          }
        }
        setState(() {});
      });
    }
  }

  Future<File> urlToFile(String imageUrl) async {
    // generate random number.
    var rng = Random();
    // get temporary directory of device.
    Directory tempDir = await getTemporaryDirectory();
    // get temporary path from temporary directory.
    String tempPath = tempDir.path;
    // create a new file in temporary path with random file name.
    File file = File('$tempPath' + (rng.nextInt(100)).toString() + '.png');
    // call http.get method and pass imageUrl into it to get response.
    http.Response response = await http.get(Uri.parse(imageUrl));
    // write bodyBytes received in response to file.
    await file.writeAsBytes(response.bodyBytes);
    // now return the file which is created with random name in
    // temporary directory and image bytes from response is written to // that file.
    return file;
  }

  @override
  Widget build(BuildContext context) {
    return images == null || images.isEmpty
        ? GestureDetector(
            onTap: () {
              _chooseTypeImage();
            },
            child: Card(
              margin: EdgeInsets.only(bottom: 15),
              elevation: 2,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              child: GestureDetector(
                onTap: () {
                  _chooseTypeImage();
                },
                child: Container(
                  height: 100,
                  width: 100,
                  decoration: BoxDecoration(
                      border: Border.all(color: Colors.black, width: 1),
                      borderRadius: BorderRadius.circular(15)),
                  child: Icon(
                    Icons.add,
                    size: 30,
                  ),
                ),
              ),
            ),
          )
        : Container(
            margin: EdgeInsets.only(bottom: 15),
            child: GridView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10),
                itemCount: min(3, images.length + 1),
                itemBuilder: (context, index) {
                  return index == (images.length)
                      ? GestureDetector(
                          onTap: () {
                            _chooseTypeImage();
                          },
                          child: Container(
                            decoration: BoxDecoration(
                                border:
                                    Border.all(color: Colors.black, width: 1),
                                borderRadius: BorderRadius.circular(15)),
                            child: Icon(
                              Icons.add,
                              size: 30,
                            ),
                          ),
                        )
                      : Stack(
                          alignment: Alignment.topLeft,
                          children: <Widget>[
                            Container(
                              height: double.infinity,
                              width: double.infinity,
                              child: ClipRRect(
                                  borderRadius: BorderRadius.circular(15),
                                  child: Image.file(
                                    File(images[index]!),
                                    fit: BoxFit.cover,
                                    height: 100,
                                    width: 100,
                                  )),
                            ),
                            Container(
                              height: double.infinity,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(15),
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.black54,
                                    Colors.transparent,
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.center,
                                ),
                              ),
                              child: Align(
                                alignment: Alignment.topLeft,
                                child: IconButton(
                                  onPressed: () {
                                    _deleteImage(images[index], index);
                                  },
                                  icon: Icon(
                                    Icons.close,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                }),
          );
  }

  _chooseTypeImage() {
    List<Widget> listForiOS = <Widget>[
      CupertinoActionSheetAction(
        onPressed: () {
          Navigator.pop(context);
          getGalleryImages();
        },
        child: Text(
          MyLocalizations.of(context, 'gallery')!,
          style: TextStyle(color: Colors.blue),
        ),
      ),
      CupertinoActionSheetAction(
        onPressed: () {
          if (Utils.report!.type == 'adult') {
            Utils.infoAdultCamera(context, getImage);
          } else if (Utils.report!.type == 'site') {
            Utils.infoBreedingCamera(context, getImage);
          }
          Navigator.pop(context);
        },
        child: Text(
          MyLocalizations.of(context, 'camara')!,
          style: TextStyle(color: Colors.blue),
        ),
      ),
      // CupertinoActionSheetAction(
      //   onPressed: () {
      //     Navigator.pop(context);
      //   },
      //   child: Text(
      //     MyLocalizations.of(context, 'continue_without_photo'),
      //     style: TextStyle(color: Colors.blue),
      //   ),
      // ),
    ];
    List<Widget> listForAndroid = <Widget>[
      InkWell(
        onTap: () {
          if (Utils.report!.type == 'adult') {
            Utils.infoAdultCamera(context, getImage);
          } else if (Utils.report!.type == 'site') {
            Utils.infoBreedingCamera(context, getImage);
          }
          Navigator.pop(context);
        },
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.all(20),
          child: Text(MyLocalizations.of(context, 'camara')!,
              style: TextStyle(color: Colors.blue, fontSize: 15)),
        ),
      ),
      Divider(height: 1.0),
      InkWell(
        onTap: () {
          Navigator.pop(context);
          getGalleryImages();
        },
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.all(20),
          child: Text(MyLocalizations.of(context, 'gallery')!,
              style: TextStyle(color: Colors.blue, fontSize: 15)),
        ),
      ),
      // Utils.report.type == 'adult'
      //     ? Column(
      //         children: <Widget>[
      //           Divider(height: 1.0),
      //           InkWell(
      //             onTap: () {
      //               Navigator.pop(context);
      //             },
      //             child: Container(
      //               width: double.infinity,
      //               padding: EdgeInsets.all(20),
      //               child: Text(
      //                   MyLocalizations.of(context, 'continue_without_photo'),
      //                   style: TextStyle(color: Colors.blue, fontSize: 15)),
      //             ),
      //           ),
      //         ],
      //       )
      //     : Container(),
    ];

    Utils.modalDetailTrackingforPlatform(
        Theme.of(context).platform == TargetPlatform.iOS
            ? listForiOS
            : listForAndroid,
        Theme.of(context).platform,
        context, () {
      Navigator.pop(context);
    }, title: '${MyLocalizations.of(context, 'bs_info_adult_title')}:');
  }

  _deleteImage(String? img, int index) {
    if (widget.photoRequired && images.length == 1) {
      Utils.showAlert(MyLocalizations.of(context, 'app_name'),
          MyLocalizations.of(context, 'photo_required_alert'), context);
    } else {
      Utils.deleteImage(img);
      setState(() {
        images.removeAt(index);
      });
    }
  }

  getGalleryImages() async {
    var newFiles = await FilePicker.platform.pickFiles(
      type: FileType.image,
    );
    List<String?> paths = [];

    if (newFiles != null &&
        newFiles.files != null &&
        newFiles.files.isNotEmpty) {
      newFiles.files.forEach((image) {
        Utils.saveImgPath(File(image.path!));
        paths.add(image.path);
      });

      setState(() {
        images = [...images, ...paths];
      });
    }    
  }

  Future getImage(source) async {
    if (await Permission.camera.isPermanentlyDenied && Platform.isIOS) {
      await openAppSettings();
      return;
    }

    final _picker = ImagePicker();
    var image = await _picker.getImage(
        source: source, maxHeight: 1024, imageQuality: 60);
    if (image != null) {
      final File file = File(image.path);
      Utils.saveImgPath(file);
      setState(() {
        images.add(image.path);
      });
    }
  }
}
