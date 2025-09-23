import 'package:flutter/material.dart';
import 'package:mosquito_alert_app/utils/MyLocalizations.dart';

import '../models/breeding_site_report_data.dart';

class SiteTypeSelectionPage extends StatefulWidget {
  final BreedingSiteReportData reportData;
  final VoidCallback onNext;

  const SiteTypeSelectionPage({
    Key? key,
    required this.reportData,
    required this.onNext,
  }) : super(key: key);

  @override
  _SiteTypeSelectionPageState createState() => _SiteTypeSelectionPageState();
}

class _SiteTypeSelectionPageState extends State<SiteTypeSelectionPage> {
  final List<Map<String, dynamic>> _siteTypeOptions = [
    {
      'value': 'storm_drain',
      'titleKey': 'question_12_answer_121', // Storm drain
      'description':
          '(HC) Storm drain, sewer grate, or similar drainage system',
      'icon': Icons.water,
      'image': 'assets/img/ic_imbornal.webp',
    },
    {
      'value': 'other',
      'titleKey': 'question_12_answer_122', // Other
      'description': '(HC) Other type of breeding site in public space',
      'icon': Icons.location_on,
      'image': 'assets/img/ic_other_site.webp',
    },
  ];

  void _selectSiteType(String siteType) {
    setState(() {
      widget.reportData.siteType = siteType;
    });
    // Auto-proceed to next step
    widget.onNext();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text(
            MyLocalizations.of(context, 'question_12'),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),

          SizedBox(height: 8),

          // Subtitle
          Text(
            '(HC) Select the type of breeding site you found:',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),

          SizedBox(height: 24),

          // Options
          Expanded(
            child: ListView.builder(
              itemCount: _siteTypeOptions.length,
              itemBuilder: (context, index) {
                final option = _siteTypeOptions[index];
                final isSelected =
                    widget.reportData.siteType == option['value'];

                return Container(
                  margin: EdgeInsets.only(bottom: 16),
                  child: InkWell(
                    onTap: () => _selectSiteType(option['value']),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: isSelected
                              ? Theme.of(context).primaryColor
                              : Colors.grey[300]!,
                          width: isSelected ? 2 : 1,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        color: isSelected
                            ? Theme.of(context)
                                .primaryColor
                                .withValues(alpha: 0.1)
                            : Colors.white,
                      ),
                      child: Row(
                        children: [
                          // Image
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.asset(
                                option['image'],
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: Colors.grey[200],
                                    child: Icon(
                                      option['icon'],
                                      size: 30,
                                      color: Colors.grey[500],
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),

                          SizedBox(width: 16),

                          // Text content
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  MyLocalizations.of(
                                      context, option['titleKey']),
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: isSelected
                                        ? Theme.of(context).primaryColor
                                        : Colors.black87,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  option['description'],
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Selection indicator
                          if (isSelected)
                            Container(
                              padding: EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Theme.of(context).primaryColor,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Info section
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              border: Border.all(color: Colors.blue[200]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue[700]),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '(HC) We focus on breeding sites in public spaces that may require community attention.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.blue[700],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
