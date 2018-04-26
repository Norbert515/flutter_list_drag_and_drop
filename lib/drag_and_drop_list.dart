import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:meta/meta.dart';

import 'my_draggable.dart';

typedef WidgetAndDelegate WidgetMakerAndDelegate<T>(BuildContext context, T item);

typedef Widget WidgetMaker<T>(BuildContext context, T item);

typedef void OnDragFinish(int oldIndex, int newIndex);

typedef bool CanAccept(int oldIndex, int newIndex);



class WidgetAndDelegate {
  final Widget widget;
  final DraggableDelegate delegate;

  WidgetAndDelegate(this.widget, this.delegate);
}


class DragAndDropList<T> extends StatefulWidget {
  final List<T> rowsData;

  final WidgetMaker itemBuilder;

  final WidgetMakerAndDelegate itemBuilderCustom;

  final OnDragFinish onDragFinish;

  final CanAccept canBeDraggedTo;

  final bool providesOwnDraggable;

  // dragElevation is only used if isItemsHaveCustomDraggableBehavior=false.
  // Otherwise, draggable items provide their own elevation/shadow.
  final double dragElevation;

  // Tilt is only used if isItemsHaveCustomDraggableBehavior=false.
  // Otherwise, draggable items provide their own draggable implementation.
  final double tilt;

  final Key key;
  
  DragAndDropList(this.rowsData,
      {@required this.itemBuilder,
        this.onDragFinish,
        @required this.canBeDraggedTo,
        this.dragElevation = 0.0,
        this.tilt = 0.0,
        this.key})
      : providesOwnDraggable = false,
        itemBuilderCustom = null,
        super(key: key);

  DragAndDropList.withCustomDraggableBehavior(this.rowsData,
      {@required this.itemBuilderCustom,
        this.onDragFinish,
        @required this.canBeDraggedTo,
        this.dragElevation = 0.0,
        this.tilt = 0.0,
        this.key})
      : providesOwnDraggable = true,
        itemBuilder = null,
        super(key: key);


  @override
  State<StatefulWidget> createState() => new _DragAndDropListState<T>();
}

class _DragAndDropListState<T> extends State<DragAndDropList> {
  final double _kScrollThreshold = 160.0;

  bool shouldScrollUp = false;
  bool shouldScrollDown = false;

  double _currentScrollPos = 0.0;

  ScrollController scrollController = new ScrollController();

  List<Data<T>> rows = new List<Data<T>>();

  //Index of the item dragged
  int _currentDraggingIndex;

  MyDraggableState currentDraggedState;

  // The height of the item being dragged
  double dragHeight;

  SliverMultiBoxAdaptorElement renderSliverContext;

  Data<T> draggedData;

  Offset _currentMiddle;

  //Index of the item currently accepting
  int _currentIndex;

  bool isScrolling = false;

  List<GlobalKey<MyDraggableState<Data>>> key = [];

  double sliverStartPos = 0.0;

  @override
  void initState() {
    super.initState();
    print("reset");
    List data = widget.rowsData;
    rows = data.map((it) => new Data<T>(it)).toList();
    for (int i = 0; i < rows.length; i++) {
      key.add(new GlobalKey());
    }
  }

  @override
  void didUpdateWidget(DragAndDropList<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    List data = widget.rowsData;
    rows = data.map((it) => new Data<T>(it)).toList();
    key.clear();
    for (int i = 0; i < rows.length; i++) {
      key.add(new GlobalKey());
    }
  }

