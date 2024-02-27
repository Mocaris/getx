import 'package:flutter/widgets.dart';

import '../../../../get_core/get_core.dart';
import '../../../../instance_manager.dart';
import '../../../get_navigation.dart';
import '../../dialog/dialog_route.dart';
import '../../router_report.dart';

/// Extracts the name of a route based on it's instance type
/// or null if not possible.
String? _extractRouteName(Route? route) {
  if (route?.settings.name != null) {
    return route!.settings.name;
  }

  if (route is GetPageRoute) {
    return route.routeName;
  }

  if (route is GetDialogRoute) {
    return 'DIALOG ${route.hashCode}';
  }

  if (route is GetModalBottomSheetRoute) {
    return 'BOTTOMSHEET ${route.hashCode}';
  }

  return null;
}

class GetObserver extends NavigatorObserver {
  final Function(Routing?)? routing;

  final Routing? _routeSend;

  GetObserver([this.routing, this._routeSend]);

  @override
  void didPop(Route route, Route? previousRoute) {
    super.didPop(route, previousRoute);
    final currentRoute = _RouteData.ofRoute(route);
    final newRoute = _RouteData.ofRoute(previousRoute);
    if (currentRoute.isBottomSheet || currentRoute.isDialog) {
      Get.log("CLOSE ${currentRoute.name}");
    }else if (newRoute.isGetPageRoute) {
      Get.log("CLOSE TO ROUTE ${newRoute.name}");
    }

    if (previousRoute != null) {
      RouterReportManager.instance.reportCurrentRoute(previousRoute);
    }

    // Here we use a 'inverse didPush set', meaning that we use
    // previous route instead of 'route' because this is
    // a 'inverse push'
    _routeSend?.update((value) {
      value.current = newRoute.name ?? '';
      value.previous = currentRoute.name ?? '';
      value.args = previousRoute?.settings.arguments;
      value.route = previousRoute;
      value.isBack = true;
      value.removed = '';
      // value.isSnackbar = newRoute.isSnackbar;
      value.isBottomSheet = newRoute.isBottomSheet;
      value.isDialog = newRoute.isDialog;
    });

    // print('currentRoute.isDialog ${currentRoute.isDialog}');
    routing?.call(_routeSend);
  }

  @override
  void didPush(Route route, Route? previousRoute) {
    super.didPush(route, previousRoute);
    final newRoute = _RouteData.ofRoute(route);
    final previous = _RouteData.ofRoute(previousRoute);
    if (newRoute.isBottomSheet || newRoute.isDialog) {
      Get.log("OPEN ${newRoute.name}");
    } else if (newRoute.isGetPageRoute) {
      Get.log("GOING TO ROUTE ${newRoute.name}");
    }

    RouterReportManager.instance.reportCurrentRoute(route);
    _routeSend!.update((value) {
      value.current = newRoute.name ?? '';
      value.previous = previous.name ?? '';

      value.args = route.settings.arguments;
      value.route = route;
      value.isBack = false;
      value.removed = '';
      value.isBottomSheet = newRoute.isBottomSheet;
      value.isDialog = newRoute.isDialog;
    });

    routing?.call(_routeSend);
  }

  @override
  void didRemove(Route route, Route? previousRoute) {
    super.didRemove(route, previousRoute);
    final newRoute = _RouteData.ofRoute(previousRoute);
    final removeRoute = _RouteData.ofRoute(route);
    Get.log("REMOVING ROUTE ${removeRoute.name}, TO ROUTE ${newRoute.name}");

    if(null != previousRoute){
      RouterReportManager.instance.reportCurrentRoute(previousRoute);
    }
    _routeSend?.update((value) {
      value.current = newRoute.name ?? '';
      value.route = previousRoute;
      value.isBack = false;
      value.removed = removeRoute.name ?? '';
      value.previous = removeRoute.name ?? '';
      // value.isSnackbar = currentRoute.isSnackbar ? false : value.isSnackbar;
      value.isBottomSheet = newRoute.isBottomSheet;
      value.isDialog = newRoute.isDialog;
    });

    if (route is GetPageRoute) {
      RouterReportManager.instance.reportRouteWillDispose(route);
    }

    routing?.call(_routeSend);
  }

  @override
  void didReplace({Route? newRoute, Route? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    final previousRoute = _RouteData.ofRoute(oldRoute);
    final currentRoute = _RouteData.ofRoute(newRoute);
    Get.log("REPLACE ROUTE ${previousRoute.name}, NEW ROUTE ${currentRoute.name}");

    if (newRoute != null) {
      RouterReportManager.instance.reportCurrentRoute(newRoute);
    }

    _routeSend?.update((value) {
      value.current = currentRoute.name ?? '';
      value.previous = previousRoute.name ?? '';
      value.args = newRoute?.settings.arguments;
      value.route = newRoute;
      value.isBack = false;
      value.removed = '';
      // value.isSnackbar = currentRoute.isSnackbar ? false : value.isSnackbar;
      value.isBottomSheet = currentRoute.isBottomSheet;
      value.isDialog = currentRoute.isDialog;
    });
    if (oldRoute is GetPageRoute) {
      RouterReportManager.instance.reportRouteWillDispose(oldRoute);
    }

    routing?.call(_routeSend);
  }
}

//TODO: Use copyWith, and remove mutate variables
class Routing {
  String current;
  String previous;
  dynamic args;
  String removed;
  Route<dynamic>? route;
  bool? isBack;

  // bool? isSnackbar;
  bool? isBottomSheet;
  bool? isDialog;

  Routing({
    this.current = '',
    this.previous = '',
    this.args,
    this.removed = '',
    this.route,
    this.isBack,
    // this.isSnackbar,
    this.isBottomSheet,
    this.isDialog,
  });

  void update(void Function(Routing value) fn) {
    fn(this);
  }
}

/// This is basically a util for rules about 'what a route is'
class _RouteData {
  final bool isGetPageRoute;
  final bool isBottomSheet;
  final bool isDialog;
  final String? name;

  _RouteData({
    required this.name,
    required this.isGetPageRoute,
    required this.isBottomSheet,
    required this.isDialog,
  });

  factory _RouteData.ofRoute(Route? route) {
    return _RouteData(
      name: _extractRouteName(route),
      isGetPageRoute: route is GetPageRoute,
      isDialog: route is GetDialogRoute,
      isBottomSheet: route is GetModalBottomSheetRoute,
    );
  }
}
