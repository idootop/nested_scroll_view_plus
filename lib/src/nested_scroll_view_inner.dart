part of 'nested_scroll_view.dart';

class NestedScrollViewInner extends OriginalNestedScrollView {
  const NestedScrollViewInner({
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
  NestedScrollViewStatePlus createState() => NestedScrollViewInnerState();
}

class NestedScrollViewInnerState extends NestedScrollViewStatePlus {
  @override
  void initState() {
    super.initState();
    _coordinator = _NestedScrollCoordinatorInner(
      this,
      widget.controller,
      _handleHasScrolledBodyChanged,
      widget.floatHeaderSlivers,
    );
  }

  @override
  Widget build(BuildContext context) {
    const defalutPhysics = ClampingScrollPhysics();
    final ScrollPhysics scrollPhysics =
        widget.physics?.applyTo(defalutPhysics) ??
            widget.scrollBehavior
                ?.getScrollPhysics(context)
                .applyTo(defalutPhysics) ??
            defalutPhysics;

    return _OriginalInheritedNestedScrollView(
      state: this,
      child: Builder(
        builder: (BuildContext context) {
          _lastHasScrolledBody = _coordinator!.hasScrolledBody;
          return _OriginalNestedScrollViewCustomScrollView(
            dragStartBehavior: widget.dragStartBehavior,
            scrollDirection: widget.scrollDirection,
            reverse: widget.reverse,
            physics: scrollPhysics,
            scrollBehavior: widget.scrollBehavior ??
                ScrollConfiguration.of(context).copyWith(scrollbars: false),
            controller: _coordinator!._outerController,
            slivers: widget._buildSlivers(
              context,
              _coordinator!._innerController,
              _lastHasScrolledBody!,
            ),
            handle: _absorberHandle,
            clipBehavior: widget.clipBehavior,
            restorationId: widget.restorationId,
          );
        },
      ),
    );
  }
}

class _NestedScrollControllerInner extends _OriginalNestedScrollController {
  _NestedScrollControllerInner(
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
    return _NestedScrollPositionInner(
      coordinator: coordinator as _NestedScrollCoordinatorInner,
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

class _NestedScrollCoordinatorInner extends _OriginalNestedScrollCoordinator {
  _NestedScrollCoordinatorInner(
    super.state,
    super.parent,
    super.onHasScrolledBodyChanged,
    super.floatHeaderSlivers,
  ) {
    final double initialScrollOffset = _parent?.initialScrollOffset ?? 0.0;
    _outerController = _NestedScrollControllerInner(
      this,
      initialScrollOffset: initialScrollOffset,
      debugLabel: 'outer',
    );
    _innerController = _NestedScrollControllerInner(
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

  // inner/outer offset -> coordinator offset
  @override
  double unnestOffset(double value, _OriginalNestedScrollPosition source) {
    if (source == _outerPosition) {
      // coordinator offset = outer.value
      return value.clamp(
        _outerPosition!.minScrollExtent,
        _outerPosition!.maxScrollExtent,
      );
    }
    // outer is scrolling
    if (_outerPosition!.maxScrollExtent - _outerPosition!.pixels >
            precisionErrorTolerance &&
        (_outerPosition!.pixels - _outerPosition!.minScrollExtent) >
            precisionErrorTolerance) {
      // coordinator offset = outer.value
      return _outerPosition!.pixels.clamp(
        _outerPosition!.minScrollExtent,
        _outerPosition!.maxScrollExtent,
      );
    }
    // top overscroll
    if (value <= source.minScrollExtent) {
      // coordinator offset = inner.min - top overscroll
      final overscroll = source.minScrollExtent - value;
      return _outerPosition!.minScrollExtent - overscroll;
    }
    // inner is scrolling
    // coordinator offset = outer.max + inner offset
    final offset = value - source.minScrollExtent;
    return _outerPosition!.maxScrollExtent + offset;
  }

  // coordinator offset -> inner/outer offset
  @override
  double nestOffset(double value, _OriginalNestedScrollPosition target) {
    if (target == _outerPosition) {
      return clampDouble(
        value,
        _outerPosition!.minScrollExtent,
        _outerPosition!.maxScrollExtent,
      );
    }
    // top overscroll
    if (value <= _outerPosition!.minScrollExtent) {
      // inner offset = inner.min - top overscroll
      final overscroll = _outerPosition!.minScrollExtent - value;
      return target.minScrollExtent - overscroll;
    }
    if (value > _outerPosition!.maxScrollExtent) {
      // inner is scrolling
      // inner offset = inner.min + offset
      final offset = value - _outerPosition!.maxScrollExtent;
      return target.minScrollExtent + offset;
    }
    // outer is scrolling, inner is initial status
    // inner offset = inner.min
    return target.minScrollExtent;
  }

  @override
  void applyUserOffset(double delta) {
    updateUserScrollDirection(
      delta > 0.0 ? ScrollDirection.forward : ScrollDirection.reverse,
    );
    assert(delta != 0.0);
    if (_innerPositions.isEmpty) {
      _outerPosition!.applyFullDragUpdate(delta);
    } else if (delta < 0.0) {
      // ⬆️
      double remainingDelta = delta;
      // apply remaining delta to inner(clamped) first
      for (final position in _innerPositions) {
        if (position.pixels < position.minScrollExtent // top overscroll inner
            &&
            remainingDelta < 0) {
          remainingDelta = position.applyClampedDragUpdate(remainingDelta);
        }
      }
      // apply remaining delta to outer(clamped)
      if (remainingDelta < 0) {
        remainingDelta = _outerPosition!.applyClampedDragUpdate(remainingDelta);
      }
      // apply remaining delta to inner
      for (final position in _innerPositions) {
        if (remainingDelta < 0) {
          remainingDelta = position.applyFullDragUpdate(remainingDelta);
        }
      }
    } else {
      // ⬇️
      double remainingDelta = delta;
      if (_floatHeaderSlivers) {
        remainingDelta = _outerPosition!.applyClampedDragUpdate(remainingDelta);
      }
      // apply remaining delta to inner(clamped) first
      for (final position in _innerPositions) {
        if (remainingDelta > 0) {
          remainingDelta = position.applyClampedDragUpdate(remainingDelta);
        }
      }
      // apply remaining delta to outer(clamped)
      if (remainingDelta > 0) {
        remainingDelta = _outerPosition!.applyClampedDragUpdate(remainingDelta);
      } // apply remaining delta to inner(overscroll)
      for (final position in _innerPositions) {
        if (remainingDelta > 0) {
          remainingDelta = position.applyFullDragUpdate(remainingDelta);
        }
      }
    }
  }
}

class _NestedScrollPositionInner extends _OriginalNestedScrollPosition {
  _NestedScrollPositionInner({
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
        return _NestedOuterBallisticScrollActivityInner(
          coordinator,
          this,
          simulation,
          context.vsync,
          activity?.shouldIgnorePointer ?? true,
        );
      case _OriginalNestedBallisticScrollActivityMode.inner:
        return _NestedInnerBallisticScrollActivityInner(
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

class _NestedBallisticScrollActivityInner extends BallisticScrollActivity {
  _NestedBallisticScrollActivityInner(
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

class _NestedOuterBallisticScrollActivityInner
    extends _NestedBallisticScrollActivityInner {
  _NestedOuterBallisticScrollActivityInner(
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

class _NestedInnerBallisticScrollActivityInner
    extends _NestedBallisticScrollActivityInner {
  _NestedInnerBallisticScrollActivityInner(
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

class SliverOverlapAbsorberInner extends OriginalSliverOverlapAbsorber {
  const SliverOverlapAbsorberInner({
    super.key,
    required super.handle,
    super.sliver,
  });

  @override
  OriginalRenderSliverOverlapAbsorber createRenderObject(BuildContext context) {
    return RenderSliverOverlapAbsorberInner(
      handle: handle,
    );
  }
}

class RenderSliverOverlapAbsorberInner
    extends OriginalRenderSliverOverlapAbsorber {
  RenderSliverOverlapAbsorberInner({
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
    final isOuterScrollShrinking = currentExtent < maxExtent;
    final scrollExtend =
        isOuterScrollShrinking ? maxExtent - minExtent : maxExtent;
    final layoutExtent = isOuterScrollShrinking ? currentExtent : currentExtent;
    geometry = childLayoutGeometry.copyWith(
      scrollExtent: scrollExtend,
      layoutExtent: layoutExtent,
    );
    handle._setExtents(0, 0);
  }
}

class SliverOverlapInjectorInner extends OriginalSliverOverlapInjector {
  const SliverOverlapInjectorInner({
    super.key,
    required super.handle,
    super.sliver,
  });

  @override
  OriginalRenderSliverOverlapInjector createRenderObject(BuildContext context) {
    return RenderSliverOverlapInjectorInner(
      handle: handle,
    );
  }
}

class RenderSliverOverlapInjectorInner
    extends OriginalRenderSliverOverlapInjector {
  RenderSliverOverlapInjectorInner({
    required super.handle,
  });
}
