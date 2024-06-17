import 'package:flutter/material.dart';
import 'package:intro_slider/intro_slider.dart';
import 'package:mosquito_alert_app/utils/MyLocalizations.dart';
import 'package:mosquito_alert_app/utils/style.dart';

class TutorialPage extends StatefulWidget {
  final bool goBack;

  TutorialPage(this.goBack);

  @override
  _TutorialPageState createState() => _TutorialPageState();
}

class _TutorialPageState extends State<TutorialPage> {
  List<Slide> slides = [];

  Function? goToTab;

  @override
  void initState() {
    super.initState();
  }

  List<Slide> initSlides() {
    slides.add(Slide(
      title: '',
      description: MyLocalizations.of(context, 'tutorial_info_01'),
      pathImage: 'assets/img/tutorial/Fig1.png',
    ));
    slides.add(
      Slide(
        title: '',
        description: MyLocalizations.of(context, 'tutorial_info_02'),
        pathImage: 'assets/img/tutorial/Fig2.png',
      ),
    );
    slides.add(
      Slide(
        title: '',
        description: MyLocalizations.of(context, 'tutorial_info_03'),
        pathImage: 'assets/img/tutorial/Fig3.png',
      ),
    );
    slides.add(
      Slide(
        title: '',
        description: MyLocalizations.of(context, 'tutorial_info_04'),
        pathImage: 'assets/img/tutorial/Fig4.png',
      ),
    );
    slides.add(
      Slide(
        title: MyLocalizations.of(context, 'tutorial_title_05'),
        description: MyLocalizations.of(context, 'tutorial_info_05'),
        pathImage: 'assets/img/tutorial/Fig5.png',
      ),
    );
    slides.add(
      Slide(
        title: MyLocalizations.of(context, 'tutorial_title_06'),
        description: MyLocalizations.of(context, 'tutorial_info_06'),
        pathImage: 'assets/img/tutorial/Fig6.png',
      ),
    );
    slides.add(
      Slide(
        title: MyLocalizations.of(context, 'tutorial_title_07'),
        description: MyLocalizations.of(context, 'tutorial_info_07'),
        pathImage: 'assets/img/tutorial/Fig7.png',
      ),
    );
    slides.add(
      Slide(
        title: MyLocalizations.of(context, 'tutorial_title_08'),
        description: MyLocalizations.of(context, 'tutorial_info_08'),
        pathImage: 'assets/img/tutorial/Fig8.png',
      ),
    );
    slides.add(
      Slide(
        title: MyLocalizations.of(context, 'tutorial_title_10'),
        description: MyLocalizations.of(context, 'tutorial_info_10'),
        pathImage: 'assets/img/tutorial/Fig10.png',
      ),
    );
    slides.add(
      Slide(
        title: MyLocalizations.of(context, 'tutorial_title_11'),
        description: MyLocalizations.of(context, 'tutorial_info_11'),
        pathImage: 'assets/img/tutorial/Fig11.png',
      ),
    );
    slides.add(
      Slide(
        title: MyLocalizations.of(context, 'tutorial_title_12'),
        description: MyLocalizations.of(context, 'tutorial_info_12'),
        pathImage: 'assets/img/tutorial/Fig12.png',
      ),
    );
    slides.add(
      Slide(
        title: MyLocalizations.of(context, 'tutorial_title_13'),
        description: MyLocalizations.of(context, 'tutorial_info_13'),
        pathImage: 'assets/img/tutorial/Fig13.png',
      ),
    );
    slides.add(
      Slide(
        title: '',
        description: MyLocalizations.of(context, 'tutorial_info_15'),
        pathImage: 'assets/img/tutorial/Fig1.png',
      ),
    );
    return slides;
  }

  void onDonePress() {
    Navigator.pop(context);
  }

  Widget renderNextBtn() {
    return Icon(
      Icons.navigate_next,
      color: Style.colorPrimary,
      size: 25.0,
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
          margin: EdgeInsets.symmetric(vertical: 20),
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
                child: Style.titleMedium(
                  currentSlide.title,
                  textAlign: TextAlign.center,
                  fontSize: 14,
                ),
              ),
              Container(
                margin: EdgeInsets.all(20.0),
                child: Style.body(
                  currentSlide.description,
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
        sizeDot: 5.0,
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
}
