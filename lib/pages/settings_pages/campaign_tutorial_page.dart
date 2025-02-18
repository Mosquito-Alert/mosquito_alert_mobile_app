import 'package:flutter/material.dart';
import 'package:intro_slider/intro_slider.dart';
import 'package:mosquito_alert_app/utils/MyLocalizations.dart';
import 'package:mosquito_alert_app/utils/style.dart';

class CampaignTutorialPage extends StatefulWidget {
  final bool? fromReport;

  CampaignTutorialPage({this.fromReport});

  @override
  _CampaignTutorialPageState createState() => _CampaignTutorialPageState();
}

class _CampaignTutorialPageState extends State<CampaignTutorialPage> {
  List<Slide> slides = [];

  Function? goToTab;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_outlined),
          onPressed: () {
          if (widget.fromReport != null && widget.fromReport!) {
            Navigator.popUntil(context, (route) => route.isFirst);
          } else {
            Navigator.pop(context);
          }
        },),
        title: Style.title(MyLocalizations.of(context, 'campaign_tutorial_txt',), fontSize: 16),
      ),
      body: IntroSlider(
        slides: initSlides(),
        showSkipBtn: false,
        renderNextBtn: renderNextBtn(),
        renderDoneBtn: renderDoneBtn(),
        onDonePress: onDonePress,
        doneButtonStyle: ButtonStyle(
            backgroundColor:
            MaterialStateProperty.all(Style.colorPrimary.withOpacity(0.2)),
            overlayColor: MaterialStateProperty.all(Style.colorPrimary)),
        colorDot: Style.colorPrimary.withOpacity(0.4),
        sizeDot: 6.0,
        colorActiveDot: Style.colorPrimary,
        listCustomTabs: renderListCustomTabs(),
        backgroundColorAllSlides: Colors.white,
        refFuncGoToTab: (refFunc) {
          goToTab = refFunc;
        },
        hideStatusBar: false,
      ),
    );
  }

  // Slide Management
  List<Slide> initSlides() {
    slides.clear();
    for (var idx = 0; idx < 9; idx ++) {
      slides.add(Slide(
          title: '',
          description: MyLocalizations.of(context, 'tutorial_send_module_00${idx+1}'),
          pathImage: 'assets/img/sendmodule/fg_module_00${idx+1}.png',
          backgroundImage: 'assets/img/sendmodule/fg_module_00${idx+1}.png'));
    }
    return slides;
  }
  void onDonePress() {
    Navigator.pop(context);
    if (widget.fromReport != null && widget.fromReport!) {
      Navigator.popUntil(context, (route) => route.isFirst);
    }
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
          margin: EdgeInsets.symmetric(vertical: 0),
          child: ListView(
            children: <Widget>[
              GestureDetector(
                  child: Image.asset(
                    currentSlide.pathImage!,
                    width: MediaQuery.of(context).size.width ,
                    fit: BoxFit.cover,
                  )),
              Container(
                margin: EdgeInsets.all(12.0),
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

}
