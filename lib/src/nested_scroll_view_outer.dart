part of 'nested_scroll_view.dart';

class NestedScrollViewOuter extends OriginalNestedScrollView {
  const NestedScrollViewOuter({
    super.key,
    super.controller,
    super.scrollDirection = Axis.vertical,
    super.reverse = false,
    super.physics,
    required super.headerSliverBuilder,
    required super.body,
    super.dragStartBehavior = DragStartBehavior.start,
    super.floatHeaderSlivers = false,
    super.clipBehavior = Clip.hardEdge,
    super.restorationId,
    super.scrollBehavior,
  });

  static OriginalOverlapAbsorberHandle sliverOverlapAbsorberHandleFor(
      BuildContext context) {
    final _OriginalInheritedNestedScrollView? target =
        context.dependOnInheritedWidgetOfExactType<
            _OriginalInheritedNestedScrollView>();
    assert(
      target != null,
      'OriginalNestedScrollView.sliverOverlapAbsorberHandleFor must be called with a context that contains a OriginalNestedScrollView.',
    );
    return target!.state._absorberHandle;
  }

  @override
  NestedScrollViewStatePlus createState() => NestedScrollViewPlusOuterState();
}

class NestedScrollViewPlusOuterState extends NestedScrollViewStatePlus {
  @override
  void initState() {
    super.initState();
    _coordinator = _NestedScrollCoordinatorOuter(
      this,
      widget.controller,
      _handleHasScrolledBodyChanged,
      widget.floatHeaderSlivers,
    );
  }
}

class _NestedScrollControllerOuter extends _OriginalNestedScrollController {
  _NestedScrollControllerOuter(
    super.coordinator, {
    super.initialScrollOffset = 0.0,
    super.debugLabel,
  });

  @override
  ScrollPosition createScrollPosition(
    ScrollPhysics physics,
    ScrollContext context,
    ScrollPosition? oldPosition,
  ) {
    return _NestedScrollPositionOuter(
      coordinator: coordinator as _NestedScrollCoordinatorOuter,
      physics: physics,
      context: context,
      initialPixels: initialScrollOffset,
      oldPosition: oldPosition,
      debugLabel: debugLabel,
    );
  }

  @override
  Iterable<_OriginalNestedScrollPosition> get nestedPositions =>
      kDebugMode ? _debugNestedPositions : _releaseNestedPositions;

  Iterable<_OriginalNestedScrollPosition> get _debugNestedPositions {
    return Iterable.castFrom<ScrollPosition, _OriginalNestedScrollPosition>(
        positions);
  }

  Iterable<_OriginalNestedScrollPosition> get _releaseNestedPositions sync* {
    yield* Iterable.castFrom<ScrollPosition, _OriginalNestedScrollPosition>(
        positions);
  }
}

class _NestedScrollCoordinatorOuter extends _OriginalNestedScrollCoordinator {
  _NestedScrollCoordinatorOuter(
    super.state,
    super.parent,
    super.onHasScrolledBodyChanged,
    super.floatHeaderSlivers,
  ) {
    final double initialScrollOffset = _parent?.initialScrollOffset ?? 0.0;
    _outerController = _NestedScrollControllerOuter(
      this,
      initialScrollOffset: initialScrollOffset,
      debugLabel: 'outer',
    );
    _innerController = _NestedScrollControllerOuter(
      this,
      initialScrollOffset: 0.0,
      debugLabel: 'inner',
    );
  }

  // ignore: unused_element
  _OriginalNestedScrollPosition? get _innerPosition {
    if (!_innerController.hasClients ||
        _innerController.nestedPositions.isEmpty) return null;
    _OriginalNestedScrollPosition? innerPosition;
    if (userScrollDirection != ScrollDirection.idle) {
      for (final _OriginalNestedScrollPosition position in _innerPositions) {
        if (innerPosition != null) {
          if (userScrollDirection == ScrollDirection.reverse) {
            if (innerPosition.pixels < position.pixels) continue;
          } else {
            if (innerPosition.pixels > position.pixels) continue;
          }
        }
        innerPosition = position;
      }
    }
    return innerPosition;
  }

  @override
  _OriginalNestedScrollMetrics _getMetrics(
      _OriginalNestedScrollPosition innerPosition, double velocity) {
    return _OriginalNestedScrollMetrics(
      minScrollExtent: _outerPosition!.minScrollExtent,
      maxScrollExtent: _outerPosition!.maxScrollExtent +
          (innerPosition.maxScrollExtent - innerPosition.minScrollExtent),
      pixels: unnestOffset(innerPosition.pixels, innerPosition),
      viewportDimension: _outerPosition!.viewportDimension,
      axisDirection: _outerPosition!.axisDirection,
      minRange: 0,
      maxRange: 0,
      correctionOffset: 0,
      devicePixelRatio: _outerPosition!.devicePixelRatio,
    );
  }

