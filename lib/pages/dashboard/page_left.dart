import 'package:flutter/material.dart';
import 'package:book_hive/shared/const.dart';
import 'package:book_hive/shared/styles.dart';

class PageLeft extends StatelessWidget {
  const PageLeft({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: pageMarginValue, vertical: 0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: pageMarginValue),
            const Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [Text("Content  ", style: styleH5)],
            ),
          ],
        ),
      ),
    );
  }
}
