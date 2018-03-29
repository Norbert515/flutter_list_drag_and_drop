// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';


/// Signature for determining whether the given data will be accepted by a [MyDragTarget].
///
/// Used by [MyDragTarget.onWillAccept].
typedef bool MyDragTargetWillAccept<T>(T data);

/// Signature for causing a [MyDragTarget] to accept the given data.
///
/// Used by [MyDragTarget.onAccept].
typedef void MyDragTargetAccept<T>(T data);

/// Signature for building children of a [MyDragTarget].
///
/// The `candidateData` argument contains the list of drag data that is hovering
/// over this [MyDragTarget] and that has passed [MyDragTarget.onWillAccept]. The
/// `rejectedData` argument contains the list of drag data that is hovering over
/// this [MyDragTarget] and that will not be accepted by the [MyDragTarget].
///
/// Used by [MyDragTarget.builder].
typedef Widget MyDragTargetBuilder<T>(BuildContext context, List<T> candidateData, List<dynamic> rejectedData);

/// Signature for when a [MyDraggable] is dropped without being accepted by a [MyDragTarget].
///
/// Used by [MyDraggable.onMyDraggableCanceled].
typedef void MyDraggableCanceledCallback(Velocity velocity, Offset offset);

/// Signature for when a [MyDraggable] leaves a [MyDragTarget].
///
/// Used by [MyDragTarget.onLeave].
typedef void MyDragTargetLeave<T>(T data);

/// Where the [MyDraggable] should be anchored during a drag.
enum DragAnchor {
  /// Display the feedback anchored at the position of the original child. If
  /// feedback is identical to the child, then this means the feedback will
  /// exactly overlap the original child when the drag starts.
  child,

  /// Display the feedback anchored at the position of the touch that started
  /// the drag. If feedback is identical to the child, then this means the top
  /// left of the feedback will be under the finger when the drag starts. This
  /// will likely not exactly overlap the original child, e.g. if the child is
  /// big and the touch was not centered. This mode is useful when the feedback
  /// is transformed so as to move the feedback to the left by half its width,
  /// and up by half its width plus the height of the finger, since then it
  /// appears as if putting the finger down makes the touch feedback appear
  /// above the finger. (It feels weird for it to appear offset from the
  /// original child if it's anchored to the child and not the finger.)
  pointer,
}

/// A widget that can be dragged from to a [MyDragTarget].
///
/// When a MyDraggable widget recognizes the start of a drag gesture, it displays
/// a [feedback] widget that tracks the user's finger across the screen. If the
/// user lifts their finger while on top of a [MyDragTarget], that target is given
/// the opportunity to accept the [data] carried by the MyDraggable.
///
/// On multitouch devices, multiple drags can occur simultaneously because there
/// can be multiple pointers in contact with the device at once. To limit the
/// number of simultaneous drags, use the [maxSimultaneousDrags] property. The
/// default is to allow an unlimited number of simultaneous drags.
///
/// This widget displays [child] when zero drags are under way. If
/// [childWhenDragging] is non-null, this widget instead displays
/// [childWhenDragging] when one or more drags are underway. Otherwise, this
/// widget always displays [child].
///
/// See also:
///
///  * [MyDragTarget]
///  * [LongPressMyDraggable]
class MyDraggable<T> extends StatefulWidget {
  /// Creates a widget that can be dragged to a [MyDragTarget].
  ///
  /// The [child] and [feedback] arguments must not be null. If
  /// [maxSimultaneousDrags] is non-null, it must be non-negative.
  const MyDraggable({
    Key key,
    @required this.child,
    @required this.feedback,
    this.data,
    this.childWhenDragging,
    this.feedbackOffset: Offset.zero,
    this.dragAnchor: DragAnchor.child,
    this.affinity,
    this.maxSimultaneousDrags,
    this.onDragStarted,
    this.onMyDraggableCanceled,
    this.onDragCompleted,
    this.onMove
  }) : assert(child != null),
        assert(feedback != null),
        assert(maxSimultaneousDrags == null || maxSimultaneousDrags >= 0),
        super(key: key);


  /// The data that will be dropped by this MyDraggable.
  final T data;

