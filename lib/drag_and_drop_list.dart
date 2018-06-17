/// ---------------------------------------------------------------------
/// Makes a listView items draggable
/// 
/// based on a code from Norbert Kozsir
/// (https://github.com/Norbert515/flutter_list_drag_and_drop)
/// 
/// Uses a custom version of drag_target.dart (not yet officialized) => MyDraggable (my_draggable.dart)
/// 
/// Sample
/// class PhotoSliderSelector extends StatefulWidget {
///   @override
///   _PhotoSliderSelectorState createState() => _PhotoSliderSelectorState();
/// }
/// 
/// class _PhotoSliderSelectorState extends State<PhotoSliderSelector> {
///   List<String> _photos = <String>['1', '2', '3', '4', '5', '6', '7', '8', '9'];
///   int _currentPhotoIndex = 0;
/// 
///   void _refresh(){
///     setState((){
/// 
///     });
///   }

///   @override
///   Widget build(BuildContext context) {
///     return new Column(
///       children: <Widget>[
///         new SizedBox(height: 150.0),
///         new Container(
///           color: Colors.yellow,
///                   child: new SizedBox(
///             width: double.infinity,
///             height: 120.0,
///             child: new Row(
///               children: <Widget>[
///                 new Icon(Icons.arrow_left),
///                 new Expanded(
///                   child: new DragAndDropListView<String>(
///                     _photos,
///                     axis: Axis.horizontal,
///                     scrollPositionEdgeThreshold: 50.0,            // Distance from edge that causes scrolling
///                     itemBuilder: (BuildContext context, item){
///                       return _buildPhotoSlide(item);
///                     },
///                     onDragFinish: (before, after){
///                       dynamic data = _photos[before];
///                       _photos.removeAt(before);
///                       _photos.insert(after, data);
///                     },
///                     canBeDraggedTo: (one, two) => true,
///                     dragElevation: 8.0,
///                   ),
///                 ),
///                 new Icon(Icons.arrow_right),
///               ],
///             ),
///           ),
///         ),
///       ],
///     );
///   }
/// 
///   /// ------------------------------------------------------------------
///   /// Builds the list of photo slides
///   /// ------------------------------------------------------------------
///   Widget _buildPhotoSlide(item) {
///     return new SizedBox(
///       width: 120.0,
///       height: 120.0,
///       child: new Card(
///         child: new Container(
///           color: Colors.red,
///           child: new Text('$item'),
///         ),
///       ),
///     );
///   }
/// }
/// ---------------------------------------------------------------------
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:meta/meta.dart';

import '../helpers/my_draggable.dart';

typedef WidgetAndDelegate WidgetMakerAndDelegate<T>(BuildContext context, T item, int itemIndex);

typedef Widget WidgetMaker<T>(BuildContext context, T item, int itemIndex);

typedef void OnDragFinish(int oldIndex, int newIndex);

typedef bool CanAccept(int oldIndex, int newIndex);



class WidgetAndDelegate {
  final Widget widget;
  final DraggableDelegate delegate;

  WidgetAndDelegate(this.widget, this.delegate);
}


class DragAndDropListView<T> extends StatefulWidget {
  final List<T> itemsData;

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

  // Scroll axis
  final Axis axis;

  // Threshold value
  final double scrollPositionEdgeThreshold;

  DragAndDropListView(this.itemsData,
      {
        Key key, 
        @required this.itemBuilder,
        this.onDragFinish,
        @required this.canBeDraggedTo,
        this.dragElevation = 0.0,
        this.tilt = 0.0,
        this.axis = Axis.vertical,
        this.scrollPositionEdgeThreshold = 160.0,
      })
      : providesOwnDraggable = false,
        itemBuilderCustom = null, super(key: key);

