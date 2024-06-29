import 'package:flutter/material.dart';
import 'package:intro_slider/intro_slider.dart';
import 'package:mosquito_alert_app/utils/MyLocalizations.dart';
import 'package:mosquito_alert_app/utils/style.dart';

class GalleryPage extends StatefulWidget {
  final Function goBackToHomepage;

  GalleryPage({required this.goBackToHomepage});

  @override
  _GalleryPageState createState() => _GalleryPageState();
}

class _GalleryPageState extends State<GalleryPage> {
  List<Slide> slides = [];

  @override
  void initState() {
    super.initState();
  }

  List<Slide> initSlides() {
    slides.add(Slide(
        title: '',
        description: MyLocalizations.of(context, 'gallery_info_01'),
        pathImage: 'assets/img/gallery/guia_1.png',
        backgroundImage: 'assets/img/gallery/guia_1.png'));
    slides.add(
      Slide(
        title: '',
        description: MyLocalizations.of(context, 'gallery_info_02'),
        pathImage: 'assets/img/gallery/guia_2.png',
      ),
    );
    slides.add(
      Slide(
        title: '',
        description: MyLocalizations.of(context, 'gallery_info_03'),
        pathImage: 'assets/img/gallery/guia_3.png',
      ),
    );
    slides.add(
      Slide(
        title: '',
        description: MyLocalizations.of(context, 'gallery_info_04'),
        pathImage: 'assets/img/gallery/guia_4.png',
      ),
    );
    slides.add(
      Slide(
        title: '',
        description: MyLocalizations.of(context, 'gallery_info_05'),
        pathImage: 'assets/img/gallery/guia_5.png',
      ),
    );
    slides.add(
      Slide(
        title: '',
        description: MyLocalizations.of(context, 'gallery_info_06'),
        pathImage: 'assets/img/gallery/guia_6.png',
      ),
    );
    slides.add(
      Slide(
        title: '',
        description: MyLocalizations.of(context, 'gallery_info_07'),
        pathImage: 'assets/img/gallery/guia_7.png',
      ),
    );
    slides.add(
      Slide(
        title: '',
        description: MyLocalizations.of(context, 'gallery_info_08'),
        pathImage: 'assets/img/gallery/guia_8.png',
      ),
    );
    slides.add(
      Slide(
        title: '',
        description: MyLocalizations.of(context, 'gallery_info_09'),
        pathImage: 'assets/img/gallery/guia_9.png',
      ),
    );
    slides.add(
      Slide(
        title: '',
        description: MyLocalizations.of(context, 'gallery_info_10'),
        pathImage: 'assets/img/gallery/guia_10.png',
      ),
    );
    slides.add(
      Slide(
        title: '',
        description: MyLocalizations.of(context, 'gallery_info_11'),
        pathImage: 'assets/img/gallery/guia_11.png',
      ),
    );
    return slides;
  }

  void onDonePress() {
    // Back to homepage
    widget.goBackToHomepage(0);
  }

  Widget renderNextBtn() {
    return Icon(
      Icons.navigate_next,
      color: Style.colorPrimary,
      size: 35.0,
    );
  }

  Widget renderDoneBtn() {
    return Icon(
      Icons.done,
      color: Style.colorPrimary,
    );
  }

  Widget renderSkipBtn() {
    return Icon(
      Icons.skip_next,
      color: Style.colorPrimary,
    );
  }

  List<Widget> renderListCustomTabs() {
    var tabs = <Widget>[];
    for (var i = 0; i < slides.length; i++) {
      var currentSlide = slides[i];
      tabs.add(Container(
        width: double.infinity,
        height: double.infinity,
        child: Container(
          margin: EdgeInsets.symmetric(vertical: 40),
          child: ListView(
            children: <Widget>[
              GestureDetector(
                  child: Image.asset(
                currentSlide.pathImage!,
                width: MediaQuery.of(context).size.width * 0.9,
                height: MediaQuery.of(context).size.height * 0.55,
                fit: BoxFit.contain,
              )),
              Container(
                margin: EdgeInsets.all(20.0),
                child: Text(
                  currentSlide.description!,
                  textAlign: TextAlign.center,
                  maxLines: 20,
                ),
              ),
            ],
          ),
        ),
      ));
    }
    return tabs;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IntroSlider(
        // List slides
        slides: initSlides(),

        // Skip button
        showSkipBtn: false,

        // Next button
        renderNextBtn: renderNextBtn(),

        // Done button
        renderDoneBtn: renderDoneBtn(),
        onDonePress: onDonePress,
        doneButtonStyle: ButtonStyle(
            backgroundColor:
            MaterialStateProperty.all(Style.colorPrimary.withOpacity(0.2)),
            overlayColor: MaterialStateProperty.all(Style.colorPrimary)),

        // Dot indicator
        colorDot: Style.colorPrimary.withOpacity(0.4),
        sizeDot: 6.0,
        colorActiveDot: Style.colorPrimary,
        // typeDotAnimation: dotSliderAnimation.SIZE_TRANSITION,

        // Tabs
        listCustomTabs: renderListCustomTabs(),
        backgroundColorAllSlides: Colors.white,

        // Show or hide status bar
        hideStatusBar: false,
      ),
    );
  }
}
