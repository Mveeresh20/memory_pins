import 'package:flutter/material.dart';

class NavigationService {
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static Future<dynamic>? pushNamed(String routeName, {Object? arguments}) {
    return navigatorKey.currentState?.pushNamed(routeName, arguments: arguments);
  }

  static Future<dynamic>? pushReplacementNamed(String routeName, {Object? arguments}) {
    return navigatorKey.currentState?.pushReplacementNamed(routeName, arguments: arguments);
  }

  static void pop<T extends Object?>([T? result]) {
    return navigatorKey.currentState?.pop(result);
  }

  static Future<dynamic>? push(MaterialPageRoute route) {
    return navigatorKey.currentState?.push(route);
  }

  static Future<dynamic>? pushWidget(Widget widget) {
    return navigatorKey.currentState?.push(
      MaterialPageRoute(builder: (_) => widget),
    );
  }

  static void popUntil(String routeName) {
    navigatorKey.currentState?.popUntil(ModalRoute.withName(routeName));
  }
}
