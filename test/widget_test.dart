import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/material.dart';
import 'package:flutter_list_drag_and_drop/drag_and_drop_list.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testSwap();
}

void testSwap() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    List<String> items = [
      '0',
      '1',
      '2',
      '3',
      '4',
      '5',
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

    double tileSize = 64.0;

    StatefulBuilder app = new StatefulBuilder(
      builder: (BuildContext context, StateSetter setState) {
        return new MaterialApp(
          home: new DragAndDropList(
            items.length,
            itemBuilder: (BuildContext context, index) {
              return new SizedBox(
                height: tileSize,
                child: new Card(
                  child: new ListTile(
                    title: new Text(items[index]),
                  ),
                ),
              );
            },
            onDragFinish: (before, after) {
              setState(() {
                String data = items[before];
                items.removeAt(before);
                items.insert(after, data);
              });
            },
            canBeDraggedTo: (one, two) => true,
          ),
        );
      },
    );
    // Build our app and trigger a frame.
    await tester.pumpWidget(app);

    // Verify that our counter starts at 0.
    expect(find.text('0'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(find.text('4'), findsOneWidget);
    expect(find.text('5'), findsOneWidget);
    expect(find.text('6'), findsOneWidget);
    expect(find.text('7'), findsOneWidget);
    expect(find.text('8'), findsOneWidget);
    expect(find.text('16'), findsNothing);

    await longPressDrag(find.text('0'), tester, new Offset(0.0, tileSize * 5));

    print(items);
    expect(items[0], '1');
    expect(items[1], '2');
    expect(items[2], '3');
    expect(items[4], '5');
    expect(items[5], '0');
    expect(items[6], '6');
    expect(items[7], '7');
    expect(items[8], '8');

    await longPressDragOffset(
        new Offset(100.0, tileSize * 5), tester, new Offset(0.0, tileSize * 2));
    expect(items[0], '1');
    expect(items[1], '2');
    expect(items[2], '3');
    expect(items[3], '4');
    expect(items[4], '0');
    expect(items[5], '6');
    expect(items[6], '7');
    expect(items[7], '5');
    print(items);

    await longPressDragOffset(
        new Offset(100.0, tileSize * 6), tester, new Offset(0.0, tileSize * 2));
    expect(items[0], '1');
    expect(items[1], '2');
    expect(items[2], '3');
    expect(items[3], '4');
    expect(items[4], '0');
    expect(items[5], '7');
    expect(items[6], '5');
    expect(items[7], '6');
    print(items);

    await longPressDragOffset(
        new Offset(100.0, tileSize * 5), tester, new Offset(0.0, tileSize * 2));
    expect(items[0], '1');
    expect(items[1], '2');
    expect(items[2], '3');
    expect(items[3], '4');
    expect(items[4], '7');
    expect(items[5], '5');
    expect(items[6], '6');
    expect(items[7], '0');
    print(items);
  });
}

/// Dispatch a pointer down / pointer up sequence at the given location with
/// a delay of [kLongPressTimeout] + [kPressTimeout] between the two events.
Future<Null> longPressDrag(Finder finder, WidgetTester tester, Offset dragOffset) {
  Offset location = tester.getCenter(finder);
  return TestAsyncUtils.guard(() async {
    final TestGesture gesture = await tester.startGesture(location);
    await tester.pump(kLongPressTimeout + kPressTimeout);
    await gesture.moveBy(dragOffset);
    await tester.pump(kLongPressTimeout + kPressTimeout);
    await gesture.up();
    return null;
  });
}

/// Dispatch a pointer down / pointer up sequence at the given location with
/// a delay of [kLongPressTimeout] + [kPressTimeout] between the two events.
Future<Null> longPressDragOffset(Offset location, WidgetTester tester, Offset dragOffset) {
  return TestAsyncUtils.guard(() async {
    final TestGesture gesture = await tester.startGesture(location);
    await tester.pump(kLongPressTimeout + kPressTimeout);
    await gesture.moveBy(dragOffset, timeStamp: new Duration(seconds: 2));
    await tester.pump(kLongPressTimeout + kPressTimeout);
    await gesture.up();
    return null;
  });
}
