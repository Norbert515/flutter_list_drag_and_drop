import 'package:flutter/material.dart';
import 'package:flutter_list_drag_and_drop/drag_and_drop_list.dart';

void main() {
  runApp(new TestApp());
}

class TestApp extends StatelessWidget {
  TestApp({Key key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      title: 'Flutter Demo',
      theme: new ThemeData(primarySwatch: Colors.blue, primaryColor: new Color(0xffd05c6b)),
      home: new MyHomePage(
        title: 'Flutter Demo Home Page',
        key: key,
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);
  final String title;

  @override
  MyHomePageState createState() => new MyHomePageState();
}

class MyHomePageState extends State<MyHomePage> {
  List<String> items = [
    '0',
    '1',
    'Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua. At vero eos et accusam et justo duo dolores et ea rebum. Stet clita kasd gubergren, no sea takimata sanctus est Lorem ipsum dolor sit amet. Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua.',
    '3',
    '4',
    'Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua.',
    '6',
    '7',
    '8',
    '9',
    '10',
    '11',
    '12',
    '13',
    '14',
    '15',
  ];
  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
        title: new Text(widget.title),
      ),
      body: new DragAndDropList(
        items.length,
        itemBuilder: (BuildContext context, index) {
          return new SizedBox(
            child: new Card(
              child: new ListTile(
                title: new Text(items[index]),
              ),
            ),
          );
        },
        onDragFinish: (before, after) {
          print('on drag finish $before $after');
          String data = items[before];
          items.removeAt(before);
          items.insert(after, data);
        },
//        canDrag: (index) {
//          print('can drag $index');
//          return index != 3; //disable drag for index 3
//        },
        canBeDraggedTo: (one, two) => true,
        dragElevation: 8.0,
      ),
    );
  }
}
