import 'package:flutter/material.dart';

class AppStyles {
  static const Color backgroundColor = Color(0xFF232C38);
  static const Color lightBackgroundColor = Color(0xFFEDEDED);
  static const Color numericButtonBackgroundColor = Color(0xFFD8D8D8);

  static TextStyle numericButtonTextStyle = const TextStyle(
    fontSize: 24,
    color: Colors.black,
    fontWeight: FontWeight.bold,
  );

  static TextStyle enterPinTextStyle = const TextStyle(
      fontSize: 48,
      color: Colors.white,
      fontWeight: FontWeight.bold,
      letterSpacing: 10);

  static TextStyle mediumTextStyle = const TextStyle(
    fontSize: 16,
    color: Colors.white60,
    fontWeight: FontWeight.bold,
  );

  static TextStyle confirmButtonTextStyle = const TextStyle(
    fontSize: 24,
    color: Colors.white,
    fontWeight: FontWeight.bold,
  );

  static const _textSizeLarge = 25.0;
  static const _textSizeMedium = 20.0;
  static const _textSizeSmall = 16.0;

  static final Color _buttonColorGreen = _hexToColor('666666');

  static const textInputStyle = TextStyle(
      fontSize: _textSizeSmall,
      color: Colors.white,
      decorationColor: Colors.white);

  static const textInputHintStyle = TextStyle(color: Color(0x50FFFFFF));

  static const buttonTestSmall =
      TextStyle(fontSize: _textSizeSmall, color: Colors.white);
  static const headerTextLarge =
      TextStyle(fontSize: _textSizeLarge, color: Colors.white);

  static Color _hexToColor(String code) {
    return Color(int.parse(code.substring(0, 6), radix: 16) + 0xFF000000);
  }
}
