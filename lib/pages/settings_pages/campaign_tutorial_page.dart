import 'package:flutter/material.dart';
import 'package:intro_slider/intro_slider.dart';
import 'package:intro_slider/slide_object.dart';
import 'package:mosquito_alert_app/utils/MyLocalizations.dart';
import 'package:mosquito_alert_app/utils/style.dart';

class CampaignTutorialPage extends StatefulWidget {
  @override
  _CampaignTutorialPageState createState() => _CampaignTutorialPageState();
}

class _CampaignTutorialPageState extends State<CampaignTutorialPage> {
  List<Slide> slides = [];

  Function goToTab;

  @override
  void initState() {
    super.initState();
  }

  List<Slide> initSlides() {
    slides.add(Slide(
        title: '',
        description: MyLocalizations.of(context, 'campaign_info_01'),
        pathImage: 'assets/img/gallery/guia_1.png',
        backgroundImage: 'assets/img/gallery/guia_1.png'));

    return slides;
  }

  void onDonePress() {
    // Back to the first tab
    // this.goToTab(0);
    Navigator.pop(context);
  }

  void onTabChangeCompleted(index) {
    // Index of current tab is focused
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
    List<Widget> tabs = new List();
    for (int i = 0; i < slides.length; i++) {
      Slide currentSlide = slides[i];
      tabs.add(Container(
        width: double.infinity,
        height: double.infinity,
        child: Container(
          margin: EdgeInsets.symmetric(vertical: 40),
          child: ListView(
            children: <Widget>[
              GestureDetector(
                  child: Image.asset(
                currentSlide.pathImage,
                width: MediaQuery.of(context).size.width * 0.9,
                height: MediaQuery.of(context).size.height * 0.55,
                fit: BoxFit.contain,
              )),
              // Container(
              //   child: Text(
              //     currentSlide.title,
              //     style: currentSlide.styleTitle,
              //     textAlign: TextAlign.center,
              //   ),
              //   margin: EdgeInsets.only(top: 20.0),
              // ),
              Container(
                child: Text(
                  currentSlide.description,
                  // style: currentSlide.styleDescription,
                  textAlign: TextAlign.center,
                  maxLines: 20,
                  // overflow: TextOverflow.ellipsis,
                ),
                margin: EdgeInsets.all(20.0),
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
      appBar: AppBar(
        backgroundColor: Colors.white,
        centerTitle: true,
        title: Style.title(MyLocalizations.of(context, 'campaign_tutorial_txt'),
            fontSize: 16),
      ),
      body: IntroSlider(
        // List slides
        slides: initSlides(),

        // Skip button

        isShowSkipBtn: false,

        // Next button
        renderNextBtn: renderNextBtn(),

        // Done button
        renderDoneBtn: renderDoneBtn(),
        onDonePress: onDonePress,
        colorDoneBtn: Style.colorPrimary.withOpacity(0.2),
        highlightColorDoneBtn: Style.colorPrimary,

        // Dot indicator
        colorDot: Style.colorPrimary.withOpacity(0.4),
        sizeDot: 6.0,
        colorActiveDot: Style.colorPrimary,
        // typeDotAnimation: dotSliderAnimation.SIZE_TRANSITION,

        // Tabs
        listCustomTabs: renderListCustomTabs(),
        backgroundColorAllSlides: Colors.white,
        refFuncGoToTab: (refFunc) {
          goToTab = refFunc;
        },

        // Show or hide status bar
        shouldHideStatusBar: false,

        // On tab change completed
        onTabChangeCompleted: onTabChangeCompleted,
      ),
    );
  }
}