  /// The widget below this widget in the tree.
  ///
  /// This widget displays [child] when zero drags are under way. If
  /// [childWhenDragging] is non-null, this widget instead displays
  /// [childWhenDragging] when one or more drags are underway. Otherwise, this
  /// widget always displays [child].
  ///
  /// The [feedback] widget is shown under the pointer when a drag is under way.
  ///
  /// To limit the number of simultaneous drags on multitouch devices, see
  /// [maxSimultaneousDrags].
  ///
  /// {@macro flutter.widgets.child}
  final Widget child;

  /// The widget to display instead of [child] when one or more drags are under way.
  ///
  /// If this is null, then this widget will always display [child] (and so the
  /// drag source representation will not change while a drag is under
  /// way).
  ///
  /// The [feedback] widget is shown under the pointer when a drag is under way.
  ///
  /// To limit the number of simultaneous drags on multitouch devices, see
  /// [maxSimultaneousDrags].
  final Widget childWhenDragging;

  /// The widget to show under the pointer when a drag is under way.
  ///
  /// See [child] and [childWhenDragging] for information about what is shown
  /// at the location of the [MyDraggable] itself when a drag is under way.
  final Widget feedback;

  /// The feedbackOffset can be used to set the hit test target point for the
  /// purposes of finding a drag target. It is especially useful if the feedback
  /// is transformed compared to the child.
  final Offset feedbackOffset;

  /// Where this widget should be anchored during a drag.
  final DragAnchor dragAnchor;

  /// Controls how this widget competes with other gestures to initiate a drag.
  ///
  /// If affinity is null, this widget initiates a drag as soon as it recognizes
  /// a tap down gesture, regardless of any directionality. If affinity is
  /// horizontal (or vertical), then this widget will compete with other
  /// horizontal (or vertical, respectively) gestures.
  ///
  /// For example, if this widget is placed in a vertically scrolling region and
  /// has horizontal affinity, pointer motion in the vertical direction will
  /// result in a scroll and pointer motion in the horizontal direction will
  /// result in a drag. Conversely, if the widget has a null or vertical
  /// affinity, pointer motion in any direction will result in a drag rather
  /// than in a scroll because the MyDraggable widget, being the more specific
  /// widget, will out-compete the [Scrollable] for vertical gestures.
  final Axis affinity;

  /// How many simultaneous drags to support.
  ///
  /// When null, no limit is applied. Set this to 1 if you want to only allow
  /// the drag source to have one item dragged at a time. Set this to 0 if you
  /// want to prevent the MyDraggable from actually being dragged.
  ///
  /// If you set this property to 1, consider supplying an "empty" widget for
  /// [childWhenDragging] to create the illusion of actually moving [child].
  final int maxSimultaneousDrags;

  /// Called when the MyDraggable starts being dragged.
  final VoidCallback onDragStarted;

  /// Called when the MyDraggable is dropped without being accepted by a [MyDragTarget].
  ///
  /// This function might be called after this widget has been removed from the
  /// tree. For example, if a drag was in progress when this widget was removed
  /// from the tree and the drag ended up being canceled, this callback will
  /// still be called. For this reason, implementations of this callback might
  /// need to check [State.mounted] to check whether the state receiving the
  /// callback is still in the tree.
  final MyDraggableCanceledCallback onMyDraggableCanceled;

  /// Called when the MyDraggable is dropped and accepted by a [MyDragTarget].
  ///
  /// This function might be called after this widget has been removed from the
  /// tree. For example, if a drag was in progress when this widget was removed
  /// from the tree and the drag ended up completing, this callback will
  /// still be called. For this reason, implementations of this callback might
  /// need to check [State.mounted] to check whether the state receiving the
  /// callback is still in the tree.
  final VoidCallback onDragCompleted;


  final ValueChanged<Offset> onMove;

  /// Creates a gesture recognizer that recognizes the start of the drag.
  ///
  /// Subclasses can override this function to customize when they start
  /// recognizing a drag.
  @protected
  MultiDragGestureRecognizer<MultiDragPointerState> createRecognizer(GestureMultiDragStartCallback onStart) {
    switch (affinity) {
      case Axis.horizontal:
        return new HorizontalMultiDragGestureRecognizer()..onStart = onStart;
      case Axis.vertical:
        return new VerticalMultiDragGestureRecognizer()..onStart = onStart;
    }
    return new ImmediateMultiDragGestureRecognizer()..onStart = onStart;
  }

  @override
  MyDraggableState<T> createState() => new MyDraggableState<T>();
}

