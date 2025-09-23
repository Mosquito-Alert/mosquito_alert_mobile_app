import 'package:flutter/material.dart';
import 'package:mosquito_alert_app/pages/reports/shared/widgets/notes_and_submit_widget.dart';

/// Shared notes and submit page that can be used by any report workflow
/// Configurable notes handling and submit behavior through callbacks
class NotesAndSubmitPage extends StatefulWidget {
  final String? initialNotes;
  final Function(String?) onNotesChanged;
  final VoidCallback onSubmit;
  final VoidCallback onPrevious;
  final bool isSubmitting;
  final String notesHint;
  final String submitLoadingText;

  const NotesAndSubmitPage({
    Key? key,
    this.initialNotes,
    required this.onNotesChanged,
    required this.onSubmit,
    required this.onPrevious,
    required this.isSubmitting,
    this.notesHint =
        '(HC) e.g., "Found near standing water", "Very active", "Unusual markings"...',
    this.submitLoadingText = '(HC) Submitting your report...',
  }) : super(key: key);

  @override
  _NotesAndSubmitPageState createState() => _NotesAndSubmitPageState();
}

class _NotesAndSubmitPageState extends State<NotesAndSubmitPage> {
  @override
  Widget build(BuildContext context) {
    return NotesAndSubmitWidget(
      initialNotes: widget.initialNotes,
      onNotesChanged: widget.onNotesChanged,
      onSubmit: widget.onSubmit,
      onPrevious: widget.onPrevious,
      isSubmitting: widget.isSubmitting,
      notesHint: widget.notesHint,
      submitLoadingText: widget.submitLoadingText,
    );
  }
}
