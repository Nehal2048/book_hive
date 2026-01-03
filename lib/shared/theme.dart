import 'package:flutter/material.dart';
import 'package:book_hive/shared/const.dart';
import 'package:book_hive/shared/styles.dart';

const textFontSize = 16.0;
const spacingNavBar = 40.0;

final ThemeData themeData = ThemeData(
  primarySwatch: primaryColor,
  canvasColor: Colors.white,
  scaffoldBackgroundColor: Colors.white,
  visualDensity: VisualDensity.adaptivePlatformDensity,
  iconTheme: const IconThemeData(color: Colors.black, size: 25),
  textSelectionTheme: const TextSelectionThemeData(
    selectionColor: cerulean,
    cursorColor: cerulean,
  ),
  fontFamily: 'Montserrat',
  textTheme: const TextTheme(
    bodyLarge: TextStyle(color: Colors.black),
    bodyMedium: TextStyle(color: Colors.black),
    bodySmall: TextStyle(color: Colors.black),
    displayLarge: TextStyle(color: Colors.black),
    displayMedium: TextStyle(color: Colors.black),
    displaySmall: TextStyle(color: Colors.black),
    headlineLarge: TextStyle(color: Colors.black),
    headlineMedium: TextStyle(color: Colors.black),
    headlineSmall: TextStyle(color: Colors.black),
    titleLarge: TextStyle(color: Colors.black),
    titleMedium: TextStyle(color: Colors.black),
    titleSmall: TextStyle(color: Colors.black),
    labelLarge: TextStyle(color: Colors.black),
    labelMedium: TextStyle(color: Colors.black),
    labelSmall: TextStyle(color: Colors.black),
  ),
  tabBarTheme: const TabBarThemeData(
    unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
    labelColor: Colors.white,
    labelStyle: TextStyle(
      color: Colors.white,
      fontWeight: FontWeight.w500,
      fontSize: 16,
    ),
    indicatorColor: Colors.white,
    tabAlignment: TabAlignment.center,
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: primaryColor,
    foregroundColor: Colors.black,
    shadowColor: Colors.white,
    actionsIconTheme: IconThemeData(color: Colors.white),
    elevation: 0,
    titleSpacing: 10,
    titleTextStyle: TextStyle(
      color: Colors.white,
      fontSize: 20,
      fontFamily: 'Poppins',
      fontWeight: FontWeight.w600,
    ),
    iconTheme: IconThemeData(color: Colors.white),
    toolbarTextStyle: TextStyle(
      color: Colors.white,
      fontWeight: FontWeight.w700,
      fontSize: 22,
    ),
  ),
  inputDecorationTheme: const InputDecorationTheme(
    hintStyle: TextStyle(
      color: greyMidDark,
      fontSize: 16.0,
      decorationColor: Colors.white,
      fontWeight: FontWeight.w500,
    ),
    prefixStyle: TextStyle(
      color: greyMidDark,
      fontSize: 16.0,
      fontWeight: FontWeight.w500,
      decorationColor: Colors.white,
    ),
    labelStyle: TextStyle(
      color: greyMidDark,
      fontSize: 16.0,
      fontWeight: FontWeight.w500,
      decorationColor: Colors.white,
    ),
    // isCollapsed: true,
    // isDense: true,
    filled: false,
    fillColor: greyLight,
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(10.0)),
      borderSide: BorderSide(color: Colors.red),
    ),
    errorStyle: TextStyle(
      color: Colors.red,
      fontSize: 14,
      fontWeight: FontWeight.w500,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(10.0)),
      borderSide: BorderSide(color: greyMid),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(10.0)),
      borderSide: BorderSide(color: greyMidDark),
    ),
    focusColor: Colors.grey,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(10.0)),
      borderSide: BorderSide(color: greyMidDark),
    ),
    disabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(10.0)),
      borderSide: BorderSide(color: greyMidDark),
    ),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
      elevation: 5,
      textStyle: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: Colors.white,
        fontFamily: "Poppins",
      ),
    ),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      textStyle: const TextStyle(
        color: primaryColor,
        fontSize: 22,
        fontWeight: FontWeight.w500,
        fontFamily: "Poppins",
      ),
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      padding: const EdgeInsets.symmetric(vertical: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: Colors.white,
      side: const BorderSide(color: primaryColor, width: 1.6),
      elevation: 5,
      textStyle: const TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w500,
        color: primaryColor,
      ),
    ),
  ),
  floatingActionButtonTheme: const FloatingActionButtonThemeData(
    backgroundColor: primaryColor,
    foregroundColor: Colors.white,
    iconSize: 25,
  ),
  dividerColor: primaryColor.withAlpha(60),
  snackBarTheme: const SnackBarThemeData(backgroundColor: greenPositive),
  dialogTheme: DialogThemeData(
    titleTextStyle: navBarTextStyle.copyWith(fontSize: 20, color: Colors.black),
    backgroundColor: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(10)),
    ),
  ),
  cardTheme: CardThemeData(
    elevation: 4,
    color: Colors.grey[100],
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
  ),
  colorScheme: const ColorScheme.light(
    primary: primaryColor,
    onPrimary: greyLightest,
    onSurface: cerulean,
  ).copyWith(surface: Colors.white).copyWith(error: primaryColor),
);

const greenPositive = Color(0xFF016d5a);
const cerulean = Color(0xFF7b9bd7);
const lightBlue = Color(0xFFd9effe);
const greyLightest = Color(0xFFf7f6f6);
const greyLight = Color(0xFFe6e6e7);
const greyMid = Color(0xFFa1a0a1);
const greyMidDark = Color(0xFF8b8a8a);

LinearGradient appbarGradientGimmick = const LinearGradient(
  colors: [primaryColor, Colors.transparent],
  begin: Alignment(0, 0.5),
  end: Alignment.bottomCenter,
);