/// Makes its child MyDraggable starting from long press.
class LongPressMyDraggable<T> extends MyDraggable<T> {
  /// Creates a widget that can be dragged starting from long press.
  ///
  /// The [child] and [feedback] arguments must not be null. If
  /// [maxSimultaneousDrags] is non-null, it must be non-negative.
  const LongPressMyDraggable({
    Key key,
    @required Widget child,
    @required Widget feedback,
    T data,
    Widget childWhenDragging,
    Offset feedbackOffset: Offset.zero,
    DragAnchor dragAnchor: DragAnchor.child,
    int maxSimultaneousDrags,
    VoidCallback onDragStarted,
    MyDraggableCanceledCallback onMyDraggableCanceled,
    VoidCallback onDragCompleted,
    ValueChanged<Offset> onMove,
  }) : super(
      key: key,
      child: child,
      feedback: feedback,
      data: data,
      childWhenDragging: childWhenDragging,
      feedbackOffset: feedbackOffset,
      dragAnchor: dragAnchor,
      maxSimultaneousDrags: maxSimultaneousDrags,
      onDragStarted: onDragStarted,
      onMyDraggableCanceled: onMyDraggableCanceled,
      onDragCompleted: onDragCompleted,
      onMove: onMove
  );

  @override
  DelayedMultiDragGestureRecognizer createRecognizer(GestureMultiDragStartCallback onStart) {
    return new DelayedMultiDragGestureRecognizer()
      ..onStart = (Offset position) {
        final Drag result = onStart(position);
        if (result != null)
          HapticFeedback.vibrate();
        return result;
      };
  }
}

class MyDraggableState<T> extends State<MyDraggable<T>> {
  DragAvatar avatar;
  @override
  void initState() {
    super.initState();
    _recognizer = widget.createRecognizer(_startDrag);
  }

  @override
  void dispose() {
    _disposeRecognizerIfInactive();
    super.dispose();
  }

  // This gesture recognizer has an unusual lifetime. We want to support the use
  // case of removing the MyDraggable from the tree in the middle of a drag. That
  // means we need to keep this recognizer alive after this state object has
  // been disposed because it's the one listening to the pointer events that are
  // driving the drag.
  //
  // We achieve that by keeping count of the number of active drags and only
  // disposing the gesture recognizer after (a) this state object has been
  // disposed and (b) there are no more active drags.
  GestureRecognizer _recognizer;
  int _activeCount = 0;

  void _disposeRecognizerIfInactive() {
    if (_activeCount > 0)
      return;
    _recognizer.dispose();
    _recognizer = null;
  }

  void _routePointer(PointerEvent event) {
    if (widget.maxSimultaneousDrags != null && _activeCount >= widget.maxSimultaneousDrags)
      return;
    _recognizer.addPointer(event);
  }

  DragAvatar<T> _startDrag(Offset position) {
    if (widget.maxSimultaneousDrags != null && _activeCount >= widget.maxSimultaneousDrags)
      return null;
    Offset dragStartPoint;
    switch (widget.dragAnchor) {
      case DragAnchor.child:
        final RenderBox renderObject = context.findRenderObject();
        dragStartPoint = renderObject.globalToLocal(position);
        break;
      case DragAnchor.pointer:
        dragStartPoint = Offset.zero;
        break;
    }
    setState(() {
      _activeCount += 1;
    });
    final DragAvatar<T> avatar = new DragAvatar<T>(
        overlayState: Overlay.of(context, debugRequiredFor: widget),
        data: widget.data,
        initialPosition: position,
        dragStartPoint: dragStartPoint,
        feedback: widget.feedback,
        feedbackOffset: widget.feedbackOffset,
        onMove: widget.onMove,
        onDragEnd: (Velocity velocity, Offset offset, bool wasAccepted) {
          if (mounted) {
            setState(() {
              _activeCount -= 1;
            });
          } else {
            _activeCount -= 1;
            _disposeRecognizerIfInactive();
          }
          if (wasAccepted && widget.onDragCompleted != null)
            widget.onDragCompleted();
          if (!wasAccepted && widget.onMyDraggableCanceled != null)
            widget.onMyDraggableCanceled(velocity, offset);
        }
    );
    //TODO mine
    this.avatar = avatar;
    if (widget.onDragStarted != null)
      widget.onDragStarted();
    return avatar;
  }

