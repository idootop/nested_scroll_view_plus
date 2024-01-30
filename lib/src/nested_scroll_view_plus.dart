part of 'nested_scroll_view.dart';

enum OverscrollType {
  ///allow inner scroller to overscroll
  inner,

  ///allow outer scroller to overscroll
  outer,
}

class NestedScrollViewPlus extends StatelessWidget {
  /// An enhanced `NestedScrollView` offering overscroll support for both the nested and parent scroll views, ensuring a seamless scrolling experience.
  ///
  /// 🔥 Usage example:
  ///
  /// ```dart
  /// // Step 1: Replace `NestedScrollView` with `NestedScrollViewPlus`
  /// NestedScrollViewPlus(
  ///   headerSliverBuilder: (context, innerScrolled) => <Widget>[
  ///     // ... insert your header sliver widgets here
  ///   ],
  ///   body: CustomScrollView(
  ///     // Step 2: [🚨IMPORTANT] Set the physics of `CustomScrollView` to `AlwaysScrollableScrollPhysics`
  ///     physics: const BouncingScrollPhysics(
  ///       parent: AlwaysScrollableScrollPhysics(),
  ///     ),
  ///     slivers: <Widget>[
  ///       // ... insert your body sliver widgets here
  ///     ],
  ///   ),
  /// );
  /// ```
  ///
  /// **[🚨IMPORTANT]** Ensure that the `physics` property of the `CustomScrollView` within the body is set to `AlwaysScrollableScrollPhysics` to guarantee proper scrolling behavior.
  ///
  // ignore: use_key_in_widget_constructors
  const NestedScrollViewPlus({
    Key? key,
    this.controller,
    this.scrollDirection = Axis.vertical,
    this.reverse = false,
    this.physics,
    required this.headerSliverBuilder,
    required this.body,
    this.dragStartBehavior = DragStartBehavior.start,
    this.clipBehavior = Clip.hardEdge,
    this.restorationId,
    this.scrollBehavior,
    this.overscrollType = OverscrollType.outer,
  }) : _key = key;

  final Key? _key;
  final ScrollController? controller;
  final Axis scrollDirection;
  final bool reverse;
  final ScrollPhysics? physics;
  final OriginalNestedScrollViewHeaderSliversBuilder headerSliverBuilder;
  final Widget body;
  final DragStartBehavior dragStartBehavior;
  final Clip clipBehavior;
  final String? restorationId;
  final ScrollBehavior? scrollBehavior;

  ///allow which scroller to overscroll
  final OverscrollType overscrollType;

  @override
  Widget build(BuildContext context) {
    return overscrollType == OverscrollType.outer
        ? NestedScrollViewOuter(
            key: _key,
            controller: controller,
            scrollDirection: scrollDirection,
            reverse: reverse,
            physics: physics,
            headerSliverBuilder: headerSliverBuilder,
            body: body,
            dragStartBehavior: dragStartBehavior,
            floatHeaderSlivers: false, //does not support floatHeaderSlivers
            clipBehavior: clipBehavior,
            restorationId: restorationId,
            scrollBehavior: scrollBehavior,
          )
        : NestedScrollViewInner(
            key: _key,
            controller: controller,
            scrollDirection: scrollDirection,
            reverse: reverse,
            physics: physics,
            headerSliverBuilder: headerSliverBuilder,
            body: body,
            dragStartBehavior: dragStartBehavior,
            floatHeaderSlivers: false, //does not support floatHeaderSlivers
            clipBehavior: clipBehavior,
            restorationId: restorationId,
            scrollBehavior: scrollBehavior,
          );
  }

  static OriginalOverlapAbsorberHandle sliverOverlapAbsorberHandleFor(
      BuildContext context) {
    final target = context.dependOnInheritedWidgetOfExactType<
        _OriginalInheritedNestedScrollView>();
    assert(
      target != null,
      'OriginalNestedScrollView.sliverOverlapAbsorberHandleFor must be called with a context that contains a OriginalNestedScrollView.',
    );
    return target!.state._absorberHandle;
  }
}

class SliverOverlapAbsorberPlus extends OriginalSliverOverlapAbsorber {
  const SliverOverlapAbsorberPlus({
    super.key,
    required super.handle,
    super.sliver,
    OverscrollType overscrollType = OverscrollType.outer,
  }) : _overscrollType = overscrollType;

  ///allow which scroller to overscroll
  final OverscrollType _overscrollType;

  @override
  OriginalRenderSliverOverlapAbsorber createRenderObject(BuildContext context) {
    return _overscrollType == OverscrollType.outer
        ? RenderSliverOverlapAbsorberOuter(handle: handle)
        : RenderSliverOverlapAbsorberInner(handle: handle);
  }
}

class OverlapAbsorberPlus extends StatelessWidget {
  const OverlapAbsorberPlus({
    super.key,
    this.sliver,
    this.overscrollType = OverscrollType.outer,
  });

  final Widget? sliver;
  final OverscrollType overscrollType;

  @override
  Widget build(BuildContext context) {
    return SliverOverlapAbsorberPlus(
      overscrollType: overscrollType,
      handle: NestedScrollViewPlus.sliverOverlapAbsorberHandleFor(
        context,
      ),
      sliver: sliver,
    );
  }
}

class SliverOverlapInjectorPlus extends OriginalSliverOverlapInjector {
  const SliverOverlapInjectorPlus({
    super.key,
    required super.handle,
    super.sliver,
    OverscrollType overscrollType = OverscrollType.outer,
  }) : _overscrollType = overscrollType;

  ///allow which scroller to overscroll
  final OverscrollType _overscrollType;

  @override
  OriginalRenderSliverOverlapInjector createRenderObject(BuildContext context) {
    return _overscrollType == OverscrollType.outer
        ? RenderSliverOverlapInjectorOuter(handle: handle)
        : RenderSliverOverlapInjectorInner(handle: handle);
  }
}

class OverlapInjectorPlus extends StatelessWidget {
  const OverlapInjectorPlus({
    super.key,
    this.overscrollType = OverscrollType.outer,
  });

  final OverscrollType overscrollType;

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (context) => SliverOverlapInjectorPlus(
        overscrollType: overscrollType,
        handle: NestedScrollViewPlus.sliverOverlapAbsorberHandleFor(context),
      ),
    );
  }
}
