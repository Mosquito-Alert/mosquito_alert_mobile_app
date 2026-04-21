import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:mosquito_alert_app/features/reports/domain/models/base_report.dart';
import 'package:mosquito_alert_app/core/widgets/step_page.dart';
import 'package:mosquito_alert_app/core/widgets/step_page_container.dart';
import 'package:mosquito_alert_app/features/reports/presentation/widgets/report_creation_step_indicator.dart';
import 'package:mosquito_alert_app/core/localizations/MyLocalizations.dart';
import 'package:mosquito_alert_app/core/utils/InAppReviewManager.dart';

/// Uses PageView slider architecture for step-by-step progression
class ReportCreatePage<TReport extends BaseReportModel> extends StatefulWidget {
  final String title;
  final List<StepPage> stepPages;
  final Map<String, Object>? analyticsParameters;
  final Future<TReport> Function(BuildContext context) onSubmit;
  final Future<void> Function(BuildContext context, dynamic report)?
  onSubmitSuccess;

  ReportCreatePage({
    required this.title,
    required this.stepPages,
    this.analyticsParameters,
    required this.onSubmit,
    this.onSubmitSuccess,
  });

  @override
  _ReportCreatePageState createState() => _ReportCreatePageState();
}

class _ReportCreatePageState<TReport extends BaseReportModel>
    extends State<ReportCreatePage<TReport>>
    with TickerProviderStateMixin {
  late PageController _pageController;
  late TabController _tabController;

  int _currentPageIndex = 0;
  bool isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _tabController = TabController(
      length: widget.stepPages.length,
      vsync: this,
    );
    _logAnalyticsEvent('start_report');
  }

  @override
  void dispose() {
    _pageController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _updateCurrentPageIndex(int index) {
    _tabController.index = index;
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  void _handlePageViewChanged(int index) async {
    // Check if the index is valid and log the event
    setState(() {
      _currentPageIndex = index;
    });
    _tabController.index = index;
  }

  Future<void> _logAnalyticsEvent(String eventName) async {
    await FirebaseAnalytics.instance.logEvent(
      name: eventName,
      parameters: widget.analyticsParameters,
    );
  }

  /// Handle back button/navigation
  void _handleBackPressed() {
    if (_currentPageIndex > 0) {
      setState(() {
        _currentPageIndex--;
      });
      _pageController.previousPage(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (!didPop) {
          _handleBackPressed();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: BackButton(onPressed: _handleBackPressed),
          title: Text(
            widget.title,
            style: TextStyle(
              color: Colors.black,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          centerTitle: true,
          bottom: PreferredSize(
            child: ReportCreationStepIndicator(tabController: _tabController),
            preferredSize: Size.fromHeight(0),
          ),
        ),
        body: Stack(
          children: [
            PageView(
              controller: _pageController,
              onPageChanged: _handlePageViewChanged,
              physics: NeverScrollableScrollPhysics(), // Disable swipe
              children: widget.stepPages.asMap().entries.map((entry) {
                int index = entry.key;
                StepPage stepPage = entry.value;

                bool isLastPage = index == widget.stepPages.length - 1;
                return StepPageContainer(
                  buttonText: isLastPage
                      ? MyLocalizations.of(context, 'send_data')
                      : MyLocalizations.of(context, 'continue_txt'),
                  onContinue: () async {
                    if (!isLastPage) {
                      _updateCurrentPageIndex(_currentPageIndex + 1);
                      return;
                    }
                    if (mounted) {
                      setState(() => isSubmitting = true);
                    }
                    TReport? newReport;
                    try {
                      newReport = await widget.onSubmit(context);
                    } catch (e) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(e.toString()),
                          backgroundColor: Colors.red,
                          duration: const Duration(seconds: 4),
                        ),
                      );
                    } finally {
                      if (mounted) {
                        setState(() => isSubmitting = false);
                      }
                    }

                    if (newReport == null || !mounted) return;
                    await widget.onSubmitSuccess?.call(context, newReport);

                    Navigator.of(context).popUntil((route) => route.isFirst);
                    InAppReviewManager.requestInAppReview(context);
                  },
                  child: stepPage,
                );
              }).toList(),
            ),
            if (isSubmitting) ...[
              Container(
                color: Colors.black.withValues(alpha: 0.3),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                      SizedBox(height: 12),
                      Text(
                        MyLocalizations.of(context, 'loading'),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