  DragAndDropListView.withCustomDraggableBehavior(this.itemsData,
      {
        Key key,
        @required this.itemBuilderCustom,
        this.onDragFinish,
        @required this.canBeDraggedTo,
        this.dragElevation = 0.0,
        this.tilt = 0.0,
        this.axis = Axis.vertical,
        this.scrollPositionEdgeThreshold = 160.0,
      })
      : providesOwnDraggable = true,
        itemBuilder = null, super(key: key);

  @override
  State<StatefulWidget> createState() => new _DragAndDropListViewState<T>();
}

class _DragAndDropListViewState<T> extends State<DragAndDropListView> {
	///
	/// Constant: threshold (distance from an edge), below which we do a scroll
	///
  final double _kScrollPositionOffset = 12.0;
  final int _kScrollAnimationDelay = 75;

  bool shouldScrollUpLeft = false;
  bool shouldScrollDownRight = false;

  double _currentScrollPos = 0.0;

  ScrollController scrollController;

  List<Data<T>> items = new List<Data<T>>();

  //Index of the item dragged
  int _currentDraggingIndex;

  // The height (Axis.vertical) or width (Axis.horizontal) of the item being dragged
  double dragItemDimensions;

  SliverMultiBoxAdaptorElement renderSliverContext;

  Data<T> draggedData;

  Offset _currentMiddle;

  //Index of the item currently accepting
  int _currentIndex;

  bool isScrolling = false;

  double offsetToStartOfItem = 0.0;

  double sliverStartPos = 0.0;

  bool didJustStartDragging = false;

  // This corrects the case when the user grabs the card at the bottom (or right), 
  // the system will always handle like grabbed on the middle to ensure correct behavior
  double middleOfItemInGlobalPosition = 0.0;

  @override
  void initState() {
    super.initState();
    List data = widget.itemsData;
    items = data.map((it) => new Data<T>(it)).toList();
    scrollController = new ScrollController();
  }


  void _maybeScroll() {
    if (isScrolling) return;

    if (shouldScrollUpLeft) {
      if (scrollController.position.pixels == 0.0) return;
      isScrolling = true;
      var scrollTo = scrollController.offset - _kScrollPositionOffset;
      scrollController
          .animateTo(scrollTo, duration: new Duration(milliseconds: _kScrollAnimationDelay), curve: Curves.linear)
          .then((it) {
        updatePlaceholder();
        isScrolling = false;
        _maybeScroll();
      });
      //TODO implement
     // Scrollable.ensureVisible(context, );
    }
    if (shouldScrollDownRight) {
      if (scrollController.position.pixels == scrollController.position.maxScrollExtent) return;
      isScrolling = true;
      var scrollTo = scrollController.offset + _kScrollPositionOffset;
      scrollController
          .animateTo(scrollTo, duration: new Duration(milliseconds: _kScrollAnimationDelay), curve: Curves.linear)
          .then((it) {
        updatePlaceholder();
        isScrolling = false;
        _maybeScroll();
      });
    }
  }

  @override
  void dispose(){
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return new LayoutBuilder(
      builder: (BuildContext contextDragContainer, _) {
        return new ListView.builder(
          scrollDirection: widget.axis,
          itemBuilder: (BuildContext contextDraggableItem, int index) {
            return _getDraggableListItem(contextDraggableItem, index, contextDragContainer);
          },
          controller: scrollController,
          itemCount: items.length,
        );
      },
    );
  }


