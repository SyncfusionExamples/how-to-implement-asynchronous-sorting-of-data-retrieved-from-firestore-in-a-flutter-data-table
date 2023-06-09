# How to implement asynchronous sorting of data retrieved from Firestore in a Flutter DataTable (SfDataGrid)?

In this article, we will discuss how to implement asynchronous sorting in a [Flutter DataGrid](https://www.syncfusion.com/flutter-widgets/flutter-datagrid) that retrieves data from Firestore. We will cover the steps and techniques required to fetch data from Firestore, handle asynchronous operations, and dynamically sort the data based on user interactions.

## STEP 1:
You need to add the following package in the dependencies of pubspec.yaml.

```dart
firebase_core: ^2.13.0
cloud_firestore: ^4.7.1

 ```

## STEP 2: 
Import the following library into the flutter application:

 ```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

 ```

## STEP 3:
Initialize the [SfDataGrid](https://pub.dev/documentation/syncfusion_flutter_datagrid/latest/datagrid/SfDataGrid-class.html) with all the required details. Fetch the data from the Firestore database by passing the required collection name. The [StreamController](https://api.flutter.dev/flutter/dart-async/StreamController-class.html) that will be used to control the loading state. It will emit true or false values to show or hide the loading indicator.

 ```dart
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

 ```

## STEP 4:
The performSorting method accepts a list of DataGridRow objects as input. It includes a simulated asynchronous that applies the [Future.delay](https://api.flutter.dev/flutter/dart-async/Future/Future.delayed.html) for a specific time to imitate server-side processing. Upon completion of the delay, the loadingController is updated to signal the end of loading. If the current column's sortDirection is set to ascending, the dataGridRow variable is assigned a new list of DataGridRow objects. Each row represents an employee, with cells containing their respective attributes. The isSuspend variable is then set to false, indicating the completion of the sorting process. If the sortDirection is descending, the same steps are followed.

```dart
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

 ```