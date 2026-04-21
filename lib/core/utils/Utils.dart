import 'package:flutter/material.dart';
import 'package:mosquito_alert_app/core/utils/style.dart';

class Utils {
  static Widget loading(_isLoading, [Color? indicatorColor]) {
    return _isLoading == true
        ? IgnorePointer(
            child: Container(
              color: Colors.transparent,
              child: Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    indicatorColor ?? Style.colorPrimary,
                  ),
                ),
              ),
            ),
          )
        : Container();
  }
}
