import 'package:flutter/material.dart';
import 'package:book_hive/shared/const.dart';

class TestPage extends StatelessWidget {
  const TestPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Name")),
      body: Container(margin: EdgeInsets.all(pageMarginValue)),
    );
  }
}
