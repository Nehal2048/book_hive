import 'package:flutter/material.dart';
import 'package:book_hive/models/example_model.dart';
import 'package:book_hive/shared/const.dart';

class EventsListPage extends StatelessWidget {
  final List<ExampleModel> list;

  const EventsListPage({super.key, required this.list});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Page With List Example")),
      body: Container(
        margin: EdgeInsets.all(pageMarginValue),
        child: ListView.separated(
          itemBuilder: (BuildContext context, int index) {
            return Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 5),
                  Text(
                    "    ID: ${list[index].dealerID}",
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    "    Depot: ${list[index].depot}",
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    "    Name: ${list[index].name}",
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 5),
                ],
              ),
            );
          },
          separatorBuilder: (context, index) =>
              SizedBox(height: separatorValueDefault),
          itemCount: list.length,
        ),
      ),
    );
  }
}
