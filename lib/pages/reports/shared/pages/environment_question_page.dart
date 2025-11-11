import 'package:flutter/material.dart';
import 'package:mosquito_alert/mosquito_alert.dart';
import 'package:mosquito_alert_app/utils/MyLocalizations.dart';
import 'package:mosquito_alert_app/utils/style.dart';

class EnvironmentQuestionPage extends StatefulWidget {
  final String title;
  final bool allowNullOption;
  final void Function(String?) onNext;
  final VoidCallback onPrevious;

  const EnvironmentQuestionPage({
    super.key,
    required this.title,
    required this.allowNullOption,
    required this.onNext,
    required this.onPrevious,
  });

  @override
  _EnvironmentQuestionPageState createState() =>
      _EnvironmentQuestionPageState();
}

class _EnvironmentQuestionPageState extends State<EnvironmentQuestionPage> {
  late List<Map<String, dynamic>> _environmentOptions;

  int? selectedIndex;

  @override
  void initState() {
    super.initState();
    _environmentOptions = [
      {
        'value': ObservationEventEnvironmentEnum.vehicle.name,
        'titleKey': 'question_4_answer_41',
        // 'description': '(HC) Car, bus, train, or any other vehicle',
        'description': null,
        'icon': Icons.directions_car,
      },
      {
        'value': ObservationEventEnvironmentEnum.indoors.name,
        'titleKey': 'question_4_answer_42',
        // 'description': '(HC) House, office, shop, or any indoor space',
        'description': null,
        'icon': Icons.home,
      },
      {
        'value': ObservationEventEnvironmentEnum.outdoors.name,
        'titleKey': 'question_4_answer_43',
        // 'description': '(HC) Garden, park, street, or any outdoor space',
        'description': null,
        'icon': Icons.park,
      },
      if (widget.allowNullOption)
        {
          'value': null,
          'titleKey': 'question_4_answer_44',
          // 'description': null,
          'icon': Icons.help_outline,
        },
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
            child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.title,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                MyLocalizations.of(
                    context, 'this-information-helps-researchers'),
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),

              SizedBox(height: 20),

              // Options
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.only(bottom: 12),
                  separatorBuilder: (context, index) => SizedBox(height: 12),
                  itemCount: _environmentOptions.length,
                  itemBuilder: (context, index) {
                    final option = _environmentOptions[index];
                    final isSelected = selectedIndex == index;

                    return Card(
                      elevation: isSelected ? 4 : 1,
                      child: ListTile(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: isSelected
                              ? BorderSide(color: Style.colorPrimary, width: 2)
                              : BorderSide(color: Colors.grey[300]!, width: 1),
                        ),
                        tileColor: isSelected
                            ? Style.colorPrimary.withValues(alpha: 0.05)
                            : Colors.white,
                        leading: CircleAvatar(
                            backgroundColor: isSelected
                                ? Style.colorPrimary
                                : Colors.grey[300],
                            child: Icon(
                              option['icon'],
                              color:
                                  isSelected ? Colors.white : Colors.grey[600],
                              size: 24,
                            )),
                        title: Text(
                          MyLocalizations.of(context, option['titleKey']),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isSelected
                                ? Style.colorPrimary
                                : Colors.black87,
                          ),
                        ),
                        subtitle: option['description'] != null
                            ? Text(
                                option['description'],
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              )
                            : null,
                        onTap: () => {
                          setState(() {
                            selectedIndex = index;
                          })
                        },
                      ),
                    );
                  },
                ),
              ),

              // Navigation buttons
              SizedBox(
                width: double.infinity,
                child: Style.button(
                  MyLocalizations.of(context, 'continue_txt'),
                  selectedIndex != null
                      ? () => widget
                          .onNext(_environmentOptions[selectedIndex!]['value'])
                      : null,
                ),
              ),
            ],
          ),
        )));
  }
}
