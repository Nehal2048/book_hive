import 'package:flutter/material.dart';
import 'package:book_hive/list_tile.dart/example_tile.dart';
import 'package:book_hive/pages/list_pages/example_list_page.dart';
import 'package:book_hive/shared/const.dart';
import 'package:book_hive/shared/test_data.dart';
import 'package:book_hive/shared/widgets.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: pageMarginValue, vertical: 0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: pageMarginValue),
            DashboardTitle(
              title: "List View Example",
              onTapSeeMore: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EventsListPage(list: exampleModelList),
                  ),
                );
              },
            ),
            const SizedBox(height: 30),
            SizedBox(
              height: 300,
              child: ListView.separated(
                physics: const NeverScrollableScrollPhysics(), // new
                separatorBuilder: (context, index) =>
                    SizedBox(width: separatorValueDefault),
                itemCount: exampleModelList.length,
                scrollDirection: Axis.vertical,
                itemBuilder: (BuildContext context, int index) {
                  return ExampleTile(exampleModel: exampleModelList[index]);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
