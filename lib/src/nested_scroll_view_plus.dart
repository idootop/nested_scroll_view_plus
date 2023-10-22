part of 'nested_scroll_view.dart';

enum OverscrollType {
  ///allow inner scroller to overscroll
  inner,

  ///allow outer scroller to overscroll
  outer,
}

class NestedScrollViewPlus extends StatelessWidget {
  ///A NestedScrollView that supports outer scroller to top overscroll.
  ///
  /// If you want to access the inner or outer scroll controller of a [NestedScrollViewPlus],
  /// you can get its state by using a `GlobalKey<NestedScrollViewStatePlus>`.
  ///
  ///```dart
  /// import 'package:flutter/material.dart';
  /// import 'package:nested_scroll_view_plus/nested_scroll_view_plus.dart';
  ///
  /// void main() => runApp(
  ///       MaterialApp(
  ///         title: 'Example',
  ///         home: Example(),
  ///       ),
  ///     );
  ///
  /// class Example extends StatefulWidget {
  ///   const Example({super.key});
  ///
  ///   @override
  ///   State<Example> createState() => _ExampleState();
  /// }
  ///
  /// class _ExampleState extends State<Example> {
  ///   @override
  ///   Widget build(BuildContext context) {
  ///     return Scaffold(
  ///       body: DefaultTabController(
  ///         length: 2,
  ///         child: NestedScrollViewPlus(
  ///           // use key to access NestedScrollViewStatePlus
  ///           key: myKey,
  ///           headerSliverBuilder: (context, innerScrolled) => <Widget>[
  ///             // use OverlapAbsorberPlus to wrap your SliverAppBar
  ///             OverlapAbsorberPlus(
  ///               sliver: MySliverAppBar(),
  ///             ),
  ///           ],
  ///           body: TabBarView(
  ///             children: [
  ///               CustomScrollView(
  ///                 slivers: <Widget>[
  ///                   // use OverlapInjectorPlus on top of your inner CustomScrollView
  ///                   OverlapInjectorPlus(),
  ///                   _tabBody1,
  ///                 ],
  ///               ),
  ///               CustomScrollView(
  ///                 slivers: <Widget>[
  ///                   // use OverlapInjectorPlus on top of your inner CustomScrollView
  ///                   OverlapInjectorPlus(),
  ///                   _tabBody2,
  ///                 ],
  ///               ),
  ///             ],
  ///           ),
  ///         ),
  ///       ),
  ///     );
  ///   }
  ///
  ///   final GlobalKey<NestedScrollViewStatePlus> myKey = GlobalKey();
  ///
  ///   @override
  ///   void initState() {
  ///     super.initState();
  ///     WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
  ///       // use GlobalKey<NestedScrollViewStatePlus> to access inner or outer scroll controller
  ///       myKey.currentState?.innerController.addListener(() {
  ///         final innerController = myKey.currentState!.innerController;
  ///         print('>>> Scrolling inner nested scrollview: ${innerController.positions}');
  ///       });
  ///       myKey.currentState?.outerController.addListener(() {
  ///         final outerController = myKey.currentState!.outerController;
  ///         print('>>> Scrolling outer nested scrollview: ${outerController.positions}');
  ///       });
  ///     });
  ///   }
  ///
  ///   final _tabBody1 = SliverFixedExtentList(
  ///     delegate: SliverChildBuilderDelegate(
  ///       (_, index) => ListTile(
  ///         key: Key('$index'),
  ///         title: Center(
  ///           child: Text('ListTile ${index + 1}'),
  ///         ),
  ///       ),
  ///       childCount: 30,
  ///     ),
  ///     itemExtent: 50,
  ///   );
  ///
  ///   final _tabBody2 = const SliverFillRemaining(
  ///     child: Center(
  ///       child: Text('Test'),
  ///     ),
  ///   );
  /// }
  ///
  /// class MySliverAppBar extends StatelessWidget {
  ///   ///Header collapsed height
  ///   final minHeight = 120.0;
  ///
  ///   ///Header expanded height
  ///   final maxHeight = 400.0;
  ///
  ///   final tabBar = const TabBar(
  ///     tabs: <Widget>[Text('Tab1'), Text('Tab2')],
  ///   );
  ///
  ///   @override
  ///   Widget build(BuildContext context) {
  ///     final topHeight = MediaQuery.of(context).padding.top;
  ///     return SliverAppBar(
  ///       pinned: true,
  ///       stretch: true,
  ///       toolbarHeight: minHeight - tabBar.preferredSize.height - topHeight,
  ///       collapsedHeight: minHeight - tabBar.preferredSize.height - topHeight,
  ///       expandedHeight: maxHeight - topHeight,
  ///       flexibleSpace: FlexibleSpaceBar(
  ///         centerTitle: true,
  ///         title: const Center(child: Text('Example')),
  ///         stretchModes: <StretchMode>[
  ///           StretchMode.zoomBackground,
  ///           StretchMode.blurBackground,
  ///         ],
  ///         background: Image.network(
  ///           'https://pic1.zhimg.com/80/v2-fc35089cfe6c50f97324c98f963930c9_720w.jpg',
  ///           fit: BoxFit.cover,
  ///         ),
  ///       ),
  ///       bottom: tabBar,
  ///     );
  ///   }
  /// }
  ///```
  // ignore: use_key_in_widget_constructors
  const NestedScrollViewPlus({
    Key? key,
    this.controller,
    this.scrollDirection = Axis.vertical,
    this.reverse = false,
    this.physics = const BouncingScrollPhysics(
      parent: AlwaysScrollableScrollPhysics(),
    ),
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
