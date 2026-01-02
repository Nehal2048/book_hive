import 'package:book_hive/shared/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

showLoaderDialog(BuildContext context, bool? dismissable) {
  showDialog(
    barrierDismissible: dismissable ?? false,
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        content: Container(
          height: 300,
          padding: const EdgeInsets.all(15),
          child: const Loading(),
        ),
      );
    },
  );
}

copyToClipBoard(data) async {
  await Clipboard.setData(ClipboardData(text: data));
}

String formatDate(DateTime date) {
  final months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  return '${date.day.toString().padLeft(2, '0')} ${months[date.month - 1]} ${date.year}';
}
