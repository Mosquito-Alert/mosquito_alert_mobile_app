import 'package:flutter/material.dart';

class StepPage extends StatefulWidget {
  final ValueNotifier<bool> canContinue;
  final Function()? onDisplay;
  final Widget child;
  final EdgeInsetsGeometry padding;
  final bool fullScreen;
  final bool allowScroll;

  const StepPage({
    Key? key,
    required this.canContinue,
    required this.child,
    this.onDisplay,
    this.padding = const EdgeInsets.fromLTRB(16, 16, 16, 0),
    this.fullScreen = false,
    this.allowScroll = true,
  }) : super(key: key);

  @override
  _StepPageState createState() => _StepPageState();
}

class _StepPageState extends State<StepPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onDisplay?.call();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: widget.fullScreen ? EdgeInsets.zero : widget.padding,
      child: widget.child,
    );
  }
}
