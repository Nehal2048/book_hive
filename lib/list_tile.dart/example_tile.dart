import 'package:flutter/material.dart';
import 'package:book_hive/models/example_model.dart';

class ExampleTile extends StatelessWidget {
  final ExampleModel exampleModel;

  const ExampleTile({super.key, required this.exampleModel});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: const Text('ListTile with red background'),
      trailing: Text(exampleModel.depot),
      tileColor: Colors.red,
    );
  }
}
