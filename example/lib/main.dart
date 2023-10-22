// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:nested_scroll_view_plus/nested_scroll_view_plus.dart';

void main() => runApp(
      const MaterialApp(home: Example()),
    );

class Example extends StatefulWidget {
  const Example({super.key});

  @override
  State<Example> createState() => _ExampleState();
}

class _ExampleState extends State<Example> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DefaultTabController(
        length: 2,
        child: NestedScrollViewPlus(
          // use key to access NestedScrollViewStatePlus
          key: myKey,
          headerSliverBuilder: (context, innerScrolled) => <Widget>[
            // use OverlapAbsorberPlus to wrap your SliverAppBar
            const OverlapAbsorberPlus(
              sliver: MySliverAppBar(),
            ),
          ],
          body: TabBarView(
            children: [
              CustomScrollView(
                slivers: <Widget>[
                  // use OverlapInjectorPlus on top of your inner CustomScrollView
                  const OverlapInjectorPlus(),
                  _tabBody1,
                ],
              ),
              CustomScrollView(
                slivers: <Widget>[
                  // use OverlapInjectorPlus on top of your inner CustomScrollView
                  const OverlapInjectorPlus(),
                  _tabBody2,
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  final GlobalKey<NestedScrollViewStatePlus> myKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      // use GlobalKey<NestedScrollViewStatePlus> to access inner or outer scroll controller
      myKey.currentState?.innerController.addListener(() {
        final innerController = myKey.currentState!.innerController;
        print('Scrolling inner nested scrollview: ${innerController.offset}');
      });
      myKey.currentState?.outerController.addListener(() {
        final outerController = myKey.currentState!.outerController;
        print('Scrolling outer nested scrollview: ${outerController.offset}');
      });
    });
  }

  final _tabBody1 = SliverFixedExtentList(
    delegate: SliverChildBuilderDelegate(
      (_, index) => ListTile(
        key: Key('$index'),
        tileColor: index.isEven ? Colors.white : Colors.grey[100],
        title: Center(
          child: Text('ListTile ${index + 1}'),
        ),
      ),
      childCount: 30,
    ),
    itemExtent: 60,
  );

  final _tabBody2 = const SliverFillRemaining(
    child: Center(
      child: Text('Test'),
    ),
  );
}

class MySliverAppBar extends StatelessWidget {
  ///Header collapsed height
  final minHeight = 100.0;

  ///Header expanded height
  final maxHeight = 360.0;

  final tabBar = const TabBar(
    labelPadding: EdgeInsets.all(16),
    tabs: <Widget>[Text('Tab1'), Text('Tab2')],
  );

  const MySliverAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    final topHeight = MediaQuery.of(context).padding.top;
    return SliverAppBar(
      pinned: true,
      stretch: true,
      toolbarHeight: minHeight - tabBar.preferredSize.height - topHeight,
      collapsedHeight: minHeight - tabBar.preferredSize.height - topHeight,
      expandedHeight: maxHeight - topHeight,
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: true,
        stretchModes: const <StretchMode>[
          StretchMode.zoomBackground,
          StretchMode.blurBackground,
        ],
        background: Image.network(
          'https://pic1.zhimg.com/80/v2-fc35089cfe6c50f97324c98f963930c9_720w.jpg',
          fit: BoxFit.cover,
          alignment: const Alignment(0.0, 0.3),
        ),
      ),
      bottom: tabBar,
    );
  }
}
