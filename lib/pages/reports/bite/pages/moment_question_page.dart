import 'package:flutter/material.dart';
import 'package:mosquito_alert/mosquito_alert.dart';
import 'package:mosquito_alert_app/utils/MyLocalizations.dart';
import 'package:mosquito_alert_app/utils/style.dart';

class EventMomentPage extends StatefulWidget {
  final void Function(BiteRequestEventMomentEnum) onNext;
  final VoidCallback onPrevious;
  const EventMomentPage(
      {super.key, required this.onNext, required this.onPrevious});

  @override
  State<EventMomentPage> createState() => _EventMomentPageState();
}

enum MainSelectionType { justNow, last24h }

class _EventMomentPageState extends State<EventMomentPage> {
  MainSelectionType? _mainSelection;
  BiteRequestEventMomentEnum?
      _timeOfDay; // "morning", "midday", "afternoon", "night"

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                MyLocalizations.of(context, 'question_5'),
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // Main selection
              Row(
                children: [
                  _buildOptionButton(
                      MyLocalizations.of(context, 'question_5_answer_51'),
                      MainSelectionType.justNow,
                      BiteRequestEventMomentEnum.now),
                  const SizedBox(width: 12),
                  _buildOptionButton(
                      MyLocalizations.of(context, 'question_5_answer_52'),
                      MainSelectionType.last24h,
                      null),
                ],
              ),

              const SizedBox(height: 24),

              // Conditional time of day
              if (_mainSelection == MainSelectionType.last24h) ...[
                Text(
                  MyLocalizations.of(context, 'question_3'),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 12),
                _buildTimeOfDayButton(
                    MyLocalizations.of(context, 'question_3_answer_31'),
                    Icons.wb_sunny_outlined,
                    BiteRequestEventMomentEnum.lastMorning),
                _buildTimeOfDayButton(
                    MyLocalizations.of(context, 'question_3_answer_32'),
                    Icons.wb_sunny,
                    BiteRequestEventMomentEnum.lastMidday),
                _buildTimeOfDayButton(
                    MyLocalizations.of(context, 'question_3_answer_33'),
                    Icons.wb_twilight,
                    BiteRequestEventMomentEnum.lastAfternoon),
                _buildTimeOfDayButton(
                    MyLocalizations.of(context, 'question_3_answer_34'),
                    Icons.nightlight_round,
                    BiteRequestEventMomentEnum.lastNight),
              ],
              const Spacer(),
              // Continue button
              SizedBox(
                width: double.infinity,
                child: Style.button(
                  MyLocalizations.of(context, 'continue_txt'),
                  _timeOfDay != null ? () => widget.onNext(_timeOfDay!) : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionButton(String label, MainSelectionType value,
      BiteRequestEventMomentEnum? timeOfDayValue) {
    final bool selected = _mainSelection == value;
    return Expanded(
      child: ElevatedButton(
        onPressed: () {
          setState(() {
            _mainSelection = value;
            _timeOfDay = timeOfDayValue;
          });
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: selected ? Style.colorPrimary : Colors.grey.shade200,
          foregroundColor: selected ? Colors.white : Colors.black87,
          elevation: 0,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
        child: Text(label),
      ),
    );
  }

  Widget _buildTimeOfDayButton(
      String label, IconData icon, BiteRequestEventMomentEnum value) {
    final bool selected = _timeOfDay == value;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: InkWell(
        onTap: () => setState(() => _timeOfDay = value),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          decoration: BoxDecoration(
            color: selected
                ? Style.colorPrimary.withValues(alpha: 0.05)
                : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? Style.colorPrimary : Colors.grey.shade300,
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: selected ? Style.colorPrimary : Colors.grey.shade700,
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                  color: selected ? Style.colorPrimary : Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
