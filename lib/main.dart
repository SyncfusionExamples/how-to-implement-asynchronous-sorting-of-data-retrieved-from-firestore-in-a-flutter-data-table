import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';
import 'employee.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: defaultFirebaseOptions);
  runApp(MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const SfDataGridDemo()));
}

const defaultFirebaseOptions = FirebaseOptions(
  apiKey: '',
  authDomain: '',
  projectId: '',
  storageBucket: '',
  messagingSenderId: '',
  appId: '',
);
StreamController<bool> loadingController = StreamController<bool>();

class SfDataGridDemo extends StatefulWidget {
  const SfDataGridDemo({Key? key}) : super(key: key);
  @override
  SfDataGridDemoState createState() => SfDataGridDemoState();
}

class SfDataGridDemoState extends State<SfDataGridDemo> {
  late EmployeeDataSource employeeDataSource;
  List<Employee> employeeData = [];

  @override
  void initState() {
    super.initState();
    employeeDataSource = EmployeeDataSource([]);
  }

  final getDataFromFireStore =
      FirebaseFirestore.instance.collection('Sync1').snapshots();
  Widget _buildDataGrid() {
    return StreamBuilder<QuerySnapshot>(
      stream: getDataFromFireStore,
      builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (snapshot.hasData) {
          for (var data in snapshot.data!.docs) {
            employeeData.add(Employee(
                id: data['id'],
                name: data['name'],
                designation: data['designation'],
                salary: data['salary'].toString()));
          }
          employeeDataSource = EmployeeDataSource(employeeData);
          return StreamBuilder<bool>(
              stream: loadingController.stream,
              builder: (context, snapshot) {
                return Stack(children: [
                  SfDataGrid(
                    source: employeeDataSource,
                    columns: getColumns,
                    allowSorting: true,
                    columnWidthMode: ColumnWidthMode.fill,
                    gridLinesVisibility: GridLinesVisibility.both,
                    headerGridLinesVisibility: GridLinesVisibility.both,
                  ),
                  if (snapshot.data == true)
                    const Center(
                      child: CircularProgressIndicator(),
                    ),
                ]);
              });
        } else {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Syncfusion Flutter Datagrid FireStore Demo'),
      ),
      body: _buildDataGrid(),
    );
  }
}

class EmployeeDataSource extends DataGridSource {
  EmployeeDataSource(this.employeeData) {
    _buildDataRow();
  }

  List<DataGridRow> dataGridRows = [];
  List<Employee> employeeData;

  void _buildDataRow() {
    dataGridRows = employeeData
        .map<DataGridRow>((e) => DataGridRow(cells: [
              DataGridCell<String>(columnName: 'id', value: e.id),
              DataGridCell<String>(columnName: 'name', value: e.name),
              DataGridCell<String>(
                  columnName: 'designation', value: e.designation),
              DataGridCell<String>(columnName: 'salary', value: e.salary),
            ]))
        .toList();
  }

  @override
  List<DataGridRow> get rows => dataGridRows;

  @override
  DataGridRowAdapter buildRow(
    DataGridRow row,
  ) {
    return DataGridRowAdapter(
        cells: row.getCells().map<Widget>((e) {
      return Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.all(8.0),
        child: Text(e.value.toString()),
      );
    }).toList());
  }

  bool isSuspend = true;
  @override
  Future<void> performSorting(List<DataGridRow> rows) async {
    if (!isSuspend || sortedColumns.isEmpty) {
      return;
    }
    loadingController.add(true);
    await Future<void>.delayed(const Duration(seconds: 2));
    loadingController.add(false);

    for (final column in sortedColumns) {
      if (column.sortDirection == DataGridSortDirection.ascending) {
        final snapshot = await FirebaseFirestore.instance
            .collection('Sync1')
            .orderBy(column.name)
            .get();
        fetchData(snapshot);
        buildData(employeeData);
        isSuspend = false;
        notifyListeners();
      } else if (column.sortDirection == DataGridSortDirection.descending) {
        final snapshot = await FirebaseFirestore.instance
            .collection('Sync1')
            .orderBy(column.name,
                descending:
                    column.sortDirection == DataGridSortDirection.descending)
            .get();
        fetchData(snapshot);
        buildData(employeeData);
        isSuspend = false;
        notifyListeners();
      }
    }

    isSuspend = true;
  }

  List<Employee> fetchData(QuerySnapshot<Map<String, dynamic>> snapshot) {
    return employeeData = snapshot.docs
        .map((data) => Employee(
              id: data['id'],
              name: data['name'],
              designation: data['designation'],
              salary: data['salary'].toString(),
            ))
        .toList();
  }

  List<DataGridRow> buildData(List<Employee> employeeData) {
    return dataGridRows = employeeData
        .map<DataGridRow>((e) => DataGridRow(cells: [
              DataGridCell<String>(columnName: 'id', value: e.id),
              DataGridCell<String>(columnName: 'name', value: e.name),
              DataGridCell<String>(
                  columnName: 'designation', value: e.designation),
              DataGridCell<String>(columnName: 'salary', value: e.salary),
            ]))
        .toList();
  }
}

List<GridColumn> get getColumns {
  return <GridColumn>[
    GridColumn(
        columnName: 'id',
        label: Container(
            padding: const EdgeInsets.all(16.0),
            alignment: Alignment.center,
            child: const Text(
              'ID',
            ))),
    GridColumn(
        columnName: 'name',
        label: Container(
            padding: const EdgeInsets.all(8.0),
            alignment: Alignment.center,
            child: const Text('Name'))),
    GridColumn(
        columnName: 'designation',
        label: Container(
            padding: const EdgeInsets.all(8.0),
            alignment: Alignment.center,
            child: const Text(
              'Designation',
              overflow: TextOverflow.ellipsis,
            ))),
    GridColumn(
        columnName: 'salary',
        label: Container(
            padding: const EdgeInsets.all(8.0),
            alignment: Alignment.center,
            child: const Text('Salary'))),
  ];
}
