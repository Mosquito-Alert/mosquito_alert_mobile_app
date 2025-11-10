import 'package:flutter/material.dart';
import 'package:mosquito_alert_app/utils/MyLocalizations.dart';
import 'package:mosquito_alert_app/utils/style.dart';

/// Shared notes and submit page that can be used by any report workflow
/// Configurable notes handling and submit behavior through callbacks
class NotesAndSubmitPage extends StatefulWidget {
  final String? initialNotes;
  final Function(String?) onNotesChanged;
  final VoidCallback onSubmit;
  final VoidCallback onPrevious;
  final bool isSubmitting;
  final String submitLoadingText;

  const NotesAndSubmitPage({
    Key? key,
    this.initialNotes,
    required this.onNotesChanged,
    required this.onSubmit,
    required this.onPrevious,
    required this.isSubmitting,
    this.submitLoadingText = '(HC) Submitting your report...',
  }) : super(key: key);

  @override
  _NotesAndSubmitPageState createState() => _NotesAndSubmitPageState();
}

class _NotesAndSubmitPageState extends State<NotesAndSubmitPage> {
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

  void _updateNotes() {
    final notes = _notesController.text.isEmpty ? null : _notesController.text;
    widget.onNotesChanged(notes);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Scrollable content area
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Notes section
                  Text(
                    '(HC) Additional Notes (Optional)',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  SizedBox(height: 8),

                  Text(
                    '(HC) Add any additional observations or details.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
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
                        borderSide:
                            BorderSide(color: Style.colorPrimary, width: 2),
                      ),
                      hintText: MyLocalizations.of(context, "comments_txt"),
                    ),
                    onChanged: (value) => _updateNotes(),
                  ),

                  SizedBox(height: 24),

                  // Submit section
                  if (widget.isSubmitting) ...[
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Style.colorPrimary.withValues(alpha: 0.1),
                        border: Border.all(
                            color: Style.colorPrimary.withValues(alpha: 0.3)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                                Style.colorPrimary),
                          ),
                          SizedBox(height: 12),
                          Text(
                            widget.submitLoadingText,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            '(HC) Please wait while we process your report.',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            child: widget.isSubmitting
                ? Style.button(
                    '(HC) Submitting...',
                    null,
                  )
                : Style.button(
                    MyLocalizations.of(context, 'send_data'),
                    widget.onSubmit,
                  ),
          ),
        ],
      ),
    ));
  }
}