  @override
  Widget build(BuildContext context) {
    assert(Overlay.of(context, debugRequiredFor: widget) != null);
    final bool canDrag = widget.maxSimultaneousDrags == null ||
        _activeCount < widget.maxSimultaneousDrags;
    final bool showChild = _activeCount == 0 || widget.childWhenDragging == null;
    return new Listener(
        onPointerDown: canDrag ? _routePointer : null,
        child: showChild ? widget.child : widget.childWhenDragging
    );
  }
}

/// A widget that receives data when a [MyDraggable] widget is dropped.
///
/// When a MyDraggable is dragged on top of a drag target, the drag target is
/// asked whether it will accept the data the MyDraggable is carrying. If the user
/// does drop the MyDraggable on top of the drag target (and the drag target has
/// indicated that it will accept the MyDraggable's data), then the drag target is
/// asked to accept the MyDraggable's data.
///
/// See also:
///
///  * [MyDraggable]
///  * [LongPressMyDraggable]
class MyDragTarget<T> extends StatefulWidget {
  /// Creates a widget that receives drags.
  ///
  /// The [builder] argument must not be null.
  const MyDragTarget({
    Key key,
    @required this.builder,
    this.onWillAccept,
    this.onAccept,
    this.onLeave,
  }) : super(key: key);

  /// Called to build the contents of this widget.
  ///
  /// The builder can build different widgets depending on what is being dragged
  /// into this drag target.
  final MyDragTargetBuilder<T> builder;

  /// Called to determine whether this widget is interested in receiving a given
  /// piece of data being dragged over this drag target.
  ///
  /// Called when a piece of data enters the target. This will be followed by
  /// either [onAccept], if the data is dropped, or [onLeave], if the drag
  /// leaves the target.
  final MyDragTargetWillAccept<T> onWillAccept;

  /// Called when an acceptable piece of data was dropped over this drag target.
  final MyDragTargetAccept<T> onAccept;

  /// Called when a given piece of data being dragged over this target leaves
  /// the target.
  final MyDragTargetLeave<T> onLeave;

  @override
  _MyDragTargetState<T> createState() => new _MyDragTargetState<T>();
}

List<T> _mapAvatarsToData<T>(List<DragAvatar<T>> avatars) {
  return avatars.map<T>((DragAvatar<T> avatar) => avatar.data).toList();
}

class _MyDragTargetState<T> extends State<MyDragTarget<T>> {
  final List<DragAvatar<T>> _candidateAvatars = <DragAvatar<T>>[];
  final List<DragAvatar<dynamic>> _rejectedAvatars = <DragAvatar<dynamic>>[];

  bool didEnter(DragAvatar<dynamic> avatar) {
    assert(!_candidateAvatars.contains(avatar));
    assert(!_rejectedAvatars.contains(avatar));
    if (avatar.data is T && (widget.onWillAccept == null || widget.onWillAccept(avatar.data))) {
      setState(() {
        _candidateAvatars.add(avatar);
      });
      return true;
    }
    _rejectedAvatars.add(avatar);
    return false;
  }

  void didLeave(DragAvatar<dynamic> avatar) {
    assert(_candidateAvatars.contains(avatar) || _rejectedAvatars.contains(avatar));
    if (!mounted)
      return;
    setState(() {
      _candidateAvatars.remove(avatar);
      _rejectedAvatars.remove(avatar);
    });
    if (widget.onLeave != null)
      widget.onLeave(avatar.data);
  }

  void didDrop(DragAvatar<dynamic> avatar) {
    assert(_candidateAvatars.contains(avatar));
    if (!mounted)
      return;
    setState(() {
      _candidateAvatars.remove(avatar);
    });
    if (widget.onAccept != null)
      widget.onAccept(avatar.data);
  }

  @override
  Widget build(BuildContext context) {
    assert(widget.builder != null);
    return new MetaData(
        metaData: this,
        behavior: HitTestBehavior.translucent,
        child: widget.builder(context, _mapAvatarsToData<T>(_candidateAvatars), _mapAvatarsToData<dynamic>(_rejectedAvatars))
    );
  }
}

enum _DragEndKind { dropped, canceled }
typedef void _OnDragEnd(Velocity velocity, Offset offset, bool wasAccepted);

