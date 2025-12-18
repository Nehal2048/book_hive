import 'package:flutter/material.dart';
import 'package:book_hive/models/example_model.dart';
import 'package:book_hive/services/app_controller.dart';
import 'package:book_hive/shared/const.dart';
import 'package:book_hive/shared/shared_functions.dart';
import 'package:book_hive/shared/widgets.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_instance/src/extension_instance.dart';

class ExampleTablePage extends StatefulWidget {
  final List<ExampleModel> exampleList;

  const ExampleTablePage({Key? key, required this.exampleList})
    : super(key: key);

  @override
  State<ExampleTablePage> createState() => _ExampleTablePageState();
}

class _ExampleTablePageState extends State<ExampleTablePage> {
  late List<ExampleModel> exampleList;
  List<ExampleModel> sortedExampleList = [];
  List<ExampleModel> selectedExample = [];

  int? sortColumnIndex;
  bool isAscending = false;

  String? criteriaDropdown;
  String criteriaSearch = "";

  final AppController c = Get.put(AppController());

  @override
  void initState() {
    super.initState();
    exampleList = widget.exampleList;
    sortList();
    clearCriterias();
  }

  sortList() {
    sortedExampleList = exampleList;
    if (criteriaDropdown != "" && criteriaDropdown != null) {
      sortedExampleList = sortedExampleList
          .where((element) => element.depot == criteriaDropdown)
          .toList();
    }

    sortedExampleList = sortedExampleList
        .where(
          (element) =>
              element.depot.toLowerCase().contains(
                criteriaSearch.toLowerCase(),
              ) ||
              element.name.toLowerCase().contains(
                criteriaSearch.toLowerCase(),
              ) ||
              element.dealerID.toLowerCase().contains(
                criteriaSearch.toLowerCase(),
              ),
        )
        .toList();

    setState(() {});
  }

  clearCriterias() {
    criteriaSearch = "";
    sortColumnIndex = null;
    isAscending = false;
    criteriaDropdown = null;
    sortList();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 20),
          SizedBox(
            height: filterHeight,
            child: Wrap(
              runSpacing: 20.0,
              spacing: 20.0,
              runAlignment: WrapAlignment.center,
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SizedBox(
                  width: 300,
                  child: TextFormField(
                    enableInteractiveSelection: true,
                    decoration: const InputDecoration(
                      labelText: "Search Criteria",
                      hintText: "Eg. Name, ID, Depot",
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: ((value) => setState(() {
                      criteriaSearch = value;
                      sortList();
                    })),
                  ),
                ),
                SizedBox(
                  height: filterHeight,
                  width: 200,
                  child: DropdownCustom(
                    label: "Options",
                    hintText: 'Showing All',
                    listOfItems: exampleOptions,
                    value: criteriaDropdown,
                    onChanged: (selection) => setState(() {
                      criteriaDropdown = selection;
                      sortList();
                    }),
                  ),
                ),
                IconButton(
                  tooltip: "Remove Filters",
                  splashRadius: 20,
                  iconSize: 20,
                  icon: const Icon(Icons.refresh, color: primaryColor),
                  onPressed: clearCriterias,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: (exampleList.isEmpty || exampleList == [])
                  ? const SizedBox(
                      height: 600,
                      width: 200,
                      child: Center(child: Text("No Data Found")),
                    )
                  : SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: buildDataTable(MediaQuery.of(context).size.width),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildDataTable(double screenWidth) {
    return DataTable(
      columnSpacing: 20,
      sortColumnIndex: sortColumnIndex,
      sortAscending: isAscending,
      showCheckboxColumn: false,
      columns: getColumns(screenWidth),
      rows: getRows(sortedExampleList, screenWidth),
    );
  }

  getColumns(double screenWidth) {
    final columnsHeading = [
      'Dealer Id',
      'Dealer Name',
      'Sales Depot',
      'Actions',
    ];

    return columnsHeading.map((e) {
      return DataColumn(
        label: Text(e),
        onSort: (e == "Actions") ? null : onSort,
      );
    }).toList();
  }

  getRows(List<ExampleModel> dealers, double screenWidth) => dealers
      .map(
        ((e) => DataRow(
          cells: [
            DataCell(
              SizedBox(width: 90, child: Text(e.dealerID)),
              onTap: () async => copyToClipBoard(e.dealerID),
            ),
            DataCell(
              SizedBox(width: 300, child: Text(e.name)),
              onTap: () async => copyToClipBoard(e.name),
            ),
            DataCell(
              Text(e.depot),
              onTap: () async => copyToClipBoard(e.depot),
            ),
            DataCell(
              Center(
                child: IconButton(
                  splashRadius: 20,
                  iconSize: 15,
                  tooltip: "Edit Dealer Info",
                  icon: const Icon(Icons.edit, color: primaryColor),
                  onPressed: () {},
                ),
              ),
            ),
          ],
        )),
      )
      .toList();

  void onSort(int columnIndex, bool ascending) {
    switch (columnIndex) {
      case 0:
        sortedExampleList.sort(
          (a, b) => compareString(ascending, a.dealerID, b.dealerID),
        );
        break;
      case 1:
        sortedExampleList.sort(
          (a, b) => compareString(ascending, a.name, b.name),
        );
        break;
      case 2:
        sortedExampleList.sort(
          (a, b) => compareString(ascending, a.depot, b.depot),
        );
        break;
      default:
        sortedExampleList.sort(
          (a, b) => compareString(ascending, a.depot, b.depot),
        );
        break;
    }

    setState(() {
      sortColumnIndex = columnIndex;
      isAscending = ascending;
    });
  }

  int compareString(bool ascending, String value1, String value2) =>
      ascending ? value1.compareTo(value2) : value2.compareTo(value1);
}
