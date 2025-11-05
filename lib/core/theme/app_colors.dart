import 'package:flutter/material.dart';

class AppColors {
  static const Color darkPitch = Color(0xFF121212);

  static const Color gameOnGreen = Color(0xFF32A847);
  static const Color brightGold = Color(0xFFFFC700);

  static const Color darkCard = Color(0xFF1F1F1F);
  static const Color darkCardSecondary = Color(0xFF1A1A1A);

  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color grey = Color(0xFF666666);
  static const Color lightGrey = Color(0xFF888888);
  static const Color red = Color(0xFFFF4444);
  static const Color green = Color(0xFF44FF44);

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [gameOnGreen, brightGold],
  );

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [darkCard, darkCardSecondary],
  );
}
