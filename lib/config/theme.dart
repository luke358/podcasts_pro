import 'package:flutter/material.dart';

// 颜色配置
class ThemeColor {
  static const Color primary = Color(0xff3853e2);
  static const Color text = Color(0xFF000000);

  static const Color success = Color(0xff07c160);

  static const Color danger = Color(0xffee0a24);

  static const Color warning = Color(0xffffba00);

  static const Color info = Color(0xff00a1d6);

  static const Color active = Color(0xff3853e2);

  static const Color unactive = Color(0xff7b7b7b);

  static const Color un2active = Color(0xff8d8d8d);

  static const Color un3active = Color(0xffb1b1b1);

  static const Color page = Color(0xffffffff);

  static const Color nav = Color(0xffffffff);

  static const Color border = Color(0xfff5f5f5);

  // 颜色值转换
  static Color string2Color(String colorString) {
    int value = 0x00000000;
    if (colorString.isNotEmpty) {
      if (colorString[0] == '#') {
        colorString = colorString.substring(1);
      }
      value = int.tryParse(colorString, radix: 16) ?? 0x00000000;
      if (value < 0xFF000000) {
        value += 0xFF000000;
      }
    }
    return Color(value);
  }
}
