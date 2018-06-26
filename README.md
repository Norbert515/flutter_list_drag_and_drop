# flutter_list_drag_and_drop

A new Flutter package which handles all aspects of drag and drop inside a listView.

In your pubspec.yaml
```
dependencies:
  flutter_list_drag_and_drop: "^0.1.3"
```

## Note
The structure of this implementation has a few drawabacks. Back when I wrote this I made the mistake of using the Draggable class (I had no idea how to approache a drag&drop effect). Because using the draggable class following things happen:
- The items shown are in an overlay, which might pass other constraints then your listview
- The Draggable class adds a lot of unnecessary complexity to this implmenetation.

A better approache in my opition would be to use the Stack directly.
I might or might not rewrite some parts of this in the future.

## Demo
![Demo 1](https://github.com/Norbert515/flutter_list_drag_and_drop/blob/master/example/gifs/demo_1_small.gif)


## Features

- When dragging an item to the top/ bottom the list scroll accordingly 
- Works with different sized items
- material like behaviour 

## Take a look at the example folder for info on how to use



If you encounter feel free to open an issue.
Pull request are also welcome.
