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

    // if (currentRoute.isSnackbar) {
    //   // Get.log("CLOSE SNACKBAR ${currentRoute.name}");
    //   Get.log("CLOSE SNACKBAR");
    // } else

    if (currentRoute.isBottomSheet || currentRoute.isDialog) {
      Get.log("CLOSE ${currentRoute.name}");
    } else if (currentRoute.isGetPageRoute) {
      Get.log("CLOSE TO ROUTE ${currentRoute.name}");
    }
    if (previousRoute != null) {
      RouterReportManager.instance.reportCurrentRoute(previousRoute);
    }

    // Here we use a 'inverse didPush set', meaning that we use
    // newCurrentRoute route instead of 'route' because this is
    // a 'inverse push'
    _routeSend?.update((value) {
      value.current = newRoute.name??'';
      value.previous = currentRoute.name??'';// newRoute.name ?? '';

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
    // if (newRoute.isSnackbar) {
    //   // Get.log("OPEN SNACKBAR ${newRoute.name}");
    //   Get.log("OPEN SNACKBAR");
    // } else

    if (newRoute.isBottomSheet || newRoute.isDialog) {
      Get.log("OPEN ${newRoute.name}");
    } else{
      Get.log("GOING TO ROUTE ${newRoute.name}");
    }

    RouterReportManager.instance.reportCurrentRoute(route);
    _routeSend?.update((value) {
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
    Get.log("REMOVING ROUTE ${removeRoute.name}");

    _routeSend?.update((value) {
      value.route = previousRoute;
      value.isBack = false;
      value.removed = removeRoute.name ?? '';
      value.previous = newRoute.name ?? '';
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
    final oldName = _extractRouteName(oldRoute);
    final newCRoute = _RouteData.ofRoute(newRoute);

    Get.log("REPLACE ROUTE $oldName");
    Get.log("NEW ROUTE ${newCRoute.name}");

    if (newRoute != null) {
      RouterReportManager.instance.reportCurrentRoute(newRoute);
    }

    _routeSend?.update((value) {
      value.current = newCRoute.name ?? '';

      value.args = newRoute?.settings.arguments;
      value.route = newRoute;
      value.isBack = false;
      value.removed = '';
      value.previous = '$oldName';
      // value.isSnackbar = currentRoute.isSnackbar ? false : value.isSnackbar;
      value.isBottomSheet = newCRoute.isBottomSheet;
      value.isDialog =newCRoute.isDialog;
    });
    if (oldRoute is GetPageRoute) {
      RouterReportManager.instance.reportRouteWillDispose(oldRoute);
    }

    routing?.call(_routeSend);
  }
}

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

  void update(void fn(Routing value)) {
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
