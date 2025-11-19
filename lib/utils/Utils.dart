import 'dart:math';

import 'package:flutter/material.dart';
import 'package:mosquito_alert_app/utils/style.dart';

class Utils {
  static Widget loading(_isLoading, [Color? indicatorColor]) {
    return _isLoading == true
        ? IgnorePointer(
            child: Container(
            color: Colors.transparent,
            child: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                    indicatorColor ?? Style.colorPrimary),
              ),
            ),
          ))
        : Container();
  }

  static String getRandomPassword(int length) {
    const chars =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#\$%^&*';
    final rand = Random.secure();
    return List.generate(length, (index) => chars[rand.nextInt(chars.length)])
        .join();
  }
}
