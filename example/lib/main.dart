// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:nested_scroll_view_plus/nested_scroll_view_plus.dart';

void main() => runApp(
      SafeArea(
        top: true,
        child: MaterialApp(
          theme: ThemeData.light(useMaterial3: true).copyWith(
            primaryColor: Colors.black,
            tabBarTheme: const TabBarTheme(
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              indicatorColor: Colors.white,
            ),
            appBarTheme: const AppBarTheme(backgroundColor: Colors.black),
          ),
          home: const Example(),
        ),
      ),
    );

class Example extends StatefulWidget {
  const Example({super.key});

  @override
  State<Example> createState() => _ExampleState();
}

class _ExampleState extends State<Example> {
  Widget _tabView([bool reverse = false]) => CustomScrollView(
        key: PageStorageKey<String>('$reverse'),
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: <Widget>[
          const OverlapInjectorPlus(),
          SliverFixedExtentList(
            delegate: SliverChildBuilderDelegate(
              (_, index) => Container(
                key: Key('$reverse-$index'),
                color: index.isEven ? Colors.white : Colors.grey[100],
                child: Center(
                  child: Text('ListTile ${reverse ? 30 - index : index + 1}'),
                ),
              ),
              childCount: 30,
            ),
            itemExtent: 60,
          ),
        ],
      );

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
              _tabView(),
              _tabView(true),
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
        if (innerController.positions.length == 1) {
          print('Scrolling inner nested scrollview: ${innerController.offset}');
        }
      });
      myKey.currentState?.outerController.addListener(() {
        final outerController = myKey.currentState!.outerController;
        if (outerController.positions.length == 1) {
          print('Scrolling outer nested scrollview: ${outerController.offset}');
        }
      });
    });
  }
}

class MySliverAppBar extends StatelessWidget {
  ///Header collapsed height
  final minHeight = 60.0;

  ///Header expanded height
  final maxHeight = 320.0;

  final tabBar = const TabBar(
    labelPadding: EdgeInsets.all(16),
    tabs: <Widget>[Text('Tab1'), Text('Tab2')],
  );

  const MySliverAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    final bottomHeight = tabBar.preferredSize.height;
    return SliverAppBar(
      pinned: true,
      stretch: true,
      toolbarHeight: minHeight - bottomHeight - topPadding,
      collapsedHeight: minHeight - bottomHeight - topPadding,
      expandedHeight: maxHeight - topPadding,
      titleSpacing: 0,
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const <StretchMode>[
          StretchMode.zoomBackground,
          StretchMode.blurBackground,
        ],
        background: Image.network(
          'https://pic1.zhimg.com/80/v2-fc35089cfe6c50f97324c98f963930c9_720w.jpg',
          fit: BoxFit.cover,
          alignment: const Alignment(0.0, 0.4),
        ),
      ),
      bottom: tabBar,
    );
  }
}
