import 'package:flutter/material.dart';

class Style {
  //Colors
  static final Color colorPrimary = Color(0XFFF0A402);
  static final Color textColor = Color(0XFF282828);

  // Texts
  static Widget title(
    text, {
    color,
    maxLines,
    textAlign,
    double? fontSize,
    height,
  }) {
    return Text(
      text ?? '',
      maxLines: maxLines,
      textAlign: textAlign ?? TextAlign.left,
      overflow: maxLines != null ? TextOverflow.ellipsis : null,
      style: TextStyle(
        height: height,
        color: color ?? textColor,
        fontSize: fontSize ?? 21,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  static Widget titleMedium(
    text, {
    color,
    maxLines,
    textAlign,
    double? fontSize,
    height,
  }) {
    return Text(
      text ?? '',
      maxLines: maxLines,
      textAlign: textAlign ?? TextAlign.left,
      overflow: maxLines != null ? TextOverflow.ellipsis : null,
      style: TextStyle(
        height: height,
        color: color ?? textColor,
        fontSize: fontSize ?? 21,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  static Widget body(
    text, {
    color,
    maxLines,
    textAlign,
    double? fontSize,
    height,
  }) {
    return Text(
      text ?? '',
      maxLines: maxLines,
      textAlign: textAlign ?? TextAlign.left,
      overflow: maxLines != null ? TextOverflow.ellipsis : null,
      style: TextStyle(
        height: height,
        color: color ?? textColor,
        fontSize: fontSize ?? 14,
      ),
    );
  }

  static Widget bodySmall(
    text, {
    color,
    maxLines,
    textAlign,
    double? fontSize,
    height,
  }) {
    return Text(
      text ?? '',
      maxLines: maxLines,
      textAlign: textAlign ?? TextAlign.left,
      overflow: maxLines != null ? TextOverflow.ellipsis : null,
      style: TextStyle(
        height: height,
        color: color ?? textColor,
        fontSize: fontSize ?? 12,
      ),
    );
  }
}
