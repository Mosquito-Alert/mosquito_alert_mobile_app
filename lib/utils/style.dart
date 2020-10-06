import 'dart:io';

import 'package:flutter/material.dart';

class Style {
  //Colors
  static final Color colorPrimary = Color(0XFFF0A402);
  static final Color textColor = Color(0XFF282828);
  static final Color greyColor = Colors.black.withOpacity(0.5);

  //UI
  static Icon get iconBack =>
      Platform.isIOS ? Icon(Icons.arrow_back_ios) : Icon(Icons.arrow_back);

  // Texts
  static Widget title(
    text, {
    color,
    maxLines,
    textAlign,
    double fontSize,
    height,
  }) {
    return Text(
      text != null ? text : '',
      maxLines: maxLines,
      textAlign: textAlign != null ? textAlign : TextAlign.left,
      overflow: maxLines != null ? TextOverflow.ellipsis : null,
      style: TextStyle(
        height: height,
        color: color == null ? textColor : color,
        fontSize: fontSize == null ? 21 : fontSize,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  static Widget titleMedium(
    text, {
    color,
    maxLines,
    textAlign,
    double fontSize,
    height,
  }) {
    return Text(
      text != null ? text : '',
      maxLines: maxLines,
      textAlign: textAlign != null ? textAlign : TextAlign.left,
      overflow: maxLines != null ? TextOverflow.ellipsis : null,
      style: TextStyle(
        height: height,
        color: color == null ? textColor : color,
        fontSize: fontSize == null ? 21 : fontSize,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  static Widget body(
    text, {
    color,
    maxLines,
    textAlign,
    double fontSize,
    height,
  }) {
    return Text(
      text != null ? text : '',
      maxLines: maxLines,
      textAlign: textAlign != null ? textAlign : TextAlign.left,
      overflow: maxLines != null ? TextOverflow.ellipsis : null,
      style: TextStyle(
        height: height,
        color: color == null ? textColor : color,
        fontSize: fontSize == null ? 14 : fontSize,
      ),
    );
  }

  static Widget bodySmall(
    text, {
    color,
    maxLines,
    textAlign,
    double fontSize,
    height,
  }) {
    return Text(
      text != null ? text : '',
      maxLines: maxLines,
      textAlign: textAlign != null ? textAlign : TextAlign.left,
      overflow: maxLines != null ? TextOverflow.ellipsis : null,
      style: TextStyle(
        height: height,
        color: color == null ? textColor : color,
        fontSize: fontSize == null ? 12 : fontSize,
      ),
    );
  }

  ///Buttons

  static Widget button(text, onPressed,
      {color, textColor, borderColor, elevation}) {
    return RaisedButton(
      onPressed: onPressed,
      elevation: 0,
      highlightElevation: 0,
      hoverElevation: 0,
      highlightColor: color != null ? color : colorPrimary.withOpacity(0.5),
      padding: EdgeInsets.symmetric(vertical: 14),
      color: color != null ? color : colorPrimary,
      disabledColor: color != null
          ? color.withOpacity(0.3)
          : colorPrimary.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(
        text,
        style: TextStyle(
            color: textColor != null ? textColor : Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500),
      ),
    );
  }

  static Widget noBgButton(text, onPressed, {textColor, borderColor}) {
    return RaisedButton(
      onPressed: onPressed,
      elevation: 0,
      highlightElevation: 0,
      hoverElevation: 0,
      highlightColor: colorPrimary.withOpacity(0.5),
      padding: EdgeInsets.symmetric(vertical: 14),
      color: Colors.transparent,
      disabledColor: Colors.white.withOpacity(0.3),
      textColor: textColor != null ? textColor : Colors.black,
      disabledTextColor: textColor != null
          ? textColor.withOpacity(0.3)
          : Colors.black.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(
        text,
        style: TextStyle(
          // color: textColor != null ? textColor : Colors.black,
          fontSize: 14,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  static Widget loginButton(icon, text, color, colorText, onPressed,
      {colorBorder}) {
    return Container(
      height: 50,
      child: RaisedButton(
        elevation: 2,
        onPressed: onPressed,
        padding: EdgeInsets.all(0),
        color: color,
        shape: RoundedRectangleBorder(
          borderRadius: new BorderRadius.circular(3.0),
          side: BorderSide(
              color: colorBorder != null ? colorBorder : color,
              width: 1,
              style: BorderStyle.solid),
        ),
        child: Stack(
          children: <Widget>[
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                width: 55,
                child: icon,
              ),
            ),
            Center(
              child: Text(
                text,
                style: TextStyle(color: colorText, fontSize: 15),
              ),
            )
          ],
        ),
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
      textCapitalization: textCapitalization == null
          ? TextCapitalization.none
          : textCapitalization,
      autofocus: false,
      controller: controller,
      style: TextStyle(
          fontSize: 15,
          color: enabled ? textColor : textColor.withOpacity(0.6)),
      textInputAction:
          textInputAction == null ? TextInputAction.done : textInputAction,
      focusNode: focusNode,
      obscureText: obscure == null ? false : obscure,
      decoration: textFieldDecoration(hint, suffixIcon),
      maxLines:
          expands != null && expands || keyboardType == TextInputType.multiline
              ? null
              : 1,
      expands: expands != null ? expands : false,
      textAlignVertical: textAlignVertical != null
          ? textAlignVertical
          : TextAlignVertical.center,
      textAlign: TextAlign.start,
      enabled: enabled != null ? enabled : true,
      onChanged: handleChange != null ? handleChange : null,
    );
  }

  static InputDecoration textFieldDecoration(hint, suffixIcon) {
    return InputDecoration(
        suffixIcon: suffixIcon == null ? null : suffixIcon,
        filled: true,
        fillColor: Colors.white,
        hintText: hint,
        hintMaxLines: 5,
        hintStyle: TextStyle(fontSize: 17),
        contentPadding: EdgeInsets.fromLTRB(15.0, 16.0, 10.0, 16.0),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(3.0),
          borderSide:
              BorderSide(color: Colors.black.withOpacity(0.1), width: 1),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(3.0),
          borderSide:
              BorderSide(color: Colors.black.withOpacity(0.1), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(3.0),
          borderSide:
              BorderSide(color: Colors.black.withOpacity(0.1), width: 1),
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