  @override
  double unnestOffset(double value, _OriginalNestedScrollPosition source) {
    if (source == _outerPosition) {
      return value;
    } else {
      if (_outerPosition!.maxScrollExtent - _outerPosition!.pixels >
          precisionErrorTolerance) {
        return _outerPosition!.pixels;
      }
      return _outerPosition!.maxScrollExtent + (value - source.minScrollExtent);
    }
  }

  @override
  double nestOffset(double value, _OriginalNestedScrollPosition target) {
    if (target == _outerPosition) {
      if (value > _outerPosition!.maxScrollExtent) {
        return _outerPosition!.maxScrollExtent;
      }
      return value;
    } else {
      if (value < _outerPosition!.maxScrollExtent) {
        return target.minScrollExtent;
      }
      return (target.minScrollExtent +
          (value - _outerPosition!.maxScrollExtent));
    }
  }

  @override
  void applyUserOffset(double delta) {
    updateUserScrollDirection(
        delta > 0.0 ? ScrollDirection.forward : ScrollDirection.reverse);
    if (_innerPositions.isEmpty) {
      _outerPosition!.applyFullDragUpdate(delta);
    } else if (delta < 0.0) {
      double outerDelta = delta;
      for (final position in _innerPositions) {
        if (position.pixels < position.minScrollExtent) {
          final potentialOuterDelta = position.applyClampedDragUpdate(delta);
          if (potentialOuterDelta < 0) {
            outerDelta = math.max(outerDelta, potentialOuterDelta);
          }
        }
      }
      if (outerDelta != 0.0) {
        final innerDelta = _outerPosition!.applyClampedDragUpdate(
          outerDelta,
        );
        if (innerDelta != 0.0) {
          for (final position in _innerPositions) {
            position.applyFullDragUpdate(innerDelta);
          }
        }
      }
    } else {
      double innerDelta = delta;
      if (_floatHeaderSlivers) {
        innerDelta = _outerPosition!.applyClampedDragUpdate(delta);
      }
      if (innerDelta != 0.0) {
        double outerDelta = 0.0;
        for (final position in _innerPositions) {
          final overscroll = position.applyClampedDragUpdate(innerDelta);
          if (overscroll > 0) {
            outerDelta = math.max(outerDelta, overscroll);
          }
        }
        if (outerDelta != 0.0) {
          _outerPosition!.applyFullDragUpdate(outerDelta);
        }
      }
    }
  }
}

class _NestedScrollPositionOuter extends _OriginalNestedScrollPosition {
  _NestedScrollPositionOuter({
    required super.physics,
    required super.context,
    super.initialPixels = 0.0,
    super.oldPosition,
    super.debugLabel,
    required super.coordinator,
  });

  @override
  ScrollActivity createBallisticScrollActivity(
    Simulation? simulation, {
    required _OriginalNestedBallisticScrollActivityMode mode,
    _OriginalNestedScrollMetrics? metrics,
  }) {
    if (simulation == null) return IdleScrollActivity(this);
    switch (mode) {
      case _OriginalNestedBallisticScrollActivityMode.outer:
        return _NestedOuterBallisticScrollActivityOuter(
          coordinator,
          this,
          simulation,
          context.vsync,
          activity?.shouldIgnorePointer ?? true,
        );
      case _OriginalNestedBallisticScrollActivityMode.inner:
        return _NestedInnerBallisticScrollActivityOuter(
          coordinator,
          this,
          simulation,
          context.vsync,
          activity?.shouldIgnorePointer ?? true,
        );
      case _OriginalNestedBallisticScrollActivityMode.independent:
        return BallisticScrollActivity(this, simulation, context.vsync,
            activity?.shouldIgnorePointer ?? true);
    }
  }
}

class _NestedBallisticScrollActivityOuter extends BallisticScrollActivity {
  _NestedBallisticScrollActivityOuter(
    this.coordinator,
    super.position,
    super.simulation,
    super.vsync,
    super.shouldIgnorePointer,
  );

  final _OriginalNestedScrollCoordinator coordinator;

  @override
  _OriginalNestedScrollPosition get delegate =>
      super.delegate as _OriginalNestedScrollPosition;

