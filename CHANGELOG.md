## 3.0.1

- Synchronized the `NestedScrollView` source code with [Flutter 3.41.0](https://github.com/flutter/flutter/commit/bfb25da29410775d7d10d102167e37b9457eb1d0).

## 3.0.0

- Synchronized the `NestedScrollView` source code with [Flutter 3.27.2](https://github.com/flutter/flutter/pull/160545).
- Added support for `CupertinoSliverRefreshControl` and other loading indicators.
- Increased the minimum supported Flutter version to 3.22.0.

## 2.0.0

**🚨 Breaking Changes**

- Renamed `OverscrollType` to `OverscrollBehavior`.
- Deprecated `OverlapInjector` and `OverlapAbsorber` widgets. It is no longer necessary to wrap header slivers with `OverlapAbsorber`.

**✨ New Features**

- Added support for multiple header slivers. ([#3](https://github.com/idootop/nested_scroll_view_plus/issues/3))
- Enhanced the scroll behavior for a smoother and more seamless experience.
- Synchronized the `NestedScrollView` source code with [Flutter 3.19.0-5.0.pre](https://github.com/flutter/flutter/commit/e5f62cc5a029469f46464a6930075731ce42a94d) for better compatibility and performance.

**🔧 Fixes**

- Corrected the default physics setting for `NestedScrollView`.
- Resolved an issue where `NestedScrollView` was not adhering to user-specified physics settings. ([#4](https://github.com/idootop/nested_scroll_view_plus/issues/4))
- Improved synchronization between inner and outer scroll views. ([#4](https://github.com/idootop/nested_scroll_view_plus/issues/4))

## 1.0.3

- Fixed an issue where the inner scroll view exceeded the boundaries of the header ([issue#4](https://github.com/idootop/nested_scroll_view_plus/issues/4)).
- Corrected behavior of NestedScrollView to ensure it follows the defined physics.
- Synchronized NestedScrollView source code with Flutter version [Flutter 3.19.0-5.0.pre](https://github.com/flutter/flutter/commit/e5f62cc5a029469f46464a6930075731ce42a94d).

## 1.0.2

- Fixed the performLayout of RenderSliverOverlapAbsorberInner

## 1.0.1

- Fixed issue with incorrect calculation of scrollExtend and layoutExtent in RenderSliverOverlapAbsorberOuter ([issue#2](https://github.com/idootop/nested_scroll_view_plus/issues/2))

## 1.0.0

- First release
