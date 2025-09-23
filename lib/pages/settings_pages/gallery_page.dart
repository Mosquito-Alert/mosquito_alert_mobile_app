import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart' as html;
import 'package:intro_slider/intro_slider.dart';
import 'package:markdown/markdown.dart';
import 'package:mosquito_alert_app/services/analytics_service.dart';
import 'package:mosquito_alert_app/utils/MyLocalizations.dart';
import 'package:mosquito_alert_app/utils/style.dart';

class GalleryPage extends StatefulWidget {
  final Function goBackToHomepage;
  final AnalyticsService? analyticsService;

  GalleryPage({
    required this.goBackToHomepage,
    this.analyticsService,
  });

  @override
  _GalleryPageState createState() => _GalleryPageState();
}

class _GalleryPageState extends State<GalleryPage> {
  List<Slide> slides = [];
  late AnalyticsService _analyticsService;

  @override
  void initState() {
    super.initState();
    _analyticsService = widget.analyticsService ?? FirebaseAnalyticsService();
    _logScreenView();
  }

  Future<void> _logScreenView() async {
    await _analyticsService.logScreenView(screenName: '/mosquito_guide');
  }

  List<Slide> initSlides() {
    slides.add(Slide(
        title: '',
        description: MyLocalizations.of(context, 'gallery_info_01'),
        pathImage: 'assets/img/gallery/guia_1.webp',
        backgroundImage: 'assets/img/gallery/guia_1.webp'));
    slides.add(
      Slide(
        title: '',
        description: MyLocalizations.of(context, 'gallery_info_02'),
        pathImage: 'assets/img/gallery/guia_2.webp',
      ),
    );
    slides.add(
      Slide(
        title: '',
        description: MyLocalizations.of(context, 'gallery_info_03'),
        pathImage: 'assets/img/gallery/guia_3.webp',
      ),
    );
    slides.add(
      Slide(
        title: '',
        description: MyLocalizations.of(context, 'gallery_info_04'),
        pathImage: 'assets/img/gallery/guia_4.webp',
      ),
    );
    slides.add(
      Slide(
        title: '',
        description: MyLocalizations.of(context, 'gallery_info_05'),
        pathImage: 'assets/img/gallery/guia_5.webp',
      ),
    );
    slides.add(
      Slide(
        title: '',
        description: MyLocalizations.of(context, 'gallery_info_06'),
        pathImage: 'assets/img/gallery/guia_6.webp',
      ),
    );
    slides.add(
      Slide(
        title: '',
        description: MyLocalizations.of(context, 'gallery_info_07'),
        pathImage: 'assets/img/gallery/guia_7.webp',
      ),
    );
    slides.add(
      Slide(
        title: '',
        description: MyLocalizations.of(context, 'gallery_info_08'),
        pathImage: 'assets/img/gallery/guia_8.webp',
      ),
    );
    slides.add(
      Slide(
        title: '',
        description: MyLocalizations.of(context, 'gallery_info_09'),
        pathImage: 'assets/img/gallery/guia_9.webp',
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

  List<Widget> renderListCustomTabs() {
    var tabs = <Widget>[];
    for (var i = 0; i < slides.length; i++) {
      var currentSlide = slides[i];
      tabs.add(Container(
        width: double.infinity,
        height: double.infinity,
        child: Container(
          margin: const EdgeInsets.only(bottom: 60.0),
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
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 0.0),
                    child: html.Html(
                      data: markdownToHtml(currentSlide.description!),
                    ),
                  )),
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
        slides: initSlides(),
        showSkipBtn: false,
        renderNextBtn: renderNextBtn(),
        renderDoneBtn: renderDoneBtn(),
        onDonePress: onDonePress,
        doneButtonStyle: ButtonStyle(
            backgroundColor: WidgetStateProperty.all(
                Style.colorPrimary.withValues(alpha: 0.2)),
            overlayColor: WidgetStateProperty.all(Style.colorPrimary)),
        colorDot: Style.colorPrimary.withValues(alpha: 0.4),
        sizeDot: 6.0,
        colorActiveDot: Style.colorPrimary,
        listCustomTabs: renderListCustomTabs(),
        backgroundColorAllSlides: Colors.white,
        hideStatusBar: false,
        prevButtonStyle: ButtonStyle(
            foregroundColor: WidgetStateProperty.all(Style.colorPrimary),
            overlayColor: WidgetStateProperty.all(Style.colorPrimary)),
      ),
    );
  }
}
