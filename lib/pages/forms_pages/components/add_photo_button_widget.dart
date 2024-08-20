import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mosquito_alert_app/pages/forms_pages/components/whatsapp_camera.dart/camera_whatsapp.dart';
import 'package:mosquito_alert_app/utils/MyLocalizations.dart';
import 'package:mosquito_alert_app/utils/Utils.dart';
import 'package:mosquito_alert_app/utils/style.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class AddPhotoButton extends StatefulWidget {
  final bool isEditing;
  final bool photoRequired;
  final Function _atLeastOnePhotoAttached;
  final String? subtitleKey;
  final String? infoBadgeTextKey;

  AddPhotoButton(this.isEditing, this.photoRequired, this._atLeastOnePhotoAttached, this.subtitleKey, this.infoBadgeTextKey);

  @override
  _AddPhotoButtonState createState() => _AddPhotoButtonState();
}

class _AddPhotoButtonState extends State<AddPhotoButton> {
  List<String?> images = [];

  @override
  void initState() {
    _permissionsPath();
    super.initState();
    initializePhotos();
  }

  Future<void> initializePhotos() async {
    await _initImages();
    if (images.isEmpty){
      await getImageWhatsapp();
    }    
  }

  Future<void> _permissionsPath() async {
    var status = await Permission.storage.status;
    if (!status.isGranted) {
      await Permission.storage.request();
    }
  }

  Future<void> _initImages() async {
    if (Utils.imagePath != null && Utils.imagePath!.isNotEmpty) {
      Utils.imagePath!.forEach((element) async {
        if (element['id'] == Utils.report!.version_UUID) {
          if (element['image'].contains('http')) {
            var file = await urlToFile(element['image']);
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
    var tempDir = await getTemporaryDirectory();
    // get temporary path from temporary directory.
    var tempPath = tempDir.path;
    // create a new file in temporary path with random file name.
    var file = File('$tempPath' + (rng.nextInt(100)).toString() + '.png');
    // call http.get method and pass imageUrl into it to get response.
    var response = await http.get(Uri.parse(imageUrl));
    // write bodyBytes received in response to file.
    await file.writeAsBytes(response.bodyBytes);
    // now return the file which is created with random name in
    // temporary directory and image bytes from response is written to // that file.
    return file;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Style.title(MyLocalizations.of(context, 'bs_info_adult_title')),
          Visibility(
            visible: widget.subtitleKey != null,
            child: Style.body(MyLocalizations.of(context, widget.subtitleKey))
          ),
          SizedBox(height: 15),
          GridView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: min(3, images.length + 1),
            itemBuilder: (context, index) {
              return index == (images.length)
                ? GestureDetector(
                    onTap: () {
                      getImageWhatsapp();
                    },
                    child: Container(
                      decoration: BoxDecoration(
                          border: Border.all(color: Colors.black, width: 1),
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
                          ),
                        ),
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
            },
          ),
        ],
      ),
    );
  }

  void _deleteImage(String? img, int index) {
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

  Future<void> getImageWhatsapp() async{
    var files = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WhatsappCamera(
          multiple: false,
          infoBadgeTextKey: widget.infoBadgeTextKey,
        )
      ),
    );

    if(files == null){
      return;
    }

    var file = files[0];
    Utils.saveImgPath(file);
    setState(() {
      images.add(file.path);
    });
    widget._atLeastOnePhotoAttached();
  }
}
