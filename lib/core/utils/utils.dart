import 'package:flutter/material.dart';
import 'package:mosquito_alert_app/core/utils/style.dart';

class Utils {
  static Widget loading(bool isLoading, [Color? indicatorColor]) {
    return isLoading == true
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