  Widget _getDraggableListItem(BuildContext contextDraggableItem, int index, BuildContext contextDragContainer) {
    WidgetAndDelegate widgetAndDelegate;
    if (widget.providesOwnDraggable) {
      widgetAndDelegate = widget.itemBuilderCustom(contextDraggableItem, items[index].data, index);
    } else {
      widgetAndDelegate =
      new WidgetAndDelegate(widget.itemBuilder(contextDraggableItem, items[index].data, index), null);
    }
    var draggableListItem = new DraggableListItem(
      child: widgetAndDelegate.widget,
      custom: widget.providesOwnDraggable,
      key: new ValueKey(items[index]),
      data: items[index],
      index: index,
      tilt: widget.tilt,
      axis: widget.axis,
      delegate: widgetAndDelegate.delegate,
      dragElevation: widget.dragElevation,
      draggedDimensions: dragItemDimensions,
      onDragStarted: (double draggedDimensions, double globalTopPositionOfDraggedItem) {
        _currentDraggingIndex = index;
        RenderBox rend = contextDragContainer.findRenderObject();
        double start = widget.axis == Axis.vertical 
                     ? rend.localToGlobal(new Offset(0.0, 0.0)).dy
                     : rend.localToGlobal(new Offset(0.0, 0.0)).dx;

        didJustStartDragging = true;
        _currentScrollPos = start;

        middleOfItemInGlobalPosition = globalTopPositionOfDraggedItem + draggedDimensions / 2;

        sliverStartPos = start;
        draggedData = items[index];

        renderSliverContext = contextDraggableItem;
        updatePlaceholder();
        dragItemDimensions = draggedDimensions;

        setState(() {
          items.removeAt(index);
        });
      },
      onDragCompleted: () {
        _accept(index, draggedData);
      },
      onAccept: (Data data) {
        _accept(index, data);
      },
      onMove: (Offset offset) {
        double ofs = (widget.axis == Axis.vertical ? offset.dy : offset.dx);

        if(didJustStartDragging) {
          didJustStartDragging = false;
          offsetToStartOfItem = ofs - middleOfItemInGlobalPosition;
          _currentScrollPos = ofs - offsetToStartOfItem;
        }
        _currentScrollPos = ofs - offsetToStartOfItem;
        double screenDimensions = widget.axis == Axis.vertical 
                              ? MediaQuery.of(contextDraggableItem).size.height
                              : MediaQuery.of(contextDraggableItem).size.width; 

        if (_currentScrollPos < widget.scrollPositionEdgeThreshold) {
          shouldScrollUpLeft = true;
        } else {
          shouldScrollUpLeft = false;
        }
        if (_currentScrollPos > screenDimensions - widget.scrollPositionEdgeThreshold) {
          shouldScrollDownRight = true;
        } else {
          shouldScrollDownRight = false;
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
    shouldScrollUpLeft = false;
    shouldScrollDownRight = false;
    _currentIndex = null;
    _currentScrollPos = 0.0;
    _currentMiddle = null;
    _currentDraggingIndex = null;
    didJustStartDragging = false;
    offsetToStartOfItem = 0.0;
    middleOfItemInGlobalPosition = 0.0;
  }

  void _accept(int index, Data data) {
    if(_currentIndex == null || _currentMiddle == null) return;
    setState(() {
      shouldScrollDownRight = false;
      shouldScrollUpLeft = false;
      data.extraTopLeft = 0.0;
      data.extraBotRight = 0.0;

      double middle = widget.axis == Axis.vertical ? _currentMiddle.dy : _currentMiddle.dx;

      if (middle >= _currentScrollPos) {
        items.insert(index, data);
        widget.onDragFinish(_currentDraggingIndex, index);
      } else {
        items.insert(index + 1, data);
        widget.onDragFinish(_currentDraggingIndex, index + 1);
      }
      items.forEach((it) {
        it.extraTopLeft = 0.0;
        it.extraBotRight = 0.0;
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
    buffer += it.childMainAxisPosition(currentChild) + (widget.axis == Axis.vertical ? currentChild.size.height : currentChild.size.width);
    while (_currentScrollPos > buffer) {
      if (currentChild != null) {
        var bufferChild = it.childAfter(currentChild);
        if (bufferChild == null) break;
        currentChild = bufferChild;
        buffer = it.childMainAxisPosition(currentChild) + (widget.axis == Axis.vertical ? currentChild.size.height : currentChild.size.width) + sliverStartPos;
      }
    }
    assert(currentChild != null);
    double middle = buffer - (widget.axis == Axis.vertical ? currentChild.size.height : currentChild.size.width) / 2;

    int index = it.indexOf(currentChild);
    if (!widget.canBeDraggedTo(_currentDraggingIndex, index)) return;

    _currentMiddle = widget.axis == Axis.vertical ? new Offset(0.0, middle) : new Offset(middle, 0.0);
    _currentIndex = index;

    //TODO not so performant
    setState(() {
      items.forEach((it) {
        it.extraTopLeft = 0.0;
        it.extraBotRight = 0.0;
      });
    });

    if (_currentIndex >= items.length) {
      _currentIndex--;
    }

    setState(() {
      double middle = widget.axis == Axis.vertical ? _currentMiddle.dy : _currentMiddle.dx;
      if (_currentScrollPos > middle) {
        items[_currentIndex].extraBotRight = dragItemDimensions;
        items[_currentIndex].extraTopLeft = 0.0;
      } else {
        items[_currentIndex].extraTopLeft = dragItemDimensions;
        items[_currentIndex].extraBotRight = 0.0;
      }
    });
  }
}

typedef void OnDragStarted(double height, double topPosition);


class DraggableListItem extends StatelessWidget {
  final Data data;
  final int index;
  final double draggedDimensions;

  final OnDragStarted onDragStarted;
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

  final Axis axis;

  DraggableListItem(
      {
        Key key,
        this.data,
        this.index,
        this.onDragStarted,
        this.onDragCompleted,
        this.onAccept,
        this.onMove,
        this.cancelCallback,
        this.draggedDimensions,
        this.child,
        this.tilt,
        this.dragElevation,
        this.delegate,
        this.custom,
        @required this.axis,
      }): super(key: key);

  @override
  Widget build(BuildContext context) {
    if (custom) {
      if (delegate != null) {
        delegate.onMove(onMove);
        delegate.onDragStarted(() {
          RenderBox it = context.findRenderObject() as RenderBox;
          if (axis == Axis.vertical){
            onDragStarted(it.size.height, it.localToGlobal(it.semanticBounds.topCenter).dy);
          } else {
            onDragStarted(it.size.width, it.localToGlobal(it.semanticBounds.topCenter).dx);
          }
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
          dragAnchor: MyDragAnchor.child,
          onDragStarted: () {
            RenderBox it = context.findRenderObject() as RenderBox;
            if (axis == Axis.vertical){
              onDragStarted(it.size.height, it.localToGlobal(it.semanticBounds.topCenter).dy);
            } else {
              onDragStarted(it.size.width, it.localToGlobal(it.semanticBounds.topCenter).dx);
            }
          },
          onDragCompleted: onDragCompleted,
          onDraggableCanceled: (_, _2) {
            cancelCallback();
          });
    }
  }

  ///
  /// 
  ///
  Widget _getListChild(BuildContext context) {
    return new MyDragTarget<Data>(
      builder: (BuildContext context, List candidateData, List rejectedData) {
        return (axis == Axis.vertical) ?
        new Column(
          children: <Widget>[
            new SizedBox(height: data.extraTopLeft),
            child,
            new SizedBox(height: data.extraBotRight),
          ],
        )
        : 
        new Row(
          children: <Widget>[
            new SizedBox(width: data.extraTopLeft),
            child,
            new SizedBox(width: data.extraBotRight),
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
    return new ConstrainedBox(
      constraints: axis == Axis.vertical 
                   ? new BoxConstraints(maxWidth: MediaQuery.of(context).size.width)
                   : new BoxConstraints(maxHeight: MediaQuery.of(context).size.height),
      child: new Transform(
        transform: new Matrix4.rotationZ(tilt),
        alignment: axis == Axis.vertical ? FractionalOffset.bottomRight : FractionalOffset.center,
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

  double extraTopLeft;
  double extraBotRight;

  Data(this.data, {this.color, this.extraTopLeft = 0.0, this.extraBotRight = 0.0});
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