// The lifetime of this object is a little dubious right now. Specifically, it
// lives as long as the pointer is down. Arguably it should self-immolate if the
// overlay goes away. _MyDraggableState has some delicate logic to continue
// eeding this object pointer events even after it has been disposed.
class DragAvatar<T> extends Drag {
  DragAvatar({
    @required this.overlayState,
    this.data,
    Offset initialPosition,
    this.dragStartPoint: Offset.zero,
    this.feedback,
    this.feedbackOffset: Offset.zero,
    this.onDragEnd,
    this.onMove
  }) : assert(overlayState != null),
        assert(dragStartPoint != null),
        assert(feedbackOffset != null) {
    _entry = new OverlayEntry(builder: _build);
    overlayState.insert(_entry);
    _position = initialPosition;
    updateDrag(initialPosition);
  }

  final T data;
  final Offset dragStartPoint;
  final Widget feedback;
  final Offset feedbackOffset;
  final _OnDragEnd onDragEnd;
  final OverlayState overlayState;

  _MyDragTargetState<T> _activeTarget;
  final List<_MyDragTargetState<T>> _enteredTargets = <_MyDragTargetState<T>>[];
  Offset _position;
  Offset _lastOffset;
  OverlayEntry _entry;

  final ValueChanged<Offset> onMove;

  double startClamp = -1.0;
  double endClamp = -1.0;


  void updateZero() {
    updateDrag(_position);
  }

  @override
  void update(DragUpdateDetails details) {
    _position += details.delta;
    updateDrag(_position);
  }

  @override
  void end(DragEndDetails details) {
    finishDrag(_DragEndKind.dropped, details.velocity);
  }

  @override
  void cancel() {
    finishDrag(_DragEndKind.canceled);
  }

  void updateDrag(Offset globalPosition) {

    _lastOffset = globalPosition - dragStartPoint;
    _entry.markNeedsBuild();

    //TODO norbert it's here :)
    onMove(globalPosition);
    final HitTestResult result = new HitTestResult();
    WidgetsBinding.instance.hitTest(result, globalPosition + feedbackOffset);

    final List<_MyDragTargetState<T>> targets = _getMyDragTargets(result.path).toList();

    bool listsMatch = false;
    if (targets.length >= _enteredTargets.length && _enteredTargets.isNotEmpty) {
      listsMatch = true;
      final Iterator<_MyDragTargetState<T>> iterator = targets.iterator;
      for (int i = 0; i < _enteredTargets.length; i += 1) {
        iterator.moveNext();
        if (iterator.current != _enteredTargets[i]) {
          listsMatch = false;
          break;
        }
      }
    }

    // If everything's the same, bail early.
    if (listsMatch)
      return;

    // Leave old targets.
    _leaveAllEntered();

    // Enter new targets.
    final _MyDragTargetState<T> newTarget = targets.firstWhere((_MyDragTargetState<T> target) {
      _enteredTargets.add(target);
      return target.didEnter(this);
    },
        orElse: _null
    );


    _activeTarget = newTarget;
  }

  static Null _null() => null;

  Iterable<_MyDragTargetState<T>> _getMyDragTargets(List<HitTestEntry> path) sync* {
    // Look for the RenderBoxes that corresponds to the hit target (the hit target
    // widgets build RenderMetaData boxes for us for this purpose).
    for (HitTestEntry entry in path) {
      if (entry.target is RenderMetaData) {
        final RenderMetaData renderMetaData = entry.target;
        if (renderMetaData.metaData is _MyDragTargetState<T>)
          yield renderMetaData.metaData;
      }
    }
  }

  void _leaveAllEntered() {
    for (int i = 0; i < _enteredTargets.length; i += 1)
      _enteredTargets[i].didLeave(this);
    _enteredTargets.clear();
  }

  void finishDrag(_DragEndKind endKind, [Velocity velocity]) {
    bool wasAccepted = false;
    if (endKind == _DragEndKind.dropped && _activeTarget != null) {
      _activeTarget.didDrop(this);
      wasAccepted = true;
      _enteredTargets.remove(_activeTarget);
    }
    _leaveAllEntered();
    _activeTarget = null;
    _entry.remove();
    _entry = null;
    // TODO(ianh): consider passing _entry as well so the client can perform an animation.
    if (onDragEnd != null)
      onDragEnd(velocity ?? Velocity.zero, _lastOffset, wasAccepted);
  }

  Widget _build(BuildContext context) {
    final RenderBox box = overlayState.context.findRenderObject();
    final Offset overlayTopLeft = box.localToGlobal(Offset.zero);
    return new Positioned(
        left: _lastOffset.dx - overlayTopLeft.dx,
        top: _lastOffset.dy - overlayTopLeft.dy,
        child: new IgnorePointer(
            child: feedback
        )
    );
  }
}