  @override
  void resetActivity() {
    assert(false);
  }

  @override
  void applyNewDimensions() {
    assert(false);
  }

  @override
  bool applyMoveTo(double value) {
    return super.applyMoveTo(coordinator.nestOffset(value, delegate));
  }
}

class _NestedOuterBallisticScrollActivityOuter
    extends _NestedBallisticScrollActivityOuter {
  _NestedOuterBallisticScrollActivityOuter(
    super.coordinator,
    super.position,
    super.simulation,
    super.vsync,
    super.shouldIgnorePointer,
  );

  @override
  void resetActivity() {
    delegate.beginActivity(coordinator.createOuterBallisticScrollActivity(
      velocity,
    ));
  }

  @override
  void applyNewDimensions() {
    delegate.beginActivity(coordinator.createOuterBallisticScrollActivity(
      velocity,
    ));
  }
}

class _NestedInnerBallisticScrollActivityOuter
    extends _NestedBallisticScrollActivityOuter {
  _NestedInnerBallisticScrollActivityOuter(
    super.coordinator,
    super.position,
    super.simulation,
    super.vsync,
    super.shouldIgnorePointer,
  );

  @override
  void resetActivity() {
    delegate.beginActivity(coordinator.createInnerBallisticScrollActivity(
      delegate,
      velocity,
    ));
  }

  @override
  void applyNewDimensions() {
    delegate.beginActivity(coordinator.createInnerBallisticScrollActivity(
      delegate,
      velocity,
    ));
  }
}

class SliverOverlapAbsorberOuter extends OriginalSliverOverlapAbsorber {
  const SliverOverlapAbsorberOuter({
    super.key,
    required super.handle,
    super.sliver,
  });

  @override
  OriginalRenderSliverOverlapAbsorber createRenderObject(BuildContext context) {
    return RenderSliverOverlapAbsorberOuter(
      handle: handle,
    );
  }
}

class RenderSliverOverlapAbsorberOuter
    extends OriginalRenderSliverOverlapAbsorber {
  RenderSliverOverlapAbsorberOuter({
    required super.handle,
    super.sliver,
  });

  @override
  void performLayout() {
    assert(
      handle._writers == 1,
      'A OriginalOverlapAbsorberHandle cannot be passed to multiple OriginalRenderSliverOverlapAbsorber objects at the same time.',
    );
    if (child == null) {
      geometry = SliverGeometry.zero;
      return;
    }
    child!.layout(constraints, parentUsesSize: true);
    final SliverGeometry childLayoutGeometry = child!.geometry!;
    final maxExtent = childLayoutGeometry.scrollExtent;
    final minExtent = childLayoutGeometry.maxScrollObstructionExtent;
    final currentExtent = childLayoutGeometry.paintExtent;
    // final topOverscroll = currentExtent > maxExtent;
    final topOverscrollExtend =
        (currentExtent - maxExtent).clamp(0, double.infinity);
    final atBottom =
        (currentExtent - minExtent).abs() < precisionErrorTolerance;
    final scrollExtend = atBottom ? maxExtent - minExtent : maxExtent;
    final layoutExtent =
        atBottom ? minExtent : currentExtent - topOverscrollExtend;
    geometry = SliverGeometry(
      scrollExtent: scrollExtend,
      layoutExtent: layoutExtent,
      paintExtent: childLayoutGeometry.paintExtent,
      paintOrigin: childLayoutGeometry.paintOrigin,
      maxPaintExtent: childLayoutGeometry.maxPaintExtent,
      maxScrollObstructionExtent:
          childLayoutGeometry.maxScrollObstructionExtent,
      hitTestExtent: childLayoutGeometry.hitTestExtent,
      visible: childLayoutGeometry.visible,
      hasVisualOverflow: childLayoutGeometry.hasVisualOverflow,
      scrollOffsetCorrection: childLayoutGeometry.scrollOffsetCorrection,
    );
    handle._setExtents(0, 0);
  }
}

class SliverOverlapInjectorOuter extends OriginalSliverOverlapInjector {
  const SliverOverlapInjectorOuter({
    super.key,
    required super.handle,
    super.sliver,
  });

  @override
  OriginalRenderSliverOverlapInjector createRenderObject(BuildContext context) {
    return RenderSliverOverlapInjectorOuter(
      handle: handle,
    );
  }
}

class RenderSliverOverlapInjectorOuter
    extends OriginalRenderSliverOverlapInjector {
  RenderSliverOverlapInjectorOuter({
    required super.handle,
  });
}
