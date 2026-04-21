import 'package:flutter/material.dart';
import 'package:mosquito_alert/mosquito_alert.dart';
import 'package:mosquito_alert_app/core/localizations/MyLocalizations.dart';
import 'package:mosquito_alert_app/core/utils/style.dart';

class ReportCreationEnvironmentStep extends StatefulWidget {
  final String? initialEnvironmentName;
  final String title;
  final bool allowNullOption;
  final void Function(String?) onChanged;

  const ReportCreationEnvironmentStep({
    super.key,
    required this.title,
    required this.allowNullOption,
    required this.onChanged,
    this.initialEnvironmentName,
  });

  @override
  _ReportCreationEnvironmentStepState createState() =>
      _ReportCreationEnvironmentStepState();
}

class _ReportCreationEnvironmentStepState
    extends State<ReportCreationEnvironmentStep> {
  String? selectedEnvironmentName;

  List<Map<String, dynamic>> _environmentOptions = [
    {
      'value': ObservationEventEnvironmentEnum.vehicle,
      'titleKey': 'question_4_answer_41',
      // 'description': '(HC) Car, bus, train, or any other vehicle',
      'description': null,
      'icon': Icons.directions_car,
    },
    {
      'value': ObservationEventEnvironmentEnum.indoors,
      'titleKey': 'question_4_answer_42',
      // 'description': '(HC) House, office, shop, or any indoor space',
      'description': null,
      'icon': Icons.home,
    },
    {
      'value': ObservationEventEnvironmentEnum.outdoors,
      'titleKey': 'question_4_answer_43',
      // 'description': '(HC) Garden, park, street, or any outdoor space',
      'description': null,
      'icon': Icons.park,
    },
  ];

  @override
  void initState() {
    super.initState();
    if (widget.allowNullOption) {
      _environmentOptions.add({
        'value': ObservationEventEnvironmentEnum.empty,
        'titleKey': 'question_4_answer_44',
        // 'description': null,
        'icon': Icons.help_outline,
      });
    }
    selectedEnvironmentName = widget.initialEnvironmentName;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.title,
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Text(
          MyLocalizations.of(context, 'this-information-helps-researchers'),
          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
        ),

        SizedBox(height: 20),

        // Options
        ListView.separated(
          shrinkWrap: true,
          padding: const EdgeInsets.only(bottom: 12),
          separatorBuilder: (context, index) => SizedBox(height: 12),
          itemCount: _environmentOptions.length,
          itemBuilder: (context, index) {
            final option = _environmentOptions[index];
            final isSelected = selectedEnvironmentName == option['value']?.name;

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
                    color: isSelected ? Colors.white : Colors.grey[600],
                    size: 24,
                  ),
                ),
                title: Text(
                  MyLocalizations.of(context, option['titleKey']),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Style.colorPrimary : Colors.black87,
                  ),
                ),
                subtitle: option['description'] != null
                    ? Text(
                        option['description'],
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      )
                    : null,
                onTap: () {
                  setState(() {
                    selectedEnvironmentName = option['value']?.name;
                  });
                  widget.onChanged(option['value']?.name);
                },
              ),
            );
          },
        ),
      ],
    );
  }
}