  void _maybeScroll() {
    if (isScrolling) return;

    if (shouldScrollUp) {
      if (scrollController.position.pixels == 0.0) return;
      isScrolling = true;
      var scrollTo = scrollController.offset - 12.0;
      scrollController
          .animateTo(scrollTo, duration: new Duration(milliseconds: 74), curve: Curves.linear)
          .then((it) {
        updatePlaceholder();
        isScrolling = false;
        _maybeScroll();
      });
    }
    if (shouldScrollDown) {
      if (scrollController.position.pixels == scrollController.position.maxScrollExtent) return;
      isScrolling = true;
      var scrollTo = scrollController.offset + 12.0;
      scrollController
          .animateTo(scrollTo, duration: new Duration(milliseconds: 75), curve: Curves.linear)
          .then((it) {
        updatePlaceholder();
        isScrolling = false;
        _maybeScroll();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return new LayoutBuilder(
      builder: (BuildContext context3, constr) {
        return new ListView.builder(
          itemBuilder: (BuildContext context2, int index) {
            WidgetAndDelegate widgetAndDelegate;
            if (widget.providesOwnDraggable) {
              widgetAndDelegate = widget.itemBuilderCustom(context2, rows[index].data);
            } else {
              widgetAndDelegate =
              new WidgetAndDelegate(widget.itemBuilder(context2, rows[index].data), null);
            }
            return new DraggableListItem(
              child: widgetAndDelegate.widget,
              custom: widget.providesOwnDraggable,
              myKey: key[index],
              data: rows[index],
              index: index,
              tilt: widget.tilt,
              delegate: widgetAndDelegate.delegate,
              dragElevation: widget.dragElevation,
              draggedHeight: dragHeight,
              onDragStarted: (double draggedHeight) {
                _currentDraggingIndex = index;
                RenderBox rend = context3.findRenderObject();
                double start = rend.localToGlobal(new Offset(0.0, 0.0)).dy;
                double end = rend.localToGlobal(new Offset(0.0, rend.semanticBounds.height)).dy;

                sliverStartPos = start;
                currentDraggedState = key[index].currentState;
                draggedData = rows[index];

                // _buildOverlay(context2, start, end);

                renderSliverContext = context2;
                updatePlaceholder();
                dragHeight = draggedHeight;

                setState(() {
                  rows.removeAt(index);
                });
              },
              onDragCompleted: () {},
              onAccept: (Data data) {
                _accept(index, data);
              },
              onMove: (Offset offset) {
                _currentScrollPos = offset.dy;
                double screenHeight = MediaQuery.of(context2).size.height;

                if (offset.dy < _kScrollThreshold) {
                  shouldScrollUp = true;
                } else {
                  shouldScrollUp = false;
                }
                if (offset.dy > screenHeight - _kScrollThreshold) {
                  shouldScrollDown = true;
                } else {
                  shouldScrollDown = false;
                }
                _maybeScroll();
                updatePlaceholder();
              },
              cancelCallback: () {
                _accept(_currentIndex, draggedData);
              },
            );
          },
          controller: scrollController,
          itemCount: rows.length,
        );
      },
    );
  }

  void _complete() {
    shouldScrollUp = false;
    shouldScrollDown = false;
    _currentIndex = null;
    _currentScrollPos = 0.0;
    _currentMiddle = null;
    _currentDraggingIndex = null;
  }

  void _accept(int index, Data data) {
    setState(() {
      shouldScrollDown = false;
      shouldScrollUp = false;
      data.extraTop = 0.0;
      data.extraBot = 0.0;
      if (_currentMiddle.dy > _currentScrollPos) {
        rows.insert(index, data);
        widget.onDragFinish(_currentDraggingIndex, index);
      } else {
        rows.insert(index + 1, data);
        widget.onDragFinish(_currentDraggingIndex, index + 1);
      }
      rows.forEach((it) {
        it.extraTop = 0.0;
        it.extraBot = 0.0;
      });
    });
    _complete();
  }

  void updatePlaceholder() {
    if (renderSliverContext == null) return;
    if (_currentDraggingIndex == null) return;
    RenderSliverList it = renderSliverContext.findRenderObject();
    double buffer = sliverStartPos;
    RenderBox currentChild = it.firstChild;
    buffer += currentChild.size.height;
    while (_currentScrollPos > buffer) {
      if (currentChild != null) {
        var bufferChild = it.childAfter(currentChild);
        if (bufferChild == null) break;
        currentChild = bufferChild;
        buffer = it.childMainAxisPosition(currentChild) + currentChild.size.height + sliverStartPos;
      }
    }
    assert(currentChild != null);
    double middle = buffer - currentChild.size.height / 2;

    int index = it.indexOf(currentChild);
    if (!widget.canBeDraggedTo(_currentDraggingIndex, index)) return;

    _currentMiddle = new Offset(0.0, middle);
    _currentIndex = index;

    //TODO not so performant
    setState(() {
      rows.forEach((it) {
        it.extraTop = 0.0;
        it.extraBot = 0.0;
      });
    });

    if (_currentIndex >= rows.length) {
      _currentIndex--;
    }

    setState(() {
      if (_currentScrollPos > middle) {
        rows[_currentIndex].extraBot = dragHeight;
        rows[_currentIndex].extraTop = 0.0;
      } else {
        rows[_currentIndex].extraTop = dragHeight;
        rows[_currentIndex].extraBot = 0.0;
      }
    });
  }
}

class DraggableListItem extends StatelessWidget {
  final Data data;
  final int index;

  final double _kScrollThreashhold = 80.0;

  final double draggedHeight;

  final ValueChanged<double> onDragStarted;
  final VoidCallback onDragCompleted;
  final MyDragTargetAccept<Data> onAccept;
  final ValueChanged<Offset> onMove;
  final VoidCallback cancelCallback;

  final double dragElevation;

  Key myKey;

  final Widget child;

  DraggableDelegate delegate;

  final bool custom;

  final double tilt;

  DraggableListItem(
      {this.myKey,
        this.data,
        this.index,
        this.onDragStarted,
        this.onDragCompleted,
        this.onAccept,
        this.onMove,
        this.cancelCallback,
        this.draggedHeight,
        this.child,
        this.tilt,
        this.dragElevation,
        this.delegate,
        this.custom});

  @override
  Widget build(BuildContext context) {
    if (custom) {
      if (delegate != null) {
        delegate.onMove(onMove);
        delegate.onDragStarted(() {
          RenderBox it = context.findRenderObject() as RenderBox;
          onDragStarted(it.size.height);
        });
        delegate.onComplete(onDragCompleted);
        delegate.onCancel(cancelCallback);
      }

      return _getListChild(context);
    } else {
      return new LongPressMyDraggable<Data>(
          key: myKey,
          child: _getListChild(context),
          feedback: _getFeedback(index, context),
          data: data,
          onMove: onMove,
          onDragStarted: () {
            RenderBox it = context.findRenderObject() as RenderBox;
            onDragStarted(it.size.height);
          },
          onDragCompleted: onDragCompleted,
          onMyDraggableCanceled: (_, _2) {
            cancelCallback();
          });
    }
  }

  Widget _getListChild(BuildContext context) {
    return new MyDragTarget<Data>(
      builder: (BuildContext context, List candidateData, List rejectedData) {
        return new Column(
          children: <Widget>[
            new SizedBox(
              height: data.extraTop,
            ),
            child,
            new SizedBox(
              height: data.extraBot,
            ),
          ],
        );
      },
      onAccept: onAccept,
      onWillAccept: (data) {
        return true;
      },
    );
  }

  Widget _getFeedback(int index, BuildContext context) {
    var maxWidth = MediaQuery.of(context).size.width;
    return new ConstrainedBox(
      constraints: new BoxConstraints(maxWidth: maxWidth),
      child: new Transform(
        transform: new Matrix4.rotationZ(tilt),
        alignment: FractionalOffset.bottomRight,
        child: new Material(
          child: child,
          elevation: dragElevation,
          color: Colors.transparent,
          borderRadius: BorderRadius.zero,
        ),
      ),
    );
  }
}

class Data<T> {
  final T data;
  Color color = Colors.white;

  double extraTop;
  double extraBot;

  Data(this.data, {this.color, this.extraTop = 0.0, this.extraBot = 0.0});
}

class ListDraggable extends StatelessWidget {
  final Widget child;
  final bool longPress;
  final DraggableDelegate delegate;

  ListDraggable({this.child, this.longPress, this.delegate});

  @override
  Widget build(BuildContext context) {
    return child;
  }
}

class DraggableDelegate {
  VoidCallback onDragStartedListener;

  ValueChanged<Offset> onMoveListener;

  VoidCallback onDragCompleted;

  VoidCallback onCancelListener;

  void cancel() {
    if (onCancelListener != null) {
      onCancelListener();
    }
  }

  void onCancel(VoidCallback listener) {
    onCancelListener = listener;
  }

  void complete() {
    if (onDragCompleted != null) {
      onDragCompleted();
    }
  }

  void onComplete(VoidCallback listener) {
    onDragCompleted = listener;
  }

  void move(Offset offset) {
    if (onMoveListener != null) {
      onMoveListener(offset);
    }
  }

  void onMove(ValueChanged<Offset> listener) {
    onMoveListener = listener;
  }

  void startDrag() {
    if (onDragStartedListener != null) {
      onDragStartedListener();
    }
  }

  void onDragStarted(VoidCallback listener) {
    onDragStartedListener = listener;
  }
}
