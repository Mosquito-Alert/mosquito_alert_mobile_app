import 'dart:async';
import 'dart:math';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:mosquito_alert_app/features/bites/presentation/pages/bite_create_page.dart';
import 'package:mosquito_alert_app/features/breeding_sites/presentation/pages/breeding_site_create_page.dart';
import 'package:mosquito_alert_app/features/observations/presentation/pages/observation_create_page.dart';
import 'package:mosquito_alert_app/screens/public_map.dart';
import 'package:mosquito_alert_app/core/localizations/MyLocalizations.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late String _suggestedActionTextId;

  @override
  void initState() {
    super.initState();
    _suggestedActionTextId = _getRandomWhatToDoText();
    _logScreenView();
  }

  String _getRandomWhatToDoText() {
    var i = Random().nextInt(5) + 1;
    return 'what_to_do_txt_$i';
  }

  Future<void> _logScreenView() async {
    await FirebaseAnalytics.instance.logScreenView(
      screenName: '/home',
      parameters: {'action_text_id': _suggestedActionTextId},
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints viewportConstraints) {
          return Stack(
            children: [
              // Footer image in the background
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Image.asset(
                  'assets/img/bottoms/bottom_main.webp',
                  width: double.infinity,
                  fit: BoxFit.fitWidth,
                ),
              ),
              // Scrollable content
              SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: viewportConstraints.maxHeight,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),
                        Text(
                          MyLocalizations.of(context, _suggestedActionTextId),
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 30),
                        ..._buildCards(),
                        const SizedBox(
                          height: 150,
                        ), // Give space for the footer
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  List<Widget> _buildCards() {
    final cards = [
      {
        'text': MyLocalizations.of(context, 'single_mosquito'),
        'image': 'assets/img/ic_mosquito_report.webp',
        'color': '40DFD458',
        'page': ObservationCreatePage(),
      },
      {
        'text': MyLocalizations.of(context, 'single_bite'),
        'image': 'assets/img/ic_bite_report.webp',
        'color': '40D28A73',
        'page': BiteCreatePage(),
      },
      {
        'text': MyLocalizations.of(context, 'single_breeding_site'),
        'image': 'assets/img/ic_breeding_report.webp',
        'color': '407D9393',
        'page': BreedingSiteCreatePage(),
      },
      {
        'text': MyLocalizations.of(context, 'public_map_tab'),
        'image': 'assets/img/ic_public_map.webp',
        'color': 'FFebf1cc',
        'page': PublicMap(),
      },
    ];

    return cards
        .map(
          (c) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _buildCard(
              text: c['text'] as String,
              imagePath: c['image'] as String,
              color: c['color'] as String,
              page: c['page'] as Widget,
            ),
          ),
        )
        .toList();
  }

  Widget _buildCard({
    required String text,
    required String imagePath,
    required String color,
    required Widget page,
  }) {
    return Material(
      elevation: 5.0,
      borderRadius: BorderRadius.circular(100),
      child: Container(
        height: 70.0,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(100),
        ),
        child: InkWell(
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => page));
          },
          child: Row(
            children: <Widget>[
              CircleAvatar(
                radius: 35,
                backgroundColor: Color(int.parse(color, radix: 16)),
                child: ClipOval(
                  child: Image.asset(
                    imagePath,
                    fit: BoxFit.cover,
                    width: 65,
                    height: 65,
                  ),
                ),
              ),
              const SizedBox(width: 15),
              Expanded(child: Text(text, style: TextStyle(fontSize: 18))),
            ],
          ),
        ),
      ),
    );
  }
}
