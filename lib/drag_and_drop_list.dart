import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'my_draggable.dart';

typedef Widget WidgetMaker<T>(BuildContext context, int index);

typedef void OnDragFinish(int oldIndex, int newIndex);

typedef bool CanAccept(int oldIndex, int newIndex);

typedef bool CanDrag(int index);

class DragAndDropList extends StatefulWidget {
  final int rowsCount;

  final WidgetMaker itemBuilder;

  final CanDrag canDrag;

  final OnDragFinish onDragFinish;

  final CanAccept canBeDraggedTo;

  // dragElevation is only used if isItemsHaveCustomDraggableBehavior=false.
  // Otherwise, draggable items provide their own elevation/shadow.
  final double dragElevation;

  DragAndDropList(
    this.rowsCount, {
    Key key,
    @required this.itemBuilder,
    this.onDragFinish,
    @required this.canBeDraggedTo,
    this.dragElevation = 0.0,
    this.canDrag,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => new _DragAndDropListState();
}

class _DragAndDropListState extends State<DragAndDropList> {
  final double _kScrollThreshold = 160.0;

  bool shouldScrollUp = false;
  bool shouldScrollDown = false;

  double _currentScrollPos = 0.0;

  ScrollController scrollController = new ScrollController();

  List<Data> rows = new List<Data>();

  //Index of the item dragged
  int _currentDraggingIndex;

  // The height of the item being dragged
  double dragHeight;

  SliverMultiBoxAdaptorElement renderSliverContext;

  Data draggedData;

  Offset _currentMiddle;

  //Index of the item currently accepting
  int _currentIndex;

  bool isScrolling = false;

  double offsetToStartOfItem = 0.0;

  double sliverStartPos = 0.0;

  bool didJustStartDragging = false;

  // This corrects the case when the user grabs the card at the bottom, the system will always handle like grabbed on the middle to ensure correct behvior
  double middleOfItemInGlobalPosition = 0.0;

  @override
  void initState() {
    super.initState();
    populateRowList();
  }

  void populateRowList() {
    print('populateRowList');
    rows = [];
    for (int i = 0; i < widget.rowsCount; i++) {
      rows.add(Data(i));
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
      //TODO implement
      // Scrollable.ensureVisible(context, );
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
  void didUpdateWidget(DragAndDropList oldWidget) {
    super.didUpdateWidget(oldWidget);
    populateRowList();
  }

  @override
  Widget build(BuildContext context) {
    return new LayoutBuilder(
      builder: (BuildContext context3, constr) {
        return new ListView.builder(
          itemBuilder: (BuildContext context2, int index) {
            return _getDraggableListItem(context2, index, context3);
          },
          controller: scrollController,
          itemCount: rows.length,
        );
      },
    );
  }

  Widget _getDraggableListItem(BuildContext context2, int index, BuildContext context3) {
    var draggableListItem = new DraggableListItem(
      child: widget.itemBuilder(context2, rows[index].index),
      key: new ValueKey(rows[index]),
      data: rows[index],
      index: index,
      dragElevation: widget.dragElevation,
      draggedHeight: dragHeight,
      canDrag: widget.canDrag,
      onDragStarted: (double draggedHeight, double globalTopPositionOfDraggedItem) {
        _currentDraggingIndex = index;
        RenderBox rend = context3.findRenderObject();
        double start = rend.localToGlobal(new Offset(0.0, 0.0)).dy;
        double end = rend.localToGlobal(new Offset(0.0, rend.semanticBounds.height)).dy;

        didJustStartDragging = true;
        _currentScrollPos = start;

        middleOfItemInGlobalPosition = globalTopPositionOfDraggedItem + draggedHeight / 2;

        sliverStartPos = start;
        draggedData = rows[index];

        // _buildOverlay(context2, start, end);

        renderSliverContext = context2;
        updatePlaceholder();
        dragHeight = draggedHeight;

        setState(() {
          print('rows.removeAt($index)');
          rows.removeAt(index);
        });
      },
      onDragCompleted: () {
        _accept(index, draggedData);
      },
      onAccept: (Data data) {
        _accept(index, data);
      },
      onMove: (Offset offset) {
        if (didJustStartDragging) {
          didJustStartDragging = false;
          offsetToStartOfItem = offset.dy - middleOfItemInGlobalPosition;
          _currentScrollPos = offset.dy - offsetToStartOfItem;
        }
        _currentScrollPos = offset.dy - offsetToStartOfItem;
        double screenHeight = MediaQuery.of(context2).size.height;

        if (_currentScrollPos < _kScrollThreshold) {
          shouldScrollUp = true;
        } else {
          shouldScrollUp = false;
        }
        if (_currentScrollPos > screenHeight - _kScrollThreshold) {
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
    return draggableListItem;
  }

  void _complete() {
    shouldScrollUp = false;
    shouldScrollDown = false;
    _currentIndex = null;
    _currentScrollPos = 0.0;
    _currentMiddle = null;
    _currentDraggingIndex = null;
    didJustStartDragging = false;
    offsetToStartOfItem = 0.0;
    middleOfItemInGlobalPosition = 0.0;
  }

  void _accept(int index, Data data) {
    if (_currentIndex == null || _currentMiddle == null) return;
    setState(() {
      shouldScrollDown = false;
      shouldScrollUp = false;
      data.extraTop = 0.0;
      data.extraBot = 0.0;
      print('insert back to $index');
      if (_currentMiddle.dy >= _currentScrollPos) {
        widget.onDragFinish(_currentDraggingIndex, index);
      } else {
        widget.onDragFinish(_currentDraggingIndex, index + 1);
      }
      populateRowList();
    });
    _complete();
  }

  void updatePlaceholder() {
    if (renderSliverContext == null) return;
    if (_currentDraggingIndex == null) return;
    RenderSliverList it = renderSliverContext.findRenderObject();
    double buffer = sliverStartPos;
    RenderBox currentChild = it.firstChild;
    buffer += it.childMainAxisPosition(currentChild) + currentChild.size.height;
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
      return;
    }

    setState(() {
      if (_currentScrollPos > _currentMiddle.dy) {
        rows[_currentIndex].extraBot = dragHeight;
        rows[_currentIndex].extraTop = 0.0;
      } else {
        rows[_currentIndex].extraTop = dragHeight;
        rows[_currentIndex].extraBot = 0.0;
      }
    });
  }
}

typedef void OnDragStarted(double height, double topPosition);

class DraggableListItem extends StatelessWidget {
  final Data data;
  final int index;

  final double draggedHeight;
  final CanDrag canDrag;
  final OnDragStarted onDragStarted;
  final VoidCallback onDragCompleted;
  final MyDragTargetAccept<Data> onAccept;
  final ValueChanged<Offset> onMove;
  final VoidCallback cancelCallback;

  final double dragElevation;

  final Key myKey;

  final Widget child;

  DraggableListItem({
    Key key,
    this.data,
    this.index,
    this.canDrag,
    this.onDragStarted,
    this.onDragCompleted,
    this.onAccept,
    this.onMove,
    this.cancelCallback,
    this.draggedHeight,
    this.child,
    this.dragElevation,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (canDrag != null && !(canDrag(index))) {
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
            onDragStarted(it.size.height, it.localToGlobal(it.semanticBounds.topCenter).dy);
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
        transform: new Matrix4.rotationZ(0.0),
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

class Data {
  int index;
  double extraTop;
  double extraBot;

  Data(this.index, {this.extraTop = 0.0, this.extraBot = 0.0});
}
