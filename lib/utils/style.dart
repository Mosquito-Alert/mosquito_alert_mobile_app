import 'dart:io';

import 'package:flutter/material.dart';

class Style {
  //Colors
  static final Color colorPrimary = Color(0XFFF0A402);
  static final Color textColor = Color(0XFF282828);
  static final Color greyColor = Colors.black.withValues(alpha: 0.5);

  //UI
  static Icon get iconBack =>
      Platform.isIOS ? Icon(Icons.arrow_back_ios) : Icon(Icons.arrow_back);

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

  ///Buttons

  static Widget button(text, onPressed,
      {color, textColor, borderColor, elevation}) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        elevation: 0,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        padding: EdgeInsets.symmetric(vertical: 14),
        backgroundColor: color ?? colorPrimary,
        foregroundColor: textColor ?? Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(3),
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
            color: textColor ?? Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500),
      ),
    );
  }

  //TextFields
  static Widget textField(
    hint,
    controller,
    context, {
    keyboardType,
    textCapitalization,
    obscure,
    textInputAction,
    focusNode,
    nextFocusNode,
    suffixIcon,
    expands,
    textAlignVertical,
    enabled = true,
    maxLines,
    handleChange,
  }) {
    return TextField(
      keyboardType: keyboardType ?? TextInputType.text,
      textCapitalization: textCapitalization ?? TextCapitalization.none,
      autofocus: false,
      controller: controller,
      style: TextStyle(
          fontSize: 15,
          color: enabled ? textColor : textColor.withValues(alpha: 0.6)),
      textInputAction: textInputAction ?? TextInputAction.done,
      focusNode: focusNode,
      obscureText: obscure ?? false,
      decoration: textFieldDecoration(hint, suffixIcon),
      maxLines:
          expands != null && expands || keyboardType == TextInputType.multiline
              ? maxLines
              : 1,
      expands: expands ?? false,
      textAlignVertical: textAlignVertical ?? TextAlignVertical.center,
      textAlign: TextAlign.start,
      enabled: enabled ?? true,
      onChanged: handleChange,
    );
  }

  static InputDecoration textFieldDecoration(hint, suffixIcon) {
    return InputDecoration(
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Colors.white,
        hintText: hint,
        hintMaxLines: 5,
        hintStyle: TextStyle(fontSize: 17),
        contentPadding: EdgeInsets.fromLTRB(15.0, 16.0, 10.0, 16.0),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(3.0),
          borderSide:
              BorderSide(color: Colors.black.withValues(alpha: 0.1), width: 1),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(3.0),
          borderSide:
              BorderSide(color: Colors.black.withValues(alpha: 0.1), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(3.0),
          borderSide:
              BorderSide(color: Colors.black.withValues(alpha: 0.1), width: 1),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(3.0),
          borderSide: BorderSide(color: Colors.red, width: 1.0),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(3.0),
          borderSide: BorderSide(color: Colors.red, width: 1.0),
        ),
        alignLabelWithHint: true);
  }

  static Widget get bottomOffset => SizedBox(
        height: 75,
      );
}
