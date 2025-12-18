import 'package:flutter/material.dart';
import 'package:book_hive/shared/theme.dart';

const TextStyle navBarTextStyle = TextStyle(
  color: Colors.white,
  fontSize: 22,
  fontWeight: FontWeight.bold,
  fontFamily: 'Montserrat',
);

const TextStyle styleH2 = TextStyle(
  color: Colors.black,
  fontWeight: FontWeight.w600,
  fontSize: 25,
);

const TextStyle styleH3 = TextStyle(
  color: Colors.black,
  fontWeight: FontWeight.w600,
  fontSize: 20,
);

const TextStyle styleH4 = TextStyle(color: Colors.black, fontSize: 20);

const TextStyle styleH5 = TextStyle(
  color: Colors.black,
  fontSize: 18,
  fontWeight: FontWeight.bold,
);

const TextStyle styleH6 = TextStyle(
  color: Colors.black,
  fontSize: 14,
  fontWeight: FontWeight.w600,
);

const TextStyle styleHyperLinks = TextStyle(
  color: Colors.blue,
  fontSize: 14,
  fontWeight: FontWeight.w500,
  decoration: TextDecoration.underline,
);

BoxDecoration whiteBodyGreyBordered = BoxDecoration(
  borderRadius: const BorderRadius.all(Radius.circular(10)),
  border: Border.all(color: greyMid),
  color: Colors.white,
);

const TextStyle dropdownHintStyle = TextStyle(
  fontSize: 16,
  fontWeight: FontWeight.w500,
  color: greyMid,
);

const TextStyle dropdownItemTextStyle = TextStyle(
  fontSize: 16,
  fontWeight: FontWeight.w500,
  color: greyMidDark,
);
