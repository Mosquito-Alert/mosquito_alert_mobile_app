import 'package:flutter/material.dart';
import 'package:mosquito_alert_app/utils/MyLocalizations.dart';

import '../models/adult_report_data.dart';

class NotesAndSubmitPage extends StatefulWidget {
  final AdultReportData reportData;
  final VoidCallback onSubmit;
  final VoidCallback onPrevious;
  final bool isSubmitting;

  const NotesAndSubmitPage({
    Key? key,
    required this.reportData,
    required this.onSubmit,
    required this.onPrevious,
    required this.isSubmitting,
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
    if (widget.reportData.notes != null) {
      _notesController.text = widget.reportData.notes!;
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _updateNotes() {
    widget.reportData.notes =
        _notesController.text.isEmpty ? null : _notesController.text;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
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
            '(HC) Add any additional observations or details about the mosquito or circumstances.',
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
              border: OutlineInputBorder(),
              hintText:
                  '(HC) e.g., "Found near standing water", "Very active", "Unusual markings"...',
              labelText: '(HC) Notes',
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
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 12),
                  Text(
                    '(HC) Submitting your report...',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '(HC) Please wait while we process your mosquito report.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Navigation buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: widget.isSubmitting ? null : widget.onPrevious,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Theme.of(context).primaryColor,
                    side: BorderSide(color: Theme.of(context).primaryColor),
                    padding: EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text('(HC) Back'),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: widget.isSubmitting ? null : widget.onSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    disabledBackgroundColor: Colors.grey[300],
                  ),
                  child: widget.isSubmitting
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            ),
                            SizedBox(width: 8),
                            Text('(HC) Submitting...'),
                          ],
                        )
                      : Text(
                          MyLocalizations.of(context, 'send_data'),
                          style: TextStyle(fontSize: 16),
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
