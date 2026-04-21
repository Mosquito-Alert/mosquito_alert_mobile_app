import 'package:flutter/material.dart';
import 'package:mosquito_alert_app/core/localizations/MyLocalizations.dart';
import 'package:mosquito_alert_app/core/utils/style.dart';

/// Shared notes and submit page that can be used by any report workflow
/// Configurable notes handling and submit behavior through callbacks
class ReportCreationNotesStep extends StatefulWidget {
  final String? initialNotes;
  final Function(String? notes) onChange;

  const ReportCreationNotesStep({
    Key? key,
    this.initialNotes,
    required this.onChange,
  }) : super(key: key);

  @override
  _ReportCreationNotesStepState createState() =>
      _ReportCreationNotesStepState();
}

class _ReportCreationNotesStepState extends State<ReportCreationNotesStep> {
  final _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Pre-fill notes if they exist
    if (widget.initialNotes != null) {
      _notesController.text = widget.initialNotes!;
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Notes section
        Text(
          MyLocalizations.of(context, 'notes') +
              ' (' +
              MyLocalizations.of(context, 'optional') +
              ')',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),

        SizedBox(height: 12),

        TextField(
          controller: _notesController,
          maxLines: 4,
          maxLength: 500,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.grey),
            ),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.grey),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Style.colorPrimary, width: 2),
            ),
            hintText: MyLocalizations.of(context, "comments_txt"),
          ),
          onChanged: widget.onChange,
        ),
      ],
    );
  }
}
