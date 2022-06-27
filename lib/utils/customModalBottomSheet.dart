import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

//OWN Full Modal Bottom Sheet class
class CustomShowModalBottomSheet {
  static Future<T> customShowModalBottomSheet<T>({
    @required BuildContext context,
    @required WidgetBuilder builder,
    bool dismissible,
  }) {
    assert(context != null);
    assert(builder != null);
    assert(debugCheckHasMaterialLocalizations(context));
    return Navigator.push(
        context,
        _CullModalBottomSheetRoute<T>(
          builder: builder,
          theme: Theme.of(context,),
          barrierLabel:
              MaterialLocalizations.of(context).modalBarrierDismissLabel,
          dismissible: dismissible,
        ));
  }
}

class _CullModalBottomSheetRoute<T> extends PopupRoute<T> {
  _CullModalBottomSheetRoute({
    this.builder,
    this.theme,
    this.barrierLabel,
    this.dismissible,
    RouteSettings settings,
  }) : super(settings: settings);

  final WidgetBuilder builder;
  final ThemeData theme;
  final bool dismissible;

  @override
  Duration get transitionDuration => Duration(milliseconds: 200);

  @override
  bool get barrierDismissible => dismissible ?? true;

  @override
  final String barrierLabel;

  @override
  Color get barrierColor => Colors.black54;

  AnimationController _animationController;

  @override
  AnimationController createAnimationController() {
    assert(_animationController == null);
    _animationController =
        BottomSheet.createAnimationController(navigator.overlay);
    return _animationController;
  }

  @override
  Widget buildPage(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation) {
    // By definition, the bottom sheet is aligned to the bottom of the page
    // and isn't exposed to the top padding of the MediaQuery.
    Widget bottomSheet = MediaQuery.removePadding(
      context: context,
      removeTop: true,
      child: _CustomModalBottomSheet<T>(route: this),
    );
    if (theme != null) bottomSheet = Theme(data: theme, child: bottomSheet);
    return bottomSheet;
  }
}

class _CustomModalBottomSheet<T> extends StatefulWidget {
  const _CustomModalBottomSheet({Key key, this.route}) : super(key: key);

  final _CullModalBottomSheetRoute<T> route;

  @override
  _CustomModalBottomSheetState<T> createState() =>
      _CustomModalBottomSheetState<T>();
}

class _CustomModalBottomSheetState<T>
    extends State<_CustomModalBottomSheet<T>> {
  @override
  Widget build(BuildContext context) {
    final MediaQueryData mediaQuery = MediaQuery.of(context);
    final MaterialLocalizations localizations =
        MaterialLocalizations.of(context);
    String routeLabel;
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
        routeLabel = '';
        break;
      case TargetPlatform.android:
      case TargetPlatform.fuchsia:
        routeLabel = localizations.dialogLabel;
        break;
      case TargetPlatform.linux:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
        break;
    }

    return Theme(
      data: Theme.of(context).copyWith(canvasColor: Colors.transparent),
      child: AnimatedBuilder(
          animation: widget.route.animation,
          builder: (BuildContext context, Widget child) {
            // Disable the initial animation when accessible navigation is on so
            // that the semantics are added to the tree at the correct time.
            final double animationValue = mediaQuery.accessibleNavigation
                ? 1.0
                : widget.route.animation.value;
            return Semantics(
              scopesRoute: true,
              namesRoute: true,
              label: routeLabel,
              explicitChildNodes: true,
              child: ClipRect(
                child: CustomSingleChildLayout(
                  delegate: _CustomModalBottomSheetLayout(animationValue),
                  child: BottomSheet(
                    animationController: widget.route._animationController,
                    onClosing: () => Navigator.pop(context),
                    builder: widget.route.builder,
                  ),
                ),
              ),
            );
          }),
    );
  }
}

class _CustomModalBottomSheetLayout extends SingleChildLayoutDelegate {
  _CustomModalBottomSheetLayout(this.progress);

  final double progress;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    return BoxConstraints(
        minWidth: constraints.maxWidth,
        maxWidth: constraints.maxWidth,
        minHeight: 0.0,
        maxHeight: constraints.maxHeight);
  }

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    return Offset(0.0, size.height - childSize.height * progress);
  }

  @override
  bool shouldRelayout(_CustomModalBottomSheetLayout oldDelegate) {
    return progress != oldDelegate.progress;
  }
}
