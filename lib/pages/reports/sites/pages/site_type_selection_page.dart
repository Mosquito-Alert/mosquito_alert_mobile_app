import 'package:flutter/material.dart';
import 'package:mosquito_alert_app/utils/MyLocalizations.dart';
import 'package:mosquito_alert_app/utils/style.dart';

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
      'icon': Icons.water,
      'image': 'assets/img/ic_imbornal.webp',
    },
    {
      'value': 'other',
      'titleKey': 'question_12_answer_122', // Other
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
    return Stack(
      children: [
        // Background image at bottom, undistorted
        Align(
          alignment: Alignment.bottomCenter,
          child: Image.asset(
            'assets/img/bottoms/breeding_1.webp',
            fit: BoxFit.contain,
            alignment: Alignment.bottomCenter,
          ),
        ),
        // Main content
        Padding(
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
                                  ? Style.colorPrimary
                                  : Colors.grey[300]!,
                              width: isSelected ? 2 : 1,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            color: isSelected
                                ? Style.colorPrimary.withValues(alpha: 0.1)
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
                                            ? Style.colorPrimary
                                            : Colors.black87,
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
                                    color: Style.colorPrimary,
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
            ],
          ),
        ),
      ],
    );
  }
}
