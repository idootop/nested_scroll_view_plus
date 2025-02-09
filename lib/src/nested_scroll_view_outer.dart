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
    this.pushPinnedHeaderSlivers = false,
  });

  final bool pushPinnedHeaderSlivers;

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
  List<Widget> _buildSlivers(
    BuildContext context,
    ScrollController innerController,
    bool bodyIsScrolled,
  ) {
    final headerSlivers = headerSliverBuilder(context, bodyIsScrolled);
    assert(headerSlivers.isNotEmpty,
        'headerSliverBuilder must return at least one sliver.');
    final lastSliver = headerSlivers.removeLast();
    return <Widget>[
      ...headerSlivers,
      // ignore: deprecated_member_use_from_same_package
      OverlapAbsorberPlus(
        overscrollBehavior: OverscrollBehavior.outer,
        sliver: lastSliver,
      ),
      SliverFillRemaining(
        child: PrimaryScrollController(
          automaticallyInheritForPlatforms: TargetPlatform.values.toSet(),
          controller: innerController,
          child: body,
        ),
      ),
    ];
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

  @override
  Widget build(BuildContext context) {
    const defaultPhysics = BouncingScrollPhysics(
      parent: AlwaysScrollableScrollPhysics(),
    );
    final ScrollPhysics scrollPhysics =
        widget.physics?.applyTo(defaultPhysics) ??
            widget.scrollBehavior
                ?.getScrollPhysics(context)
                .applyTo(defaultPhysics) ??
            defaultPhysics;

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

  // inner/outer offset -> coordinator offset
  @override
  double unnestOffset(double value, _OriginalNestedScrollPosition source) {
    if (source.debugLabel == 'outer') {
      return value.clamp(
        -1 * double.infinity,
        _outerPosition!.maxScrollExtent,
      );
    }
    // outer is scrolling
    if (_outerPosition!.maxScrollExtent - _outerPosition!.pixels >
        precisionErrorTolerance) {
      // coordinator offset = outer.value
      return _outerPosition!.pixels.clamp(
        -1 * double.infinity,
        _outerPosition!.maxScrollExtent,
      );
    }
    // inner is scrolling
    // coordinator offset = outer.max + inner offset
    final offset = value - source.minScrollExtent;
    return _outerPosition!.maxScrollExtent + offset.clamp(0, double.infinity);
  }

  // coordinator offset -> inner/outer offset
  @override
  double nestOffset(double value, _OriginalNestedScrollPosition target) {
    if (target.debugLabel == 'outer') {
      return value.clamp(
        -1 * double.infinity,
        _outerPosition!.maxScrollExtent,
      );
    }
    final offset = value - _outerPosition!.maxScrollExtent;
    return target.minScrollExtent + offset.clamp(0, double.infinity);
  }

  @override
  void applyUserOffset(double delta) {
    updateUserScrollDirection(
        delta > 0.0 ? ScrollDirection.forward : ScrollDirection.reverse);
    if (_innerPositions.isEmpty) {
      _outerPosition!.applyFullDragUpdate(delta);
    } else if (delta < 0.0) {
      // ⬆️
      double remainingDelta = delta;
      // apply remaining delta to outer(clamped) first
      remainingDelta = _outerPosition!.applyClampedDragUpdate(remainingDelta);
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
        // TODO: Stop dragging when the floating sliver becomes fully visible
        remainingDelta = _outerPosition!.applyClampedDragUpdate(remainingDelta);
      }
      // apply remaining delta to inner(clamped) first
      for (final position in _innerPositions) {
        if (remainingDelta > 0) {
          remainingDelta = position.applyClampedDragUpdate(remainingDelta);
        }
      }
      // apply remaining delta to outer(overflow)
      if (remainingDelta > 0) {
        _outerPosition!.applyFullDragUpdate(remainingDelta);
      }
    }
  }

  @override
  void pointerScroll(double delta) {
    if (delta == 0.0) {
      goBallistic(0.0);
      return;
    }
    goIdle();
    _outerPosition!.isScrollingNotifier.value = true;
    _outerPosition!.didStartScroll();
    for (final position in _innerPositions) {
      position.isScrollingNotifier.value = true;
      position.didStartScroll();
    }
    applyUserOffset(delta);
    _outerPosition!.didEndScroll();
    for (final position in _innerPositions) {
      position.didEndScroll();
    }
    goBallistic(0.0);
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

@Deprecated(
    'As of version 2.0, wrapping child components with this widget is no longer required. Please remove the wrap from your child components')
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

@Deprecated(
    'As of version 2.0, wrapping child components with this widget is no longer required. Please remove the wrap from your child components')
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
    final childLayoutGeometry = child!.geometry!;
    final maxExtent = childLayoutGeometry.scrollExtent;
    final minExtent = childLayoutGeometry.maxScrollObstructionExtent;
    final currentExtent = childLayoutGeometry.paintExtent;
    final atBottom =
        (currentExtent - minExtent).abs() < precisionErrorTolerance;
    final scrollExtend =
        atBottom ? maxExtent - minExtent : childLayoutGeometry.scrollExtent;
    final layoutExtent = childLayoutGeometry.layoutExtent;
    geometry = childLayoutGeometry.copyWith(
      scrollExtent: scrollExtend,
      layoutExtent: layoutExtent,
    );
    handle._setExtents(0, 0);
  }
}

@Deprecated(
    'No longer needed as of v2.0. Remove the Injector widget from atop your scroll views.')
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

@Deprecated(
    'No longer needed as of v2.0. Remove the Injector widget from atop your scroll views.')
class RenderSliverOverlapInjectorOuter
    extends OriginalRenderSliverOverlapInjector {
  RenderSliverOverlapInjectorOuter({
    required super.handle,
  });
}
